const hal = @import("hal.zig");
const c = hal.c;
const system = @import("system.zig");
const util = @import("util.zig");
const clock = @import("clock.zig");

const std = @import("std");
const assert = std.debug.assert;

/// Gpio structure
const GpioPin = struct {
    port: *c.GPIO_TypeDef,
    pin: u16,
    pwr_port: u32,
    pwr_pin: u32,
};

//TODO
pub const GPIOA_0 = GpioPin{ .port = c.GPIOA, .pin = c.GPIO_PIN_0, .pwr_port = c.PWR_GPIO_A, .pwr_pin = c.PWR_GPIO_BIT_0 };

pub const GPIOB_5 = GpioPin{ .port = c.GPIOB, .pin = c.GPIO_PIN_5, .pwr_port = c.PWR_GPIO_B, .pwr_pin = c.PWR_GPIO_BIT_5 };
pub const GPIOB_6 = GpioPin{ .port = c.GPIOB, .pin = c.GPIO_PIN_6, .pwr_port = c.PWR_GPIO_B, .pwr_pin = c.PWR_GPIO_BIT_6 };
pub const GPIOB_7 = GpioPin{ .port = c.GPIOB, .pin = c.GPIO_PIN_7, .pwr_port = c.PWR_GPIO_B, .pwr_pin = c.PWR_GPIO_BIT_7 };

/// Gpio output modes
pub const GpioOutputMode = enum {
    OutputPushPull,
    OutputOpenDrain,
};

/// Gpio input modes
pub const GpioInpuMode = enum {
    Input,
    Analog,
    InterruptRise,
    InterruptFall,
    InterruptRiseFall,
};

pub const GpioActiveState = enum {
    Low,
    High,
};

/// Gpio pull modes
pub const GpioPull = enum {
    No,
    Up,
    Down,
};

/// Gpio speed modes
pub const GpioSpeed = enum {
    Low,
    Medium,
    High,
    VeryHigh,
};

fn enableGpioClock(gpio: *const GpioPin) void {
    switch (gpio.pwr_port) {
        c.PWR_GPIO_A => clock.gpio_a.init(),
        c.PWR_GPIO_B => clock.gpio_b.init(),
        else => std.debug.panic("GPIO port not supported", .{}),
    }
}

fn disableGpioClock(gpio: *const GpioPin) void {
    switch (gpio.pwr_port) {
        c.PWR_GPIO_A => clock.gpio_a.deinit(),
        c.PWR_GPIO_B => clock.gpio_b.deinit(),
        else => std.debug.panic("GPIO port not supported", .{}),
    }
}

pub const DigitalOutput = struct {
    const Self = @This();

    active_state: GpioActiveState,
    gpio: GpioPin,
    mode: GpioOutputMode,
    pull: GpioPull,
    speed: GpioSpeed = GpioSpeed.Low,

    pub fn init(self: Self) void {

        // Enable clock
        enableGpioClock(&self.gpio); //tester clock init counter
        //GPIOA_clock.init();
        //clock.GPIOA.enable();

        // Init state
        self.write(false);

        // Configure pin as output
        var gpio_init = std.mem.zeroInit(c.GPIO_InitTypeDef, .{
            .Pin = self.gpio.pin,
            .Mode = switch (self.mode) {
                .OutputOpenDrain => c.GPIO_MODE_OUTPUT_OD,
                .OutputPushPull => c.GPIO_MODE_OUTPUT_PP,
            },
            .Pull = toHalPullMode(self.pull),
            .Speed = toHalGpioSpeed(self.speed),
            .Alternate = 0,
        });

        c.HAL_GPIO_Init(self.gpio.port, &gpio_init);
    }

    pub fn deinit(self: Self) void {
        c.HAL_GPIO_DeInit(self.gpio.port, self.gpio.pin);

        // Disable clock
        disableGpioClock(&self.gpio);
    }

    pub inline fn toggle(self: Self) void {
        c.HAL_GPIO_TogglePin(self.gpio.port, self.gpio.pin);
    }

    pub inline fn write(self: Self, state: bool) void {
        const output = switch (self.active_state) {
            .Low => !state,
            .High => state,
        };

        // writing to BSSR / BRR is an atomic operation
        if (output) {
            self.gpio.port.BSRR = self.gpio.pin;
        } else {
            self.gpio.port.BRR = self.gpio.pin;
        }
    }
};

/// Convert Zig Gpio speed type to stm32 HAL GPIO speed value
fn toHalGpioSpeed(speed: GpioSpeed) u32 {
    return switch (speed) {
        .Low => c.GPIO_SPEED_FREQ_LOW,
        .Medium => c.GPIO_SPEED_FREQ_MEDIUM,
        .High => c.GPIO_SPEED_FREQ_HIGH,
        .VeryHigh => c.GPIO_SPEED_FREQ_VERY_HIGH,
    };
}

/// Convert Zig Gpio pull type to stm32 HAL GPIO Pull value
fn toHalPullMode(pull: GpioPull) u32 {
    return switch (pull) {
        .No => c.GPIO_NOPULL,
        .Down => c.GPIO_PULLDOWN,
        .Up => c.GPIO_PULLUP,
    };
}
