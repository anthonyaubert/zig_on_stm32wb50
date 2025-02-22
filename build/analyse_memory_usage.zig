//! try to reproduce --print-memory-usage

const std = @import("std");
const StringStream = @import("StringStream.zig");

const MemoryRegion = struct {
    name: []const u8,
    start_address: u32,
    size: u32,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Memory usage: \n", .{});

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        try stdout.print("Error : linker_file_path and elf_file_path missing.\n", .{});
        return;
    }

    const linker_file_path = args[1];
    const elf_file_path = args[2];

    // Extract memory section from linker file
    const file = try std.fs.cwd().openFile(linker_file_path, .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(content);

    const memory_region_from_ld = try parse_linker_script(allocator, content);

    // Command to get memory usage with `arm-none-eabi-size`
    const size_command = [_][]const u8{
        "arm-none-eabi-size",
        "-A", // Output all sections
        elf_file_path,
    };

    // Execute `arm-none-eabi-size` to get section sizes
    var child = std.process.Child.init(&size_command, allocator);
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;

    try child.spawn();

    if (child.stdout) |child_stdout| {
        var stdout_stream = child_stdout.reader();
        const cmd_size_output = try stdout_stream.readAllAlloc(allocator, 2048);
        //        try stdout.print("{s}", .{cmd_size_output});

        // Extract memory section from elf file
        const memory_region_from_elf = try parse_size_command_output(cmd_size_output, allocator);

        const used_memory = try build_used_memory(memory_region_from_ld, memory_region_from_elf, allocator);

        // Print the result like
        //     Memory region         Used Size  Region Size  %age Used
        //        FLASH:      101906 B       256 KB     38.87%
        //   RAM_NOINIT:          0 GB         4 KB      0.00%
        //          RAM:       64368 B       188 KB     33.44%
        //   RAM_SHARED:         483 B        10 KB      4.72%
        try stdout.print("Memory region   Used Size   Region Size     %age\n", .{});

        for (used_memory) |memory_space| {
            try stdout.print("{s: <12} {d: >10} B  {d: >10} B {d: >7.2}%\n", .{
                memory_space.name,
                memory_space.used_size,
                memory_space.max_size,
                memory_space.percentageUsed(),
            });
        }
    }

    _ = try child.wait();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}

//Ex: "FOO = 25K" => extract_number_from_label(...,"FOO",true) => return 25*1024
fn extract_number_from_label(stream: *StringStream, comptime label: []const u8, allowMultiplier: bool) !u32 {
    if (false == stream.advanceToChars(label, true)) {
        return error.MemorySectionNotFound;
    }

    stream.skipWhitespace();
    if ('=' != stream.first()) {
        return error.InvalidMemoryFormat;
    }
    stream.advance(1);
    stream.skipWhitespace();

    var number_as_str = stream.nextWord();

    var multiplier: u32 = 1;
    if (std.mem.endsWith(u8, number_as_str, "K")) {
        if (allowMultiplier) {
            multiplier = 1024;
            number_as_str = number_as_str[0 .. number_as_str.len - 1];
        } else {
            return error.InvalidMemoryFormat;
        }
    }

    var number = try std.fmt.parseUnsigned(u32, number_as_str, 0);

    // Number has mulitiplier ?
    if (allowMultiplier) {
        number = try std.math.mul(u32, number, multiplier);
    }
    return number;
}

// Exctract all section size from size commmand output
// Something like:
// section               size        addr
// .isr_vector            316   134217728
// .text                25252   134218044
// .rodata               2052   134243296
fn parse_size_command_output(content: []const u8, allocator: std.mem.Allocator) ![]MemoryRegion {
    var memory_regions = std.ArrayList(MemoryRegion).init(allocator);

    var stream = StringStream.init(content);

    if (false == stream.advanceToChars("section", true)) {
        return error.MemorySectionNotFound;
    }

    if (false == stream.advanceToChars("size", true)) {
        return error.MemorySectionNotFound;
    }
    if (false == stream.advanceToChars("addr", true)) {
        return error.MemorySectionNotFound;
    }
    stream.skipWhitespace();

    // Extract each memory section until the end
    while (stream.len() > 0) {
        if (stream.first() != '.') {

            // It's the end ?
            const total = stream.nextWord();
            if (std.mem.eql(u8, "Total", total)) {
                // yes it's the end
                break;
            }

            return error.InvalidMemoryFormat;
        }
        stream.advance(1);
        var name = stream.nextWord();
        //Name could be arm.
        if (stream.first() == '.') {
            stream.advance(1);
            name = try std.fmt.allocPrint(allocator, "{s} {s}!", .{ name, stream.nextWord() });
        }

        const size_as_str = stream.nextWord();
        const size = try std.fmt.parseUnsigned(u32, size_as_str, 10);

        const address_as_str = stream.nextWord();
        const address = try std.fmt.parseUnsigned(u32, address_as_str, 10);

        // Go to the next line
        if (false == stream.advanceToChars("\n", true)) {
            return error.InvalidMemoryFormat;
        }
        stream.skipWhitespace();

        // Add the region to the list
        try memory_regions.append(MemoryRegion{
            .name = name,
            .start_address = address,
            .size = size,
        });
    }

    return memory_regions.toOwnedSlice();
}

