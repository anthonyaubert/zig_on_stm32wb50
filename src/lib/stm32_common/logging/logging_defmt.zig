//! Deffered logging

const std = @import("std");

//const rb = @import("../ring_buffer/RingBuffer.zig");

const cfg = @import("../../../cfg/logging_defmt_cfg.zig");
const system = @import("stm32_hal").system;

// Size of a defered log without param
// 1 byte for the 0x55 start byte
// 1 byte for the log size
// 2 bytes for the log id
// 4 for the timestamp
const deffered_log_min_size: u8 = 8;

// Max size of a string as param
// ( Modify the log format to increase this value )
// because the param(s) size is store on the 6 lsb of the buffer m_logs[1])
const deffered_log_max_str_param_size: u8 = 63;

//PLACE_IN_SECTION("RAM_NOINIT") => linksection(".ram_noinit") ???
// Impossible d'utiliser ringbuffer si on veut pouvoir recover le buffer après un reset
// il faudra également enregistrer un magick key au démarrage pour essayer de reconstruire la structure
/// Log Buffer
var log_buffer: [cfg.BUFFER_SIZE]u8 linksection(".noinit") = undefined;
pub var ring_buffer: std.RingBuffer linksection(".noinit") = .{
    .data = &log_buffer,
    .read_index = 0,
    .write_index = 0,
};

// si ring buffer full il faut virer non pas octet par octet mais log par log
pub var defmt: @This() = undefined;

pub fn init(self: @This()) void {
    _ = self;

    // Init Ring Buffer with log buffer
    //    ring_buffer.init();

    // TODO AA update the head index if the buffer is not empty ?
    // TODO AA Ajouter last dump
}

// size_t DefmtLog_export(uint8_t *const pu8_data, size_t u32_maxLen)
// {
//   return RingBuffer_dequeueArray(&m_ringBuffer, pu8_data, u32_maxLen);
// }

pub fn DefmtLog_log(comptime logId: cfg.LoggingDefmtId) void {
    var buffer: [deffered_log_min_size]u8 = 0;

    const size = buildLogInfo(logId, &buffer);

    // Update the size in the buffer
    buffer[1] |= size;

    system.enter_critical_section();
    ring_buffer.writeSliceAssumeCapacity(buffer);
    system.exit_critical_section();
}

// void DefmtLog_log1(LoggingDefmtId_t logId, const char * sFormat, int32_t i32_param)
// {
//     // printf format is not used now it will be used by the log viewer to format data
//     UNUSED(sFormat);

//     uint8_t pu8_buffer[DEF_LOG_MIN_SIZE + 4] = {0};

//     uint8_t size = buildLogInfo( logId, pu8_buffer);

//     // Add parameter
//     uint8_t size_param = addParameterAsI32(pu8_buffer + size, i32_param);

//     // Update the size in the buffer
//     pu8_buffer[1] += size_param;

//     ENTER_CRITICAL_SECTION( );
//     RingBuffer_queueArray(&m_ringBuffer, pu8_buffer, size);
//     EXIT_CRITICAL_SECTION( );
// }

// void DefmtLog_log2(LoggingDefmtId_t logId, const char * sFormat, int32_t i32_param1, int32_t i32_param2)
// {
//     // printf format is not used now it will be used by the log viewer to format data
//     UNUSED(sFormat);

//     uint8_t pu8_buffer[DEF_LOG_MIN_SIZE + 4] = {0};

//     uint8_t size = buildLogInfo( logId, pu8_buffer);

//     // Add parameter1
//     uint8_t size_param = addParameterAsI32(pu8_buffer + size, i32_param1);

//     // Add parameter2
//     size_param += addParameterAsI32(pu8_buffer + size + size_param, i32_param2);

//     // Update the size in the buffer
//     pu8_buffer[1] += size_param;

//     ENTER_CRITICAL_SECTION( );
//     RingBuffer_queueArray(&m_ringBuffer, pu8_buffer, size);
//     EXIT_CRITICAL_SECTION( );
// }

