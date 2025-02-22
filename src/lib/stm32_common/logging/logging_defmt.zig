//! Deffered logging

const std = @import("std");

//TODO add config module ?
const cfg_defmt = @import("root").logging_defmt_cfg;

pub const LogLevel = enum {
    INFO,
    DEBUG,
    WARNING,
    ERROR,
};

const DefmtLogHeader = packed struct {
    startByte: u8,
    data_size: u8,
    logLevel: u2,
    log_id: u14,
};

pub const writerCallback = *const fn (bytes: []const u8) void;

var my_logger_output_fn: writerCallback = undefined;

pub fn init(comptime logger_output: writerCallback) void {
    my_logger_output_fn = logger_output;
}

const LoggerDefmt_t = struct {
    log_level: LogLevel,

    pub inline fn logI(comptime self: LoggerDefmt_t, comptime log_id: cfg_defmt.LoggingDefmtId, args: anytype) void {
        comptime if (@intFromEnum(self.log_level) > @intFromEnum(LogLevel.INFO)) {
            return;
        };

        comptime checkArgs(log_id, @TypeOf(args));
        const header = comptime buildHeader(LogLevel.INFO, @intFromEnum(log_id), @TypeOf(args));
        log(header, args);
    }

    pub inline fn logD(comptime self: LoggerDefmt_t, comptime log_id: cfg_defmt.LoggingDefmtId, args: anytype) void {
        if (@intFromEnum(self.log_level) > @intFromEnum(LogLevel.DEBUG)) {
            return;
        }

        comptime checkArgs(log_id, @TypeOf(args));
        const header = comptime buildHeader(LogLevel.DEBUG, @intFromEnum(log_id), @TypeOf(args));
        log(header, args);
    }

    pub inline fn logW(comptime self: LoggerDefmt_t, comptime log_id: cfg_defmt.LoggingDefmtId, args: anytype) void {
        comptime if (@intFromEnum(self.log_level) > @intFromEnum(LogLevel.WARNING)) {
            return;
        };

        comptime checkArgs(log_id, @TypeOf(args));
        const header = comptime buildHeader(LogLevel.WARNING, @intFromEnum(log_id), @TypeOf(args));
        log(header, args);
    }

    pub inline fn logE(comptime self: LoggerDefmt_t, comptime log_id: cfg_defmt.LoggingDefmtId, args: anytype) void {
        _ = self;

        comptime checkArgs(log_id, @TypeOf(args));
        const header = comptime buildHeader(LogLevel.ERROR, @intFromEnum(log_id), @TypeOf(args));
        log(header, args);
    }
};

pub fn Logger(comptime log_level: LogLevel) LoggerDefmt_t {
    return LoggerDefmt_t{
        .log_level = log_level,
    };
}

pub const BuildLogError = error{
    /// Missing argument in the user defined arg_str
    ArgMissing,

    /// The arument is not correctly defined (ex user defined "u8u32" and the second arg is type ok i8)
    ArgInvalid,

    /// The arument type is not implemented
    ArgNotImplemented,
};

fn checkArgs(comptime log_id: cfg_defmt.LoggingDefmtId, comptime arg_type: type) void {
    const args_type_info = @typeInfo(arg_type);
    const fields_info = args_type_info.Struct.fields;

    // get declared args from the user (ex: "u8u32s4")
    const fmt_args: []const u8 = comptime getFmtArgs(log_id);

    var fmt_args_index: comptime_int = 0;

    for (fields_info) |field| {
        const arg_type_as_str = comptime getCustomTypeName(field.type);

        if (!std.mem.eql(u8, arg_type_as_str, fmt_args[fmt_args_index .. fmt_args_index + arg_type_as_str.len])) {
            @compileError(std.fmt.comptimePrint("Mismatch argument {} at index {d}", .{ field.type, fmt_args_index }));
        }

        fmt_args_index += arg_type_as_str.len;
    }
}

fn computeLogSize(comptime arg_type: type) BuildLogError!u8 {
    var log_size = 0;
    const args_type_info = @typeInfo(arg_type);
    const fields_info = args_type_info.Struct.fields;

    inline for (fields_info) |field| {
        switch (field.type) {
            i8, u8 => log_size += 1,
            i16, u16, f16 => log_size += 2,
            i32, u32, f32 => log_size += 4,
            else => switch (@typeInfo(field.type)) {
                .Pointer => return BuildLogError.ArgNotImplemented, //TODO
                .Array => |info| {
                    if (info.child == u8) {
                        log_size += info.len;
                    } else {
                        return BuildLogError.ArgNotImplemented;
                    }
                },
                else => {
                    //@compileLog(std.fmt.comptimePrint("Argument {any} not implemented", .{field.type}));
                    return BuildLogError.ArgNotImplemented;
                },
            },
        }
    }

    return log_size;
}

