const hal = @import("hal.zig");
const c = hal.c;
const mmio = @import("mmio.zig");

const SCB: *c.SCB_Type = @ptrFromInt(c.SCB_BASE);
const AIRCR = &SCB.AIRCR;

pub inline fn getTick() u32 {
    return c.HAL_GetTick();
}

pub inline fn delay(delay_ms: u32) void {
    c.HAL_Delay(delay_ms);
}

/// Enters a critical section and disables interrupts globally.
/// Call `.leave()` on the return value to restore the previous state.
pub inline fn enterCriticalSection() CriticalSection {
    const section = CriticalSection{
        ._primask = getPrimask(),
    };
    disableInterrupt();
    return section;
}

/// A critical section structure that allows restoring the interrupt
/// status that was set before entering.
const CriticalSection = struct {
    _primask: u32,

    /// Leaves the critical section and restores the interrupt state.
    pub inline fn exit(self: @This()) void {
        setPrimask(self._primask);
    }
};

///Disable Interrupts
pub inline fn disableInterrupt() void {
    asm volatile ("CPSID    I");
}

///Enable Interrupts
pub inline fn enableInterrupt() void {
    asm volatile ("CPSIE    I");
}

pub inline fn getPrimask() u32 {
    return asm volatile ("mrs r0, PRIMASK"
        : [ret] "={r0}" (-> u32),
        :
        : "r0"
    );
}

pub inline fn setPrimask(primask: u32) void {
    asm volatile ("msr   primask, %[primask]"
        :
        : [primask] "r" (primask),
    );
}

pub inline fn isIrqMode() bool {
    return asm volatile ("mrs r0, ipsr"
        : [ret] "={r0}" (-> bool),
        :
        : "r0"
    );
}

pub fn softReset() void {
    //__NVIC_SystemReset - core_cm4.h
    dsb();
    mmio.writeReg(AIRCR, (0x5FA << 16) | (AIRCR.* & (7 << 8)) | (1 << 2));
    isb();
    while (true) {}

    unreachable;
}

pub inline fn compilerBarrier() void {
    asm volatile ("" ::: "memory");
}

pub inline fn dsb() void {
    asm volatile ("dsb 0xF" ::: "memory");
}

pub inline fn isb() void {
    asm volatile ("isb 0xF" ::: "memory");
}
