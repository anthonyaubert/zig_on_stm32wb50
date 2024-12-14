// The section .no_init in the linker file should be defined according this BUFFER_SIZE
pub const BUFFER_SIZE = 1024;

pub const MAX_LOG_SIZE = 64;

//TODO Generate the file before compilation process

pub const LoggingDefmtId = enum(u16) {
    LogInit1,
    LogInit2,

    LogTest1,
    LogTest3 = 10,
};

const LoggingDefmt = struct {
    id: LoggingDefmtId,
    fmt_str: []const u8,
    arg_str: []const u8,
};

pub const logging_defmt_table = [_]LoggingDefmt{
    .{
        .id = LoggingDefmtId.LogInit1,
        .fmt_str = "Power on -> Application is starting",
        .arg_str = "",
    },
    .{
        .id = LoggingDefmtId.LogInit2,
        .fmt_str = "Application is starting (counter={d})",
        .arg_str = "u32",
    },
    .{
        .id = LoggingDefmtId.LogTest1,
        .fmt_str = "Test",
        .arg_str = "",
    },
    .{
        .id = LoggingDefmtId.LogTest3,
        .fmt_str = "Test u8 and s {d} {s}",
        .arg_str = "u8s",
    },
};