inline fn buildHeader(comptime log_level: LogLevel, comptime log_id: u14, comptime arg_type: type) DefmtLogHeader {
    const args_size_in_bytes = comptime try computeLogSize(arg_type);

    // Build Header
    return DefmtLogHeader{
        .startByte = 0x55,
        // +4 To add timestamp as u32 and +2 for log_id + log_level
        .data_size = args_size_in_bytes + 6,
        .log_id = log_id,
        .logLevel = @intFromEnum(log_level),
    };
}

fn log(comptime header: DefmtLogHeader, args: anytype) void {
    var buffer: [cfg_defmt.MAX_LOG_SIZE]u8 = undefined;

    const timestamp: u32 = 1; //TODO => getTick()

    const buffer_index: usize = buildlog(header, timestamp, args, &buffer);

    my_logger_output_fn(buffer[0..buffer_index]);
}

inline fn buildlog(comptime header: DefmtLogHeader, timestamp: u32, args: anytype, buffer: []u8) usize {
    var buffer_index: usize = 0;

    // Copy header
    const header_as_bytes: [4]u8 = @bitCast(header);
    @memcpy(buffer[buffer_index .. buffer_index + header_as_bytes.len], header_as_bytes[0..]);
    buffer_index += header_as_bytes.len;

    // Add timestamp
    const timestamp_as_bytes: [4]u8 = @bitCast(timestamp);
    @memcpy(buffer[buffer_index .. buffer_index + 4], timestamp_as_bytes[0..]);
    buffer_index += 4;

    // Add args
    inline for (args) |arg| {
        const T = @TypeOf(arg);
        switch (T) {
            i8, u8 => {
                buffer[buffer_index] = @bitCast(arg);
                buffer_index += 1;
            },
            i16, u16, f16 => {
                const arg_as_2bytes: [2]u8 = @bitCast(arg);
                @memcpy(buffer[buffer_index .. buffer_index + 2], arg_as_2bytes[0..]);
                buffer_index += 2;
            },
            i32, u32, f32 => {
                const arg_as_4bytes: [4]u8 = @bitCast(arg);
                @memcpy(buffer[buffer_index .. buffer_index + 4], arg_as_4bytes[0..]);
                buffer_index += 4;
            },
            else => switch (@typeInfo(T)) {
                .Array => |info| {
                    if (info.child == u8) {
                        @memcpy(buffer[buffer_index .. buffer_index + arg.len], arg[0..]);
                        buffer_index += arg.len;
                    } else {
                        //@compileLog(std.fmt.comptimePrint("Argument {s} not implemented", .{arg_type_as_str}));
                        // TODO not implemented
                        return 0;
                    }
                },
                else => {
                    //@compileLog(std.fmt.comptimePrint("Argument {s} not implemented", .{arg_type_as_str}));
                    // TODO not implemented
                    return 0;
                },
            },
        }
    }
    return buffer_index;
}

// Get user defined args for logID  => ex: "u8s2u32"
fn getFmtArgs(comptime defmtLogId: cfg_defmt.LoggingDefmtId) []const u8 {
    inline for (cfg_defmt.logging_defmt_table) |defmt_item| {
        if (defmt_item.id == defmtLogId) {
            return defmt_item.arg_str;
        }
    }
    @compileError("defmtLogId not found !");
}

fn getFmtString(comptime defmtLogId: cfg_defmt.LoggingDefmtId) []const u8 {
    for (cfg_defmt.logging_defmt_table) |defmt_item| {
        if (defmt_item.id == defmtLogId) {
            return defmt_item.fmt_str;
        }
    }
    @compileError("defmtLogId not found !");
}

/// return "i8" for type i8, "u32" for u32, "s4" for *const [4:0]u8
fn getCustomTypeName(comptime T: type) []const u8 {
    const arg_type_name = @typeName(T);

    // Check if the arg is a string
    // There is probably a better way to the job with @typeInfo(T)
    if ((std.mem.startsWith(u8, arg_type_name, "*const [")) and (std.mem.endsWith(u8, arg_type_name, ":0]u8"))) {
        // return 's'
        return "s";
    }

    switch (T) {
        i8, u8, i16, u16, f16, i32, u32, f32 => {
            return arg_type_name;
        },
        else => {
            //TODO manage other args
            @compileError(std.fmt.comptimePrint("Argument {s} not implemented", .{arg_type_name}));
        },
    }
}

