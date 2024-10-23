const std = @import("std");

const lib_path = "src/lib/stm32wb50_hal/src/cubemx/";

fn build_path(comptime filepath: []const u8) []const u8 {
    return lib_path ++ filepath;
}

const asm_sources = [_][]const u8{build_path("startup_stm32wb50xx_cm4.s")};
const c_includes = [_][]const u8{ build_path("Drivers/STM32WBxx_HAL_Driver/Inc"), build_path("Drivers/STM32WBxx_HAL_Driver/Inc/Legacy"), build_path("Drivers/CMSIS/Device/ST/STM32WBxx/Include"), build_path("Drivers/CMSIS/Include") };

const c_sources_drivers = [_][]const u8{
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_cortex.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_dma.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_dma_ex.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_exti.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_flash.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_flash_ex.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_gpio.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_hsem.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_pwr.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_pwr_ex.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_rcc.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_rcc_ex.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_tim.c"),
    build_path("Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_tim_ex.c"),
};
const c_sources_compile_flags = [_][]const u8{ "-Og", "-ggdb3", "-gdwarf-2", "-std=gnu17", "-DUSE_HAL_DRIVER", "-DSTM32WB50xx", "-DCORE_CM4", "-Wall" };

const driver_file = .{
    .files = &c_sources_drivers,
    .flags = &c_sources_compile_flags,
};

const c_sources_core = [_][]const u8{
    build_path("Core/Src/main.c"),
    build_path("Core/Src/gpio.c"),
    build_path("Core/Src/stm32wbxx_it.c"),
    build_path("Core/Src/stm32wbxx_hal_msp.c"),
    build_path("Core/Src/system_stm32wbxx.c"),
    build_path("Core/Src/sysmem.c"),
    build_path("Core/Src/syscalls.c"),
};

const c_includes_core = [_][]const u8{build_path("Core/Inc")};

pub fn aggregate(b: *std.Build, elf: *std.Build.Step.Compile) void {
    for (asm_sources) |path| {
        elf.addAssemblyFile(b.path(path));
    }

    for (c_includes) |path| {
        elf.addIncludePath(b.path(path));
    }

    for (c_includes_core) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(driver_file);

    elf.addCSourceFiles(.{
        .files = &c_sources_core,
        .flags = &c_sources_compile_flags,
    });
}
