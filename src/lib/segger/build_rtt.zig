const std = @import("std");

const lib_path = "src/lib/segger/";

fn build_path(comptime filepath: []const u8) []const u8 {
    return lib_path ++ filepath;
}

const asm_sources = [_][]const u8{build_path("SEGGER_RTT_ASM_ARMv7M.s")};
const c_includes = [_][]const u8{ build_path("config"), build_path("os"), build_path("segger") };

const c_sources = [_][]const u8{
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal.c"),
};
const c_sources_compile_flags = [_][]const u8{ "-Og", "-ggdb3", "-gdwarf-2", "-std=gnu17", "-DUSE_HAL_DRIVER", "-DSTM32WB50xx", "-DCORE_CM4", "-Wall" };

const driver_file = .{
    .files = &c_sources,
    .flags = &c_sources_compile_flags,
};

pub fn aggregate(b: *std.Build, elf: *std.Build.Step.Compile) void {
    for (asm_sources) |path| {
        elf.addAssemblyFile(b.path(path));
    }

    for (c_includes) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(.{
        .files = &c_sources,
        .flags = &c_sources_compile_flags,
    });
}
