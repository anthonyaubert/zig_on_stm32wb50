const builtin = @import("builtin");
const std = @import("std");

const build_rtt = @import("src/lib/segger_c/build_rtt.zig");

pub fn build(b: *std.Build) void {

    //const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };
    const executable_name = "blinky_zig";
    // Target STM32WB50
    const query: std.zig.CrossTarget = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .cpu_features_add = std.Target.arm.featureSet(&[_]std.Target.arm.Feature{std.Target.arm.Feature.vfp4d16sp}),
        .os_tag = .freestanding,
        .abi = .eabihf,
        .glibc_version = null,
    };
    const target = b.resolveTargetQuery(query);

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const opti = b.standardOptimizeOption(.{});

    const elf = b.addExecutable(.{
        .name = executable_name ++ ".elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = opti,
        .linkage = .static,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
    });

    // const rtt = b.dependency("rtt", .{});
    // elf.root_module.addImport("rtt", rtt.module("rtt"));

    const hal = b.dependency("hal", .{ .optimize = opti, .target = target }).module("hal");
    elf.root_module.addImport("hal", hal);

    const libc = b.dependency(
        "picolibc",
        .{ .optimize = .ReleaseSmall, .target = target },
    ).artifact("c");

    hal.linkLibrary(libc);

    // Add all files for Segger RTT
    build_rtt.aggregate(b, elf);
    elf.linkLibrary(libc);

    const linker_file_path = b.path("src/stm32wb50xx_flash_cm4.ld");
    elf.setLinkerScriptPath(linker_file_path);
    elf.setVerboseCC(true);
    elf.setVerboseLink(false); //(NOTE: See https://github.com/ziglang/zig/issues/19410)
    elf.entry = .{ .symbol_name = "Reset_Handler" }; // Set Entry Point of the firmware (Already set in the linker script)
    elf.want_lto = false; // -flto
    elf.link_data_sections = true; // -fdata-sections
    elf.link_function_sections = true; // -ffunction-sections
    elf.link_gc_sections = true; // -Wl,--gc-sections

    // Copy the bin out of the elf
    const bin = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    bin.step.dependOn(&elf.step);
    const copy_bin = b.addInstallBinFile(bin.getOutput(), executable_name ++ ".bin");
    b.default_step.dependOn(&copy_bin.step);

    // Copy the bin out of the elf
    const hex = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .hex,
    });
    hex.step.dependOn(&elf.step);
    const copy_hex = b.addInstallBinFile(hex.getOutput(), executable_name ++ ".hex");
    b.default_step.dependOn(&copy_hex.step);

    //Add st-flash command (https://github.com/stlink-org/stlink)
    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "--reset",
        "--freq=4000k",
        "--format=ihex",
        "write",
        "zig-out/bin/" ++ executable_name ++ ".hex",
    });

    flash_cmd.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash and run the firmware");
    flash_step.dependOn(&flash_cmd.step);

    const clean_step = b.step("clean", "Clean up");
    clean_step.dependOn(&b.addRemoveDirTree(b.install_path).step);
    if (builtin.os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(b.pathFromRoot(".zig-cache")).step);
    }

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);

    // Print memory usage
    const print_memory_usage_exe = b.addExecutable(.{
        .name = "memory_usage_printer",
        .root_source_file = b.path("build/analyse_memory_usage.zig"),
        .target = b.host,
        .optimize = .ReleaseSafe,
    });
    const print_memory_usage_exe_run = b.addRunArtifact(print_memory_usage_exe);
    print_memory_usage_exe_run.addFileArg(linker_file_path);
    print_memory_usage_exe_run.addFileArg(elf.getEmittedBin());
    b.default_step.dependOn(&print_memory_usage_exe_run.step);
}
