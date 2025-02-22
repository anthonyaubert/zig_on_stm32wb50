const std = @import("std");

const atomic = std.atomic;
const debug = std.debug;
const fmt = std.fmt;

pub const c = @cImport({
    @cInclude("SEGGER_RTT.h");
});

const Self = @This();

/// Print something to the RTT channel 0.
///
/// Uses the `std.fmt` plumbing under the hood.
pub fn print(comptime fmt_str: []const u8, args: anytype) void {
    const writer = Writer{};
    fmt.format(writer, fmt_str, args) catch unreachable;
}

/// Print something to the RTT channel, with a newline.
///
/// Uses the `std.fmt` plumbing under the hood.
pub fn println(comptime fmt_str: []const u8, args: anytype) void {
    print(fmt_str, args);
    write("\n");
}

/// Write raw bytes directly to the RTT channel.
///
/// Does _not_ use the `std.fmt` plumbing.
pub fn write(bytes: []const u8) void {
    _ = c.SEGGER_RTT_Write(0, bytes.ptr, bytes.len);
}

const Writer = struct {
    pub inline fn writeAll(self: Writer, bytes: []const u8) !void {
        _ = self;
        write(bytes);
    }

    pub fn writeBytesNTimes(self: Writer, bytes: []const u8, n: usize) !void {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            try self.writeAll(bytes);
        }
    }
};
