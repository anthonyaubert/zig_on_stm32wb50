const std = @import("std");

//TODO
const lib_path = "src/lib/segger_c/";

fn build_path(comptime filepath: []const u8) []const u8 {
    return lib_path ++ filepath;
}

const asm_sources = [_][]const u8{build_path("SEGGER_RTT_ASM_ARMv7M.s")};
const include_path = [_][]const u8{ build_path("config"), build_path("os"), build_path("segger") };

const source_paths = [_][]const u8{
    build_path("segger/SEGGER_RTT.c"),
};
const c_sources_compile_flags = [_][]const u8{ "-Og", "-ggdb3", "-gdwarf-2", "-std=gnu17", "-DUSE_HAL_DRIVER", "-DSTM32WB50xx", "-DCORE_CM4", "-Wall" };

pub fn aggregate(b: *std.Build, elf: *std.Build.Step.Compile) void {
    for (include_path) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(.{
        .files = &source_paths,
        .flags = &c_sources_compile_flags,
    });
}
