const std = @import("std");
const rtt = @import("rtt");

const assert = std.debug.assert;

const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32WB50xx", {});
    @cDefine("__PROGRAM_START", {});
    @cInclude("hw_if.h");
    @cInclude("rtc.h");
});

pub const Mode = enum { eSINGLE_SHOT, ePERIODIC };

pub const HwTimerError = error{
    HwTimerCreationFailed,
};

pub fn init(b_isBootAfterPowerON: bool) void {
    c.MX_RTC_Init();

    if (b_isBootAfterPowerON) {
        c.HW_TS_Init(c.hw_ts_InitMode_Full, &c.hrtc);
    } else {
        c.HW_TS_Init(c.hw_ts_InitMode_Limited, &c.hrtc);
    }
}

pub fn StaticTimer(comptime mode: Mode, comptime taskRunnerFn: *const fn () void) type {
    //pub fn StaticTimer(comptime T: type, comptime mode: Mode, comptime taskRunnerFn: *const fn (*T) void) type {
    return struct {
        /// Inner Timer object
        timer: HwTimer = undefined,
        //        pvParameters: *T,
        isInit: bool = false,

        fn run() callconv(.C) void {
            //            const self: @This() = undefined;
            //            taskRunnerFn(self.pvParameters);
            taskRunnerFn();
        }

        //        pub inline fn create(self: *@This(), pvParameters: *T) !void {
        pub inline fn create(self: *@This()) !void {
            //            self.pvParameters = pvParameters;
            if (mode == Mode.eSINGLE_SHOT) {
                self.timer = try HwTimer.create(run, c.hw_ts_SingleShot);
            } else {
                self.timer = try HwTimer.create(run, c.hw_ts_Repeated);
            }
            self.isInit = true;
        }

        pub inline fn start(self: *@This(), timeoutMs: u32) void {
            assert(self.isInit);
            self.timer.start(timeoutMs);
        }
    };
}

pub const HwTimer = struct {
    /// Timer ID
    timerId: u8 = undefined,

    /// Create timer
    pub inline fn create(timerCallback: c.HW_TS_pTimerCb_t, mode: c.HW_TS_Mode_t) !@This() {
        var self: @This() = undefined;
        return if (c.hw_ts_Successful == c.HW_TS_Create(1, &self.timerId, mode, timerCallback)) self else HwTimerError.HwTimerCreationFailed;
    }

    /// Start timer
    pub inline fn start(self: *const @This(), timeoutMs: c_uint) void {
        c.HW_TS_Start(self.timerId, c.MS_TO_TICK(timeoutMs));
    }
};
