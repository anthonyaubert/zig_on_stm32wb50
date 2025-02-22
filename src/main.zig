const std = @import("std");

pub const logging_defmt_cfg = @import("cfg/logging_defmt_cfg.zig");

const log_defmt = @import("lib/stm32_common/logging/logging_defmt.zig");
const logId = logging_defmt_cfg.LoggingDefmtId;

const hal = @import("hal");
const hwTimer = hal.hw_timer;
const sys = hal.system;

const rtt = @import("lib/segger_c/rtt.zig");

const board = @import("board.zig");
const led_green = board.led_green;
const led_blue = board.led_blue;
const led_red = board.led_red;

var timer1: hwTimer.StaticTimer(hwTimer.Mode.ePERIODIC, myBlinkTaskFunction1) = undefined;
var timer2: hwTimer.StaticTimer(hwTimer.Mode.ePERIODIC, myBlinkTaskFunction2) = undefined;

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

    led_green.init();
    led_blue.init();
    led_red.init();

    led_green.write(true);
    sys.delay(2000);
    led_green.write(false);

    sys.delay(1000);
    led_blue.write(true);
    sys.delay(2000);
    led_blue.write(false);

    sys.delay(1000);
    led_red.write(true);
    sys.delay(2000);
    led_red.write(false);

    sys.delay(2000);

    hwTimer.init(true);

    self.timer1.create() catch unreachable;
    self.timer1.start(1000);

    self.timer2.create() catch unreachable;
    self.timer2.start(100);

    while (true) {
        sys.delay(100);
    }

    unreachable;
}

fn myBlinkTaskFunction1() void {
    led_green.toggle();
}

fn myBlinkTaskFunction2() void {
    led_red.toggle();
}