test buildlog {
    var buffer1: [20]u8 = undefined;

    // Test Log level INFO - LogID=0 - Timestamp = 1
    {
        const expected = [8]u8{ 0x55, 0x06, 0x00, 0x00, 0x01, 0x00, 0x0, 0x00 };
        const args = .{};
        const header = buildHeader(LogLevel.INFO, 0, @TypeOf(args));
        const buffer_size = buildlog(header, 1, .{}, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    // Test Log level DEBUG - LogID=10 - Timestamp = 1025
    {
        const expected = [8]u8{ 0x55, 0x06, 0x29, 0x00, 0x01, 0x04, 0x0, 0x00 };
        const args = .{};
        const header = buildHeader(LogLevel.DEBUG, 10, @TypeOf(args));
        const buffer_size = buildlog(header, 1025, .{}, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    // Test Log level WARNING - LogID=100 - Timestamp = 0x123456
    {
        const expected = [8]u8{ 0x55, 0x06, 0x92, 0x01, 0x56, 0x34, 0x12, 0x00 };
        const args = .{};
        const header = buildHeader(LogLevel.WARNING, 100, @TypeOf(args));
        const buffer_size = buildlog(header, 0x123456, .{}, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    // Test Log level ERROR - LogID=1000 - Timestamp = 0xFFFFFFFF
    {
        const expected = [8]u8{ 0x55, 0x06, 0xA3, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF };
        const args = .{};
        const header = buildHeader(LogLevel.ERROR, 1000, @TypeOf(args));
        const buffer_size = buildlog(header, 0xFFFFFFFF, .{}, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    // Test with various arg
    var u8_value: u8 = 1;
    var i8_value: i8 = -5;
    var u16_value: u16 = 555;
    var i16_value: i16 = -256;
    var f16_value: f16 = 12.24;
    var u32_value: u32 = 100000;
    var i32_value: i32 = -100000;
    var f32_value: f32 = 124.12345;

    // Test with u8 arg Log level INFO - LogID=0 - Timestamp = 1
    {
        const expected = [9]u8{ 0x55, 0x07, 0x00, 0x00, 0x01, 0x00, 0x0, 0x00, 0x01 };
        const args = .{u8_value};
        const header = buildHeader(LogLevel.INFO, 0, @TypeOf(args));
        const buffer_size = buildlog(header, 1, args, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    u8_value = 255;
    i8_value = -120;
    u16_value = 0xFFFF;
    i16_value = -2560;
    f16_value = 32.1;

    // Test with all 1 byte and 2 bytes args
    {
        const expected = [16]u8{ 0x55, 0x0E, 0x00, 0x00, 0x01, 0x00, 0x0, 0x00, 0xFF, 0x88, 0x03, 0x50, 0x00, 0xF6, 0xFF, 0xFF };
        const args = .{ u8_value, i8_value, f16_value, i16_value, u16_value };
        const header = buildHeader(LogLevel.INFO, 0, @TypeOf(args));
        const buffer_size = buildlog(header, 1, args, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    u32_value = 0xFFFFFFFF;
    i32_value = -0x5FFFFFF;
    f32_value = 543.4321;

    // Test with all 4 bytes args
    {
        const expected = [16]u8{ 0x55, 0x0E, 0x00, 0x00, 0x01, 0x00, 0x0, 0x00, 0xFF, 0x88, 0x03, 0x50, 0x00, 0xF6, 0xFF, 0xFF };
        const args = .{ u8_value, i8_value, f16_value, i16_value, u16_value };
        const header = buildHeader(LogLevel.INFO, 0, @TypeOf(args));
        const buffer_size = buildlog(header, 1, args, &buffer1);
        try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    }

    // Test with string arg TODO
    // {
    //     const s_value = "hello";
    //     const expected = [14]u8{ 0x55, 0x0C, 0x00, 0x00, 0x01, 0x00, 0x0, 0x00, 0xFF, 0x68, 0x65, 0x6C, 0x6C, 0x6F };
    //     const args = .{ u8_value, s_value };
    //     const header = buildHeader(LogLevel.INFO, 0, @TypeOf(args));
    //     const buffer_size = buildlog(header, 1, .{}, &buffer1);
    //     try std.testing.expectEqualSlices(u8, &expected, buffer1[0..buffer_size]);
    // }

    // Check arg error
    // TODO

    // Test with max nb param
    // TODO

}
