pub const BUFFER_SIZE = 1024;

pub const LoggingDefmtId = enum(u16) {
    LogTest1,
    LogTest2,
    LogTest3 = 10,
};

const LoggingDefmt = struct {
    id: LoggingDefmtId,
    format: []const u8,
};

pub const logging_defmt_table = [_]LoggingDefmt{
    .{ .id = LoggingDefmtId.LogTest1, .format = "Test1 %d" },
    .{ .id = LoggingDefmtId.LogTest2, .format = "Test2 %d" },
};
