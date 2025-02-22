const hal = @import("hal.zig");
const c = hal.c;
const system = @import("system.zig");
const util = @import("util.zig");
const mmio = @import("mmio.zig");

const std = @import("std");

const RCC: *c.RCC_TypeDef = @ptrFromInt(c.RCC_BASE);
const AHB2ENR = &RCC.AHB2ENR;
const APB1ENR1 = &RCC.APB1ENR1;

var _tmpreg: u32 = 0;
const tmpreg: *volatile u32 = &_tmpreg;

// Enable RTCAPB clock - LL_APB1_GRP1_EnableClock
pub fn enable_RTCAPB() void {
    mmio.setBit(APB1ENR1, c.RCC_APB1ENR1_RTCAPBEN);
    //Delay after an RCC peripheral clock enabling
    tmpreg.* = APB1ENR1.*;
}

fn enable_GPIOA() void {
    mmio.setBit(AHB2ENR, c.RCC_AHB2ENR_GPIOAEN);
    //Delay after an RCC peripheral clock enabling
    tmpreg.* = AHB2ENR.*;
}

fn disable_GPIOA() void {
    mmio.clearBit(AHB2ENR, ~c.RCC_AHB2ENR_GPIOAEN);
    //Delay after an RCC peripheral clock disabling
    tmpreg.* = AHB2ENR.*;
}

pub var gpio_a = util.SharedDevice{
    .myInitializerFn = enable_GPIOA,
    .myDeinitializerFn = disable_GPIOA,
};

fn enable_GPIOB() void {
    mmio.setBit(AHB2ENR, c.RCC_AHB2ENR_GPIOBEN);
    //Delay after an RCC peripheral clock enabling
    tmpreg.* = AHB2ENR.*;
}

fn disable_GPIOB() void {
    mmio.clearBit(AHB2ENR, c.RCC_AHB2ENR_GPIOBEN);
    //Delay after an RCC peripheral clock disabling
    tmpreg.* = AHB2ENR.*;
}

pub var gpio_b = util.SharedDevice{
    .myInitializerFn = enable_GPIOB,
    .myDeinitializerFn = disable_GPIOB,
};
