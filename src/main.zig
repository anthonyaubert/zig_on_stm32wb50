const std = @import("std");

const log = @import("lib/stm32_common/logging/logging_defmt.zig");
const logId = @import("cfg/logging_defmt_cfg.zig").LoggingDefmtId;

const rtt = @import("lib/segger/rtt.zig");

const hwTimer = @import("lib/stm32wb50_hal/src/hw_timer.zig");

const freertos = @import("lib/freertos/freertos.zig");

const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/19687
    @cInclude("main.h");
});

var timer1: hwTimer.StaticTimer(hwTimer.Mode.ePERIODIC, myBlinkTaskFunction) = undefined;
var isledOn: bool = false;

export fn zig_entrypoint() void {
    const self = @This();
    log.defmt.init();
    rtt.println("Init", .{});
    //rtt.println("Start scheduler", .{});

    //var task: freertos.StaticTask(@This(), 256, "blink task", myBlinkTaskFunction) = undefined;
    //task.create(self, @intFromEnum(freertos.task_priorities.rtos_prio_below_normal)) catch unreachable;

    // Start the FreeRTOS scheduler
    //freertos.vTaskStartScheduler();

    hwTimer.init(true);

    self.timer1.create() catch unreachable;
    self.timer1.start(500);

    while (true) {
        c.HAL_Delay(100);
    }

    // while (true) {
    //     c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_RESET);
    //     c.HAL_Delay(200);
    //     c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_SET);
    //     c.HAL_Delay(500);

    //     log.DefmtLog_log(logId.LogTest1);
    // }

    unreachable;
}

fn myBlinkTaskFunction() void {
    const self = @This();
    if (self.isledOn) {
        c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_RESET);
    } else {
        c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_SET);
    }
    self.isledOn = !self.isledOn; // Toggle the LED state
}

export fn vApplicationStackOverflowHook() noreturn {
    //TODO AA    microzig.hang();
    while (true) {}
}

export fn vApplicationMallocFailedHook() noreturn {
    //TODO AA    microzig.hang();
    while (true) {}
}

export fn vApplicationTickHook() void {
    //
}