// void DefmtLog_log1s(LoggingDefmtId_t logId, const char * sFormat, const char * str_param)
// {
//     // printf format is not used now it will be used by the log viewer to format data
//     UNUSED(sFormat);

//     uint8_t pu8_buffer[DEF_LOG_MIN_SIZE + DEF_LOG_MAX_STR_PARAM_SIZE] = {0};

//     uint8_t size = buildLogInfo( logId, pu8_buffer);

//     // Add string parameter
//     uint8_t size_param = addParameterAsString(pu8_buffer + size, DEF_LOG_MAX_STR_PARAM_SIZE, str_param);

//     // Update the size in the buffer
//     pu8_buffer[1] = size + size_param;

//     ENTER_CRITICAL_SECTION( );
//     RingBuffer_queueArray(&m_ringBuffer, pu8_buffer, size);
//     EXIT_CRITICAL_SECTION( );
// }

// void DefmtLog_log2s(LoggingDefmtId_t logId, const char * sFormat, const char * str_param1, const char * str_param2)
// {
//     // printf format is not used now it will be used by the log viewer to format data
//     UNUSED(sFormat);

//     uint8_t pu8_buffer[DEF_LOG_MIN_SIZE + DEF_LOG_MAX_STR_PARAM_SIZE] = {0};

//     uint8_t size = buildLogInfo( logId, pu8_buffer);

//     // Add string parameter 1
//     uint8_t size_param = addParameterAsString(pu8_buffer + size, DEF_LOG_MAX_STR_PARAM_SIZE, str_param1);

//     // Add string parameter 2
//     size_param += addParameterAsString(pu8_buffer + size + size_param, DEF_LOG_MAX_STR_PARAM_SIZE - size_param, str_param2);

//     // Update the size in the buffer
//     pu8_buffer[1] |= size;

//     ENTER_CRITICAL_SECTION( );
//     RingBuffer_queueArray(&m_ringBuffer, pu8_buffer, size);
//     EXIT_CRITICAL_SECTION( );
// }

// /******************************************************************************/
// /* Definition of private functions                                            */
// /******************************************************************************/

fn buildLogInfo(comptime logId: cfg.LoggingDefmtId, pu8_buffer: []u8) void {
    var u8_index: u8 = 0;

    // Add start byte
    pu8_buffer[u8_index] = 0x55;
    u8_index += 1;

    // The second byte will be used later to store the size of the log in bytes
    u8_index += 1;

    // Add Log Id
    pu8_buffer[u8_index] = logId >> 8;
    u8_index += 1;
    pu8_buffer[u8_index] = logId;
    u8_index += 1;

    // Add Log timestamp
    const u32_timestamp: u32 = system.get_tick();
    pu8_buffer[u8_index] = u32_timestamp >> 24;
    u8_index += 1;
    pu8_buffer[u8_index] = u32_timestamp >> 16;
    u8_index += 1;
    pu8_buffer[u8_index] = u32_timestamp >> 8;
    u8_index += 1;
    pu8_buffer[u8_index] = u32_timestamp;
    u8_index += 1;

    return u8_index;
}

// /******************************************************************************/
// static uint8_t addParameterAsI32(uint8_t *const pu8_buffer, int32_t i32_param)
// {
//   // Add parameter with varint encoding
//   uint8_t u8_index = 0;
//   while (i32_param >= 0x80) {
//       pu8_buffer[u8_index++] = (uint8_t)((i32_param & 0x7F) | 0x80);
//       i32_param >>= 7;
//   }
//   pu8_buffer[u8_index++] = (uint8_t)i32_param;
//   return u8_index;
// }

// /******************************************************************************/
// static uint8_t addParameterAsString(uint8_t *const pu8_buffer, uint8_t u8_bufferSize,const char * const pstr_param)
// {
//   uint8_t u8_size = MIN(u8_bufferSize, strlen(pstr_param));
//   memcpy(pu8_buffer, pstr_param, u8_size);
//   return u8_size;
// }
