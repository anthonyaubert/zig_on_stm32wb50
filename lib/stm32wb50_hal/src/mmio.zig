pub inline fn writeReg(comptime reg: *volatile u32, value: u32) void {
    reg.* = value;
}

pub inline fn setBit(comptime reg: *volatile u32, comptime bit: u32) void {
    reg.* |= bit;
}

pub inline fn clearBit(comptime reg: *volatile u32, comptime bit: u32) void {
    reg.* &= ~bit;
}

pub inline fn clearReg(comptime reg: *volatile u32) void {
    reg.* = 0;
}

pub inline fn readReg(comptime reg: *volatile u32) u32 {
    return reg.*;
}

pub inline fn readBit(comptime reg: *volatile u32, comptime bit: u32) u32 {
    return (reg.* & bit);
}

pub inline fn modifyReg(comptime reg: *volatile u32, comptime clear_mask: u32, comptime set_mask: u32) void {
    reg.* = (reg.* & ~clear_mask) | set_mask;
}
