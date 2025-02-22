const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {});
    @cInclude("main.h");
});

pub fn getTick() u32 {
    return c.HAL_GetTick();
}

pub inline fn delay(delay_ms: u32) void {
    c.HAL_Delay(delay_ms);
}

pub fn enterCriticalSection() void {
    //TODO
}

pub fn exitCriticalSection() void {
    //TODO
}
