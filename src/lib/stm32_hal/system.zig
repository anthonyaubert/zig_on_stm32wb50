const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/19687
    @cInclude("main.h");
});

pub fn get_tick() u32 {
    return c.HAL_GetTick();
}

/// *Set Enable Interrupt*, will enable IRQs globally, but keep the masking done via
/// `enable` and `disable` intact.
pub fn enter_critical_section() void {
    //TODO
}

/// *Clear Enable Interrupt*, will disable IRQs globally, but keep the masking done via
/// `enable` and `disable` intact.
pub fn exit_critical_section() void {
    //TODO
}
