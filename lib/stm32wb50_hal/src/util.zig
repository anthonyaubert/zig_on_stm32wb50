const hal = @import("hal.zig");
const c = hal.c;

const std = @import("std");
const system = @import("system.zig");
const assert = std.debug.assert;

pub const SharedDevice = struct {
    myInitializerFn: *const fn () void = undefined,
    myDeinitializerFn: *const fn () void = undefined,

    init_counter: u8 = 0,

    pub fn init(self: *@This()) void {

        // Device already initialized ?
        if (self.init_counter > 0) {
            self.init_counter += 1;
            assert(self.init_counter != 0);
            return;
        }

        // First Init...
        self.myInitializerFn();
        self.init_counter += 1;
        assert(self.init_counter != 0);
    }

    pub fn deinit(self: *@This()) void {
        if (self.init_counter == 0) {
            // device not yet initialized
            return;
        }

        // Still need device. Don't deinit
        if (self.init_counter != 1) {
            self.init_counter -= 1;
            return;
        }

        // Deinit
        self.myDeinitializerFn();
        self.init_counter -= 1;
    }
};
