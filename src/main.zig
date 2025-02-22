const std = @import("std");

pub const logging_defmt_cfg = @import("cfg/logging_defmt_cfg.zig");

const log_defmt = @import("lib/stm32_common/logging/logging_defmt.zig");
const logId = logging_defmt_cfg.LoggingDefmtId;

const hal = @import("hal");
const hwTimer = hal.hw_timer;
const sys = hal.system;

const rtt = @import("lib/segger_c/rtt.zig");


var timer1: hwTimer.StaticTimer(hwTimer.Mode.ePERIODIC, myBlinkTaskFunction1) = undefined;
var isledOn: bool = false;

var timer2: hwTimer.StaticTimer(hwTimer.Mode.ePERIODIC, myBlinkTaskFunction2) = undefined;
var isledOn2: bool = false;

const RESET_MAGIC = 0xA1203455;
var resetCounterMagic: u32 linksection(".noinit") = 0;
var resetCounter: u32 linksection(".noinit") = 0;

const logger = log_defmt.Logger(log_defmt.LogLevel.DEBUG);

export fn zig_entrypoint() void {
    const self = @This();

    log_defmt.init(rtt.write);

    if (resetCounterMagic != RESET_MAGIC) {
        resetCounterMagic = RESET_MAGIC;
        resetCounter = 0;
        logger.logD(logId.LogInit1, .{});
    } else {
        resetCounter += 1;
        logger.logD(logId.LogInit2, .{resetCounter});
    }

    rtt.println("Hello", .{});

    // Test
    logger.logD(logId.LogTest1, .{});

    hwTimer.init(true);

    self.timer1.create() catch unreachable;
    self.timer1.start(500);

    self.timer2.create() catch unreachable;
    self.timer2.start(100);

    while (true) {
        sys.delay(100);
    }

    unreachable;
}

fn myBlinkTaskFunction1() void {
    const self = @This();
    if (self.isledOn) {
        c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_RESET);
    } else {
        c.HAL_GPIO_WritePin(c.LED_G_GPIO_Port, c.LED_G_Pin, c.GPIO_PIN_SET);
    }
    self.isledOn = !self.isledOn; // Toggle the LED state
}

fn myBlinkTaskFunction2() void {
    const self = @This();
    if (self.isledOn2) {
        c.HAL_GPIO_WritePin(c.LED_R_GPIO_Port, c.LED_R_Pin, c.GPIO_PIN_RESET);
    } else {
        c.HAL_GPIO_WritePin(c.LED_R_GPIO_Port, c.LED_R_Pin, c.GPIO_PIN_SET);
    }
    self.isledOn2 = !self.isledOn2; // Toggle the LED state
}
