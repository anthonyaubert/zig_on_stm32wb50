const hal = @import("hal");
const gpio = hal.gpio;

pub const led_green = gpio.DigitalOutput{
    .gpio = gpio.GPIOB_6,
    .mode = gpio.GpioOutputMode.OutputOpenDrain,
    .pull = gpio.GpioPull.No,
    .active_state = gpio.GpioActiveState.Low,
};

pub const led_blue = gpio.DigitalOutput{
    .gpio = gpio.GPIOB_7,
    .mode = gpio.GpioOutputMode.OutputOpenDrain,
    .pull = gpio.GpioPull.No,
    .active_state = gpio.GpioActiveState.Low,
};

pub const led_red = gpio.DigitalOutput{
    .gpio = gpio.GPIOB_5,
    .mode = gpio.GpioOutputMode.OutputOpenDrain,
    .pull = gpio.GpioPull.No,
    .active_state = gpio.GpioActiveState.Low,
};
