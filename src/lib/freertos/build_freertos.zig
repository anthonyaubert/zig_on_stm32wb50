const std = @import("std");

const lib_path = "src/lib/freertos/freertos_kernel/";

const c_sources_compile_flags = [_][]const u8{ "-Og", "-ggdb3", "-gdwarf-2", "-std=gnu17", "-DSTM32WB50xx", "-DCORE_CM4", "-Wall" };

fn build_path(comptime filepath: []const u8) []const u8 {
    return lib_path ++ filepath;
}

const include_path = [_][]const u8{
    "src/cfg",
    "src/lib/freertos",
    build_path("include"),
    build_path("portable/GCC/ARM_CM4F"),
};

const source_paths = [_][]const u8{
    build_path("croutine.c"),
    build_path("list.c"),
    build_path("queue.c"),
    build_path("stream_buffer.c"),
    build_path("tasks.c"),
    build_path("timers.c"),
    build_path("portable/GCC/ARM_CM4F/port.c"),
    build_path("portable/MemMang/heap_4.c"),
};

pub fn aggregate(b: *std.Build, elf: *std.Build.Step.Compile) void {
    for (include_path) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(.{
        .files = &source_paths,
        .flags = &c_sources_compile_flags,
    });
}
