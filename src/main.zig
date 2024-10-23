const std = @import("std");

const log = @import("lib/stm32_common/logging/logging_defmt.zig");

const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/19687
    @cInclude("main.h");
});

export fn zig_entrypoint() void {
    log.defmt.init();
    while (true) {
        c.HAL_GPIO_WritePin(c.LED_GPIO_Port, c.LED_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(200);
        c.HAL_GPIO_WritePin(c.LED_GPIO_Port, c.LED_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(500);
    }

    unreachable;
}
