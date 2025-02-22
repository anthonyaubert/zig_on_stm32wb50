/// Raw C code from STM
pub const c = @cImport({
    @cInclude("main.h"); // TODO à supprimer

    @cInclude("core_cm4.h");

    // For Gpio
    @cInclude("stm32wbxx_ll_gpio.h");

    // For Rtc
    @cInclude("stm32wbxx_ll_rtc.h");

    // For hw_timer - TODO à virer plus tard
    @cInclude("hw_if.h");
    @cInclude("rtc.h");
});

pub const hw_timer = @import("hw_timer.zig");

pub const system = @import("system.zig");

pub const gpio = @import("gpio.zig");
