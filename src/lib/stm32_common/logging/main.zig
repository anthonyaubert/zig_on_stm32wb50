const std = @import("std");
const log_defmt = @import("logging_defmt.zig");
const defmt_id = @import("logging_defmt_cfg.zig").LoggingDefmtId;

const logger1 = log_defmt.Logger(log_defmt.LogLevel.DEBUG);

pub fn printBytesAsHex(bytes: []const u8) void {
    const stdout = std.io.getStdOut().writer();

    stdout.print("{s}", .{std.fmt.fmtSliceHexLower(bytes)}) catch {};
    stdout.print("\n", .{}) catch {};
}

pub fn main() !void {
    log_defmt.init(
        printBytesAsHex,
    );

    logger1.logD(defmt_id.LogInit1, .{});

    logger1.logD(defmt_id.LogInit3, .{});

    const logger2 = comptime log_defmt.Logger(log_defmt.LogLevel.ERROR);

    // Should be skipped during compilation
    logger2.logD(defmt_id.LogInit1, .{});

    var foo2: u32 = 10;
    foo2 += 1;
    var foo1: u8 = 20;
    foo1 += 1;

    logger1.logD(defmt_id.LogInit2, .{ foo1, foo2 });

    const toto = "1234";
    logger2.logD(defmt_id.LogTest3, .{toto});

    // try log_defmt.logDebug(defmt_id.LogInit1, .{});

    // var foo2: u32 = 10;
    // foo2 += 1;
    // var foo1: u8 = 20;
    // foo1 += 1;
    // try log_defmt.logDebug(defmt_id.LogInit2, .{ foo1, foo2 });

    // const toto = "1234";
    // try log_defmt.logDebug(defmt_id.LogTest3, .{toto});
}
