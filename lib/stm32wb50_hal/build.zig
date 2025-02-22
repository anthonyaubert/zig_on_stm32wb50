const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const hal = b.addModule(
        "hal",
        .{
            .optimize = optimize,
            .root_source_file = b.path("src/hal.zig"),
            .target = target,
        },
    );

    hal.addCMacro("STM32WB50xx", "");
    hal.addCMacro("USE_HAL_DRIVER", "");
    hal.addCMacro("__PROGRAM_START", "_start");

    for (asm_sources) |path| {
        hal.addAssemblyFile(b.path(path));
    }

    for (c_includes) |path| {
        hal.addIncludePath(b.path(path));
    }

    for (c_includes_core) |path| {
        hal.addIncludePath(b.path(path));
    }

    hal.addCSourceFiles(.{
        .flags = c_sources_compile_flags,
        .files = c_sources_drivers,
        .root = b.path("src"),
    });

    hal.addCSourceFiles(.{
        .flags = c_sources_compile_flags,
        .files = c_sources_core,
        .root = b.path("src"),
    });
}

const asm_sources = [_][]const u8{"src/cubemx/startup_stm32wb50xx_cm4.s"};

const c_includes = [_][]const u8{
    "src/cubemx/Drivers/STM32WBxx_HAL_Driver/Inc",
    "src/cubemx/Drivers/STM32WBxx_HAL_Driver/Inc/Legacy",
    "src/cubemx/Drivers/CMSIS/Device/ST/STM32WBxx/Include",
    "src/cubemx/Drivers/CMSIS/Include",
    // "cubemx/Middlewares/ST/STM32_WPAN/ble"),
    // "cubemx/Middlewares/ST/STM32_WPAN/ble/core"),
    // "cubemx/Middlewares/ST/STM32_WPAN/ble/core/auto"),
    // "cubemx/Middlewares/ST/STM32_WPAN/ble/core/template"),
    // "cubemx/Middlewares/ST/STM32_WPAN/ble/svc/Inc"),
    // "cubemx/Middlewares/ST/STM32_WPAN/ble/svc/Src"),
    // "cubemx/Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread"),
    // "cubemx/Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/shci"),
    // "cubemx/Middlewares/ST/STM32_WPAN/interface/patterns/ble_thread/tl"),
    // "cubemx/Middlewares/ST/STM32_WPAN/utilities"),
    // "cubemx/Middlewares/ST/STM32_WPAN"),
    // "cubemx/STM32_WPAN/App"),
    // "cubemx/Utilities/lpm/tiny_lpm"),
};

const c_includes_core = [_][]const u8{"src/cubemx/Core/Inc"};

const c_sources_core = &.{
    "cubemx/Core/Src/main.c",
    "cubemx/Core/Src/gpio.c",
    "cubemx/Core/Src/stm32wbxx_it.c",
    "cubemx/Core/Src/stm32wbxx_hal_msp.c",
    "cubemx/Core/Src/system_stm32wbxx.c",
    // "cubemx/Core/Src/sysmem.c",
    // "cubemx/Core/Src/syscalls.c",
    "cubemx/Core/Src/hw_timerserver.c",
    "cubemx/Core/Src/rtc.c",
    "cubemx/Core/Src/ipcc.c",
};

const c_sources_drivers = &.{
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_cortex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_dma.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_dma_ex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_exti.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_flash.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_flash_ex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_gpio.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_hsem.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_pwr.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_pwr_ex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_rcc.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_rcc_ex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_tim.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_tim_ex.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_rtc.c",
    "cubemx/Drivers/STM32WBxx_HAL_Driver/Src/stm32wbxx_hal_ipcc.c",
};
const c_sources_compile_flags = &.{
    "-Og",
    "-ggdb3",
    "-gdwarf-2",
    "-std=gnu17",
    "-DCORE_CM4",
    "-Wall",
};