// Exctract all memory region from linker script
fn parse_linker_script(allocator: std.mem.Allocator, content: []const u8) ![]MemoryRegion {
    var memory_regions = std.ArrayList(MemoryRegion).init(allocator);

    var stream = StringStream.init(content);

    if (false == stream.advanceToChars("MEMORY", true)) {
        return error.MemorySectionNotFound;
    }
    stream.skipWhitespace();
    if ('{' != stream.first()) {
        return error.InvalidMemoryFormat;
    }
    stream.advance(1);

    // Extract each memory section until the end
    while ('}' != stream.first()) {
        const name = stream.nextWord();
        const start_address = try extract_number_from_label(&stream, "ORIGIN", false);
        const size = try extract_number_from_label(&stream, "LENGTH", true);

        // Go to the next line
        if (false == stream.advanceToChars("\n", true)) {
            return error.InvalidMemoryFormat;
        }
        stream.skipWhitespace();

        // Add the region to the list
        try memory_regions.append(MemoryRegion{
            .name = name,
            .start_address = start_address,
            .size = size,
        });
    }

    return memory_regions.toOwnedSlice();
}

const UsedMemorySpace = struct {
    name: []const u8,
    used_size: u32,
    max_size: u32,

    pub fn percentageUsed(self: @This()) f64 {
        return @as(f64, @floatFromInt(self.used_size)) / @as(f64, @floatFromInt(self.max_size)) * 100.0;
    }
};

// Exctract all memory region from linker script
fn build_used_memory(memory_region_from_ld: []MemoryRegion, memory_region_from_elf: []MemoryRegion, allocator: std.mem.Allocator) ![]UsedMemorySpace {
    var used_memory_regions = std.ArrayList(UsedMemorySpace).init(allocator);

    for (memory_region_from_ld) |memory_region| {
        const name = memory_region.name;
        const max_size = memory_region.size;

        var used_size: u32 = 0;
        for (memory_region_from_elf) |used_memory_region| {
            // Check if the secion is in the current memory_region space
            if ((used_memory_region.start_address >= memory_region.start_address) and (used_memory_region.start_address < memory_region.start_address + memory_region.size)) {
                used_size += used_memory_region.size;
            }
        }

        // Add the region to the list
        try used_memory_regions.append(UsedMemorySpace{
            .name = name,
            .max_size = max_size,
            .used_size = used_size,
        });
    }

    return used_memory_regions.toOwnedSlice();
}

test "parse linker script" {
    const allocator = std.testing.allocator;

    const content =
        \\/* Entry Point */
        \\ENTRY(Reset_Handler)
        \\/* Highest address of the user mode stack */
        \\_estack = 0x20010000;    /* end of RAM */
        \\/* Generate a link error if heap and stack don't fit into RAM */
        \\_Min_Heap_Size = 0x400;      /* required amount of heap  */
        \\_Min_Stack_Size = 0x1000; /* required amount of stack */
        \\
        \\/* Specify the memory areas */
        \\MEMORY
        \\{
        \\     FLASH (rx)                 : ORIGIN = 0x08000000, LENGTH = 512K
        \\     RAM1 (xrw)                 : ORIGIN = 0x20000008, LENGTH = 0xFFF8
        \\     RAM_SHARED (xrw)           : ORIGIN = 0x20030000, LENGTH = 10K
        \\ }
    ;

    const regions = try parse_linker_script(content, allocator);
    defer allocator.free(regions);

    try std.testing.expect(regions.len == 3);

    try std.testing.expect(std.mem.eql(u8, regions[0].name, "FLASH"));
    try std.testing.expect(regions[0].start_address == 0x08000000);
    try std.testing.expect(regions[0].size == 512 * 1024); // 512K en octets

    try std.testing.expect(std.mem.eql(u8, regions[1].name, "RAM1"));
    try std.testing.expect(regions[1].start_address == 0x20000008);
    try std.testing.expect(regions[1].size == 0xFFF8);

    try std.testing.expect(std.mem.eql(u8, regions[2].name, "RAM_SHARED"));
    try std.testing.expect(regions[2].start_address == 0x20030000);
    try std.testing.expect(regions[2].size == 10 * 1024); // 10K en octets}
}
