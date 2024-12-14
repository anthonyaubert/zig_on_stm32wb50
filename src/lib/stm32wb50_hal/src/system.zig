const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {});
    @cInclude("main.h");
});

pub fn getTick() u32 {
    return c.HAL_GetTick();
}

pub fn enterCriticalSection() void {
    //TODO
}

pub fn exitCriticalSection() void {
    //TODO
}
