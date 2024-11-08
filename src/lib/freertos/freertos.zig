// Copyright (c) 2023-2024 Francisco Llobet-Blandino and the "Miso Project".
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const std = @import("std");
pub const c = @cImport({
    @cInclude("freertos_kernel/include/FreeRTOS.h");
    @cInclude("task.h");
    @cInclude("timers.h");
    @cInclude("semphr.h");
    @cInclude("message_buffer.h");
});

pub const BaseType_t = c.BaseType_t;
pub const UBaseType_t = c.UBaseType_t;
pub const TickType_t = c.TickType_t;

//  General handle types
pub const TaskHandle_t = c.TaskHandle_t;
pub const QueueHandle_t = c.QueueHandle_t;
pub const SemaphoreHandle_t = c.SemaphoreHandle_t;
pub const TimerHandle_t = c.TimerHandle_t;
pub const MessageBufferHandle_t = c.MessageBufferHandle_t;

pub const PendedFunction_t = c.PendedFunction_t;
pub const TaskFunction_t = c.TaskFunction_t;
pub const TimerCallbackFunction_t = c.TimerCallbackFunction_t;

// Static types
pub const StaticStreamBuffer_t = c.StaticStreamBuffer_t;
pub const StaticTimer_t = c.StaticTimer_t;
pub const StaticTask_t = c.StaticTask_t;
pub const StaticSemaphore_t = c.StaticSemaphore_t;
pub const StaticQueue_t = c.StaticQueue_t;

pub const StackType_t = c.StackType_t;

// Common FreeRTOS constants
pub const pdPASS = c.pdPASS;
pub const pdFAIL = c.pdFAIL;

pub const pdTRUE = c.pdTRUE;
pub const pdFALSE = c.pdFALSE;

pub const portMAX_DELAY = c.portMAX_DELAY;
pub const pdMS_TO_TICKS = c.pdMS_TO_TICKS;

pub const task_priorities = enum(BaseType_t) {
    rtos_prio_idle = 0, // Idle task priority
    rtos_prio_low = 1,
    rtos_prio_below_normal = 2,
    rtos_prio_normal = 3, // Normal Service Tasks
    rtos_prio_above_normal = 4,
    rtos_prio_high = 5,
    rtos_prio_highest = 6, // TimerService
};

// Scheduler State
const eTaskSchedulerState = enum(BaseType_t) { taskSCHEDULER_NOT_STARTED = c.taskSCHEDULER_NOT_STARTED, taskSCHEDULER_SUSPENDED = c.taskSCHEDULER_SUSPENDED, taskSCHEDULER_RUNNING = c.taskSCHEDULER_RUNNING };

pub const FreeRtosError = error{
    pdFAIL,

    TaskCreationFailed,
    TaskHandleAlreadyExists,
    TaskNotifyFailed,

    QueueCreationFailed,
    QueueSendFailed,
    QueueReceiveFailed,

    SemaphoreCreationFailed,
    SemaphoreTakeTimeout,
    TimerCreationFailed,

    TimerStartFailed,
    TimerStopFailed,
    TimerChangePeriodFailed,

    MessageBufferCreationFailed,
    MessageBufferReceiveFailed,
    MessageBufferOverflow,
};

/// Kernel function
pub inline fn vTaskStartScheduler() noreturn {
    c.vTaskStartScheduler();
    unreachable;
}

/// Get current scheduler state
pub inline fn xTaskGetSchedulerState() eTaskSchedulerState {
    return @enumFromInt(c.xTaskGetSchedulerState());
}

pub inline fn xTaskGetCurrentTaskHandle() TaskHandle_t {
    return c.xTaskGetCurrentTaskHandle();
}

fn vPortMalloc(xSize: usize) ?*anyopaque {
    return c.pvPortMalloc(xSize);
}

fn vPortFree(pv: ?*anyopaque) void {
    c.vPortFree(pv);
}

pub fn vTaskDelay(xTicksToDelay: TickType_t) void {
    c.vTaskDelay(xTicksToDelay);
}

pub fn xTaskGetTickCount() TickType_t {
    return c.xTaskGetTickCount();
}

pub inline fn portYIELD_FROM_ISR(xSwitchRequired: BaseType_t) void {
    if (xSwitchRequired != pdFALSE) {
        portYIELD();
    }
}

pub inline fn portYIELD() void {
    // TODO AA replace dependance avec microzig
    // cpu.regs.ICSR.modify(.{ .PENDSVSET = 1 });

    // cpu.dsb();
    // cpu.isb();
}

/// Pend function call to the timer service task
pub fn xTimerPendFunctionCall(xFunctionToPend: PendedFunction_t, pvParameter1: ?*anyopaque, ulParameter2: u32, xTicksToWait: ?TickType_t) !void {
    if (pdTRUE != c.xTimerPendFunctionCall(xFunctionToPend, pvParameter1, ulParameter2, xTicksToWait orelse portMAX_DELAY)) return FreeRtosError.pdFAIL;
}

/// Create a Static Task
pub fn StaticTask(comptime T: type, comptime stackSize: usize, comptime pcName: [*:0]const u8, comptime taskRunnerFn: *const fn (*T) noreturn) type {
    return struct {
        /// Inner Task object
        task: Task = undefined,
        /// Static stack
        stack: [stackSize]StackType_t = undefined,
        /// Static task object for FreeRTOS
        staticTask: StaticTask_t = undefined,

        fn run(pvParameters: ?*anyopaque) callconv(.C) noreturn {
            taskRunnerFn(@as(*T, @ptrCast(@alignCast(pvParameters))));
        }
        pub inline fn create(self: *@This(), pvParameters: *T, uxPriority: UBaseType_t) !void {
            self.task = try Task.createStatic(run, pcName, @ptrCast(@alignCast(pvParameters)), uxPriority, self.stack[0..], &self.staticTask);
        }
        pub inline fn resumeTask(self: *const @This()) void {
            self.task.resumeTask();
        }
        pub inline fn suspendTask(self: *const @This()) void {
            self.task.suspendTask();
        }
        pub inline fn notify(self: *const @This(), ulValue: u32, eAction: Task.eNotifyAction) FreeRtosError!void {
            return self.task.notify(ulValue, eAction);
        }
        pub inline fn notifyFromIsr(self: *const @This(), ulValue: u32, eAction: Task.eNotifyAction, pxHigherPriorityTaskWoken: *BaseType_t) bool {
            return self.task.notifyFromIsr(ulValue, eAction, pxHigherPriorityTaskWoken);
        }
        pub inline fn waitForNotify(self: *const @This(), ulBitsToClearOnEntry: u32, ulBitsToClearOnExit: u32, xTicksToWait: ?TickType_t) !?u32 {
            return self.task.waitForNotify(ulBitsToClearOnEntry, ulBitsToClearOnExit, xTicksToWait);
        }
        pub inline fn getStackHighWaterMark(self: *const @This()) u32 {
            return self.task.getStackHighWaterMark();
        }
        pub inline fn delayTask(self: *const @This(), xTicksToDelay: TickType_t) void {
            self.task.delayTask(xTicksToDelay);
        }
        pub inline fn getHandle(self: *const @This()) TaskHandle_t {
            return self.task.getHandle();
        }
        pub inline fn getTickCount(self: *const @This()) TickType_t {
            return self.task.getTickCount();
        }
    };
}

/// FreeRTOS Task wrapper as Zig struct
pub const Task = struct {
    /// Notify action
    pub const eNotifyAction = enum(u32) {
        eSetBits = c.eSetBits,
        eIncrement = c.eIncrement,
        eSetValueWithOverwrite = c.eSetValueWithOverwrite,
        eSetValueWithoutOverwrite = c.eSetValueWithoutOverwrite,
        eNoAction = c.eNoAction,
    };

    /// FreeRTOS task handle
    handle: TaskHandle_t = undefined,

    pub fn initFromHandle(task_handle: TaskHandle_t) @This() {
        return @This(){ .handle = task_handle };
    }

    pub fn initFromCurrentTask() @This() {
        return @This(){ .handle = xTaskGetCurrentTaskHandle() };
    }

    /// Create a FreeRTOS task using dynamic memory allocation
    pub fn create(pxTaskCode: TaskFunction_t, pcName: [*:0]const u8, usStackDepth: u16, pvParameters: ?*anyopaque, uxPriority: UBaseType_t) !@This() {
        var self: @This() = undefined;

        return if (pdPASS == c.xTaskCreate(pxTaskCode, pcName, usStackDepth, pvParameters, uxPriority, @constCast(&self.handle))) self else FreeRtosError.TaskCreationFailed;
    }
    /// Create a FreeRTOS task using static memory allocation
    pub fn createStatic(pxTaskCode: TaskFunction_t, pcName: [*:0]const u8, pvParameters: ?*anyopaque, uxPriority: UBaseType_t, stack: []StackType_t, pxTaskBuffer: *StaticTask_t) !@This() {
        const self = @This(){ .handle = c.xTaskCreateStatic(pxTaskCode, pcName, stack.len, pvParameters, uxPriority, @as([*c]StackType_t, @ptrCast(stack.ptr)), pxTaskBuffer) };

        return if (self.handle == null) FreeRtosError.TaskCreationFailed else self;
    }

    pub fn setHandle(self: *const @This(), handle: TaskHandle_t) !void {
        if (self.handle != undefined) {
            self.handle = handle;
        } else {
            return FreeRtosError.TaskHandleAlreadyExists;
        }
    }
    /// Helper function that can be used to cast the pvParameters pointer to a reference
    pub inline fn getAndCastPvParameters(comptime T: type, pvParameters: ?*anyopaque) *T {
        return @as(*T, @ptrCast(@alignCast(pvParameters)));
    }

    pub inline fn getHandle(self: *const @This()) TaskHandle_t {
        return self.handle;
    }
    pub inline fn resumeTask(self: *const @This()) void {
        c.vTaskResume(self.handle);
    }
    pub inline fn suspendTask(self: *const @This()) void {
        c.vTaskSuspend(self.handle);
    }
    pub inline fn resumeTaskFromIsr(self: *const @This()) BaseType_t {
        return c.xTaskResumeFromISR(self.handle);
    }

    // Notify Task with given value
    pub inline fn notify(self: *const @This(), ulValue: u32, eAction: eNotifyAction) FreeRtosError!void {
        return if (pdPASS == c.xTaskGenericNotify(self.handle, c.tskDEFAULT_INDEX_TO_NOTIFY, ulValue, @intFromEnum(eAction), null)) return FreeRtosError.TaskNotifyFailed;
    }
    /// Notify Task from ISR with given value
    pub inline fn notifyFromISR(self: *const @This(), ulValue: u32, eAction: eNotifyAction, pxHigherPriorityTaskWoken: *BaseType_t) bool {
        return (pdPASS == c.xTaskNotifyFromISR(self.handle, ulValue, eAction, pxHigherPriorityTaskWoken));
    }

    /// Wait for notification.
    /// This function can only be called from the same task that is waiting for the notification in order to avoid concurrency issues.
    /// Returns error if task object is not the current task
    /// Returns the notification value if the notification was received or null if no notification was received
    /// If xTicksToWait is null, the function will wait indefinitely for the notification
    pub fn waitForNotify(self: *const @This(), ulBitsToClearOnEntry: u32, ulBitsToClearOnExit: u32, xTicksToWait: ?TickType_t) !?u32 {
        var pulNotificationValue: u32 = undefined;

        // The xTaskNotifyWait function supposes that you call it from the task that you want to wait for the notification
        if (self.handle == xTaskGetCurrentTaskHandle()) {
            return if (pdPASS == c.xTaskNotifyWait(ulBitsToClearOnEntry, ulBitsToClearOnExit, &pulNotificationValue, xTicksToWait orelse portMAX_DELAY)) pulNotificationValue else null;
        } else {
            return FreeRtosError.TaskNotifyFailed;
        }
    }

    /// Get own stack high water mark
    pub inline fn getStackHighWaterMark(self: *const @This()) u32 {
        return @intCast(c.uxTaskGetStackHighWaterMark(self.handle));
    }

    /// Delay the task for the given number of ticks
    pub inline fn delayTask(self: *const @This(), xTicksToDelay: TickType_t) void {
        _ = self;
        c.vTaskDelay(xTicksToDelay);
    }

    /// Get the current tick time
    pub inline fn getTickCount(self: *const @This()) TickType_t {
        _ = self;
        return c.xTaskGetTickCount();
    }
};

pub fn StaticBinarySemaphore() type {
    return struct {
        semaphore: Semaphore = undefined,
        staticSemaphore: StaticSemaphore_t = undefined,

        pub inline fn create(self: *@This()) !void {
            self.semaphore = try Semaphore.createBinaryStatic(&self.staticSemaphore);
        }

        pub inline fn take(self: *const @This(), xTicksToWait: ?TickType_t) !bool {
            return self.semaphore.take(xTicksToWait);
        }

        pub inline fn give(self: *const @This()) !void {
            return self.semaphore.give();
        }

        pub inline fn giveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) !void {
            return self.semaphore.giveFromIsr(pxHigherPriorityTaskWoken);
        }
    };
}

pub const Semaphore = struct {
    handle: SemaphoreHandle_t = undefined,

    /// Create a binary Semaphore
    pub fn createBinary() !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateBinary() };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    pub fn createBinaryStatic(pxSemaphoreBuffer: *StaticSemaphore_t) !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateBinaryStatic(pxSemaphoreBuffer) };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    /// Create a counting semaphore
    pub fn createCountingSemaphore(uxMaxCount: u32, uxInitialCount: u32) !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateCounting(uxMaxCount, uxInitialCount) };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    pub fn createCountingSemaphoreStatic(uxMaxCount: u32, uxInitialCount: u32, pxSemaphoreBuffer: *StaticSemaphore_t) !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateCountingStatic(uxMaxCount, uxInitialCount, pxSemaphoreBuffer) };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    /// Create a mutex
    pub fn createMutex() !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateMutex() };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    pub fn createMutexStatic(pxMutexBuffer: *StaticSemaphore_t) !@This() {
        const self = @This(){ .handle = c.xSemaphoreCreateMutexStatic(pxMutexBuffer) };

        return if (self.handle == null) FreeRtosError.SemaphoreCreationFailed else self;
    }

    /// Take the semaphore
    pub fn take(self: *const @This(), xTicksToWait: ?TickType_t) !bool {
        return if (pdTRUE == c.xSemaphoreTake(self.handle, xTicksToWait orelse portMAX_DELAY)) true else FreeRtosError.SemaphoreTakeTimeout;
    }

    /// Give the semaphore
    pub fn give(self: *const @This()) !void {
        if (pdTRUE != c.xSemaphoreGive(self.handle)) return FreeRtosError.pdFAIL;
    }

    /// Give the semaphore from ISR
    pub inline fn giveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) !void {
        if (pdTRUE != c.xSemaphoreGiveFromISR(self.handle, pxHigherPriorityTaskWoken)) return FreeRtosError.pdFAIL;
    }

    /// Initialize Semaphore from handle
    pub fn initFromHandle(handle: SemaphoreHandle_t) @This() {
        return @This(){ .handle = handle };
    }
};

/// Create a static mutex
pub fn StaticMutex() type {
    return struct {
        semaphore: Semaphore = undefined,
        staticSemaphore: StaticSemaphore_t = undefined,

        pub inline fn create(self: *@This()) !void {
            self.semaphore = try Semaphore.createMutexStatic(&self.staticSemaphore);
        }

        pub inline fn take(self: *const @This(), xTicksToWait: ?TickType_t) !bool {
            return self.semaphore.take(xTicksToWait);
        }

        pub inline fn give(self: *const @This()) !void {
            return self.semaphore.give();
        }

        pub inline fn giveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) !void {
            return self.semaphore.giveFromIsr(pxHigherPriorityTaskWoken);
        }
    };
}

/// FreeRTOS mutex
pub const Mutex = struct {
    semaphore: Semaphore = undefined,

    pub inline fn create() !@This() {
        return @This(){ .semaphore = try Semaphore.createMutex() };
    }

    pub inline fn take(self: *const @This(), xTicksToWait: ?TickType_t) !bool {
        return self.semaphore.take(xTicksToWait);
    }

    pub inline fn give(self: *const @This()) !void {
        return self.semaphore.give();
    }

    pub inline fn giveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) !void {
        return self.semaphore.giveFromIsr(pxHigherPriorityTaskWoken);
    }
};

/// Static Timer
///
/// - T: Type of the reference passed to the timer callback function
/// - pcTimerName: Name string of the timer
/// - timerFn: Timer callback function
///
pub fn StaticTimer(comptime T: type, comptime pcTimerName: [*:0]const u8, comptime timerFn: *const fn (self: *T) void) type {
    return struct {
        timer: Timer = undefined,
        staticTimer: StaticTimer_t = undefined,

        /// Timer callback function runner
        fn run(xTimer: TimerHandle_t) callconv(.C) void {
            timerFn(Timer.getIdFromHandle(T, xTimer));
        }
        /// Create a FreeRTOS timer using static memory allocation
        /// - xTimerPeriodInTicks: Timer period in ticks
        /// - autoReload: If true, the timer will automatically reload after it expires
        /// - pvTimerID: Reference passed to the timer callback function
        pub fn create(self: *@This(), xTimerPeriodInTicks: TickType_t, autoReload: bool, pvTimerID: *T) !void {
            self.timer = try Timer.createStatic(pcTimerName, xTimerPeriodInTicks, autoReload, T, pvTimerID, run, &self.staticTimer);
        }
        /// Start the timer
        /// - xTicksToWait: Optional number of ticks to wait for the timer to start
        pub inline fn start(self: *const @This(), xTicksToWait: ?TickType_t) !void {
            return self.timer.start(xTicksToWait);
        }
        /// Stop the timer
        pub inline fn stop(self: *const @This(), xTicksToWait: ?TickType_t) !void {
            return self.timer.stop(xTicksToWait);
        }
        /// Change the period of the timer
        pub inline fn changePeriod(self: *const @This(), xNewPeriod: TickType_t, xBlockTime: ?TickType_t) !void {
            return self.timer.changePeriod(xNewPeriod, xBlockTime);
        }
        /// Reset the timer
        pub inline fn reset(self: *const @This(), xTicksToWait: TickType_t) BaseType_t {
            return self.timer.reset(xTicksToWait);
        }
        /// Get the callback argument
        pub inline fn getId(self: *const @This(), comptime idType: type) ?*T {
            return self.timer.getId(idType);
        }
    };
}

/// Timer
const Timer = struct {
    handle: TimerHandle_t = undefined,

    /// Get the timer ID from the timer handle and cast it into the desired (referenced) type
    /// This function can be used in the timer callback function to get the timer ID
    pub inline fn getIdFromHandle(comptime T: type, xTimer: TimerHandle_t) *T {
        return @as(*T, @ptrCast(@alignCast(c.pvTimerGetTimerID(xTimer))));
    }

    /// Create a FreeRTOS timer
    pub inline fn create(pcTimerName: [*:0]const u8, xTimerPeriodInTicks: TickType_t, autoReload: bool, comptime T: type, pvTimerID: *T, pxCallbackFunction: TimerCallbackFunction_t) !@This() {
        const self: @This() = .{ .handle = c.xTimerCreate(pcTimerName, xTimerPeriodInTicks, if (autoReload) pdTRUE else pdFALSE, @ptrCast(@alignCast(pvTimerID)), pxCallbackFunction) };

        return if (self.handle == null) FreeRtosError.TimerCreationFailed else self;
    }
    /// Create a FreeRTOS timer using static memory allocation
    pub inline fn createStatic(pcTimerName: [*:0]const u8, xTimerPeriodInTicks: TickType_t, autoReload: bool, comptime T: type, pvTimerID: *T, pxCallbackFunction: TimerCallbackFunction_t, pxTimerBuffer: *StaticTimer_t) !@This() {
        const self: @This() = .{ .handle = c.xTimerCreateStatic(pcTimerName, xTimerPeriodInTicks, if (autoReload) pdTRUE else pdFALSE, @ptrCast(@alignCast(pvTimerID)), pxCallbackFunction, @as([*c]StaticTimer_t, pxTimerBuffer)) };

        return if (self.handle == null) FreeRtosError.TimerCreationFailed else self;
    }

    /// Get the timer ID from the own timer and cast it into the desired (referenced) type
    pub inline fn getId(self: *const @This(), comptime T: type) ?*T {
        return @as(?*T, @ptrCast(@alignCast(c.pvTimerGetTimerID(self.timer))));
    }

    /// Start the timer
    pub inline fn start(self: *const @This(), xTicksToWait: ?TickType_t) !void {
        if (pdFAIL == c.xTimerGenericCommand(self.handle, c.tmrCOMMAND_START, c.xTaskGetTickCount(), null, xTicksToWait orelse portMAX_DELAY)) {
            return FreeRtosError.TimerStartFailed;
        }
    }

    /// Stop the timer
    pub inline fn stop(self: *const @This(), xTicksToWait: ?TickType_t) !void {
        if (pdFAIL == c.xTimerGenericCommand(self.handle, c.tmrCOMMAND_STOP, @as(TickType_t, 0), null, xTicksToWait orelse portMAX_DELAY)) {
            return FreeRtosError.TimerStopFailed;
        }
    }

    /// Change the period of the timer
    pub inline fn changePeriod(self: *const @This(), xNewPeriod: TickType_t, xBlockTime: ?TickType_t) !void {
        if (pdFAIL == c.xTimerGenericCommand(self.handle, c.tmrCOMMAND_CHANGE_PERIOD, xNewPeriod, null, xBlockTime orelse portMAX_DELAY)) {
            return FreeRtosError.TimerChangePeriodFailed;
        }
    }

    /// Delete the timer
    pub inline fn delete(self: *const @This(), xTicksToWait: TickType_t) BaseType_t {
        return c.xTimerDelete(self.handle, xTicksToWait);
    }

    /// Reset the timer
    pub inline fn reset(self: *const @This(), xTicksToWait: TickType_t) BaseType_t {
        return c.xTimerReset(self.handle, xTicksToWait);
    }

    /// Initialize Timer from handle
    pub inline fn initFromHandle(handle: TimerHandle_t) @This() {
        return @This(){ .handle = handle };
    }
};

/// Create a static message buffer of desired size
pub fn StaticMessageBuffer(comptime xBufferSizeBytes: usize) type {
    return struct {
        messageBuffer: MessageBuffer = undefined,
        staticMessageBuffer: StaticStreamBuffer_t = undefined,
        buffer: [xBufferSizeBytes]u8 = undefined,

        pub inline fn create(self: *@This()) !void {
            self.messageBuffer = try MessageBuffer.initStatic(self.buffer[0..], &self.staticMessageBuffer);
        }

        pub inline fn send(self: *const @This(), txData: []const u8, comptime xTicksToWait: ?TickType_t) usize {
            return self.messageBuffer.send(txData, xTicksToWait);
        }

        pub inline fn receive(self: *const @This(), rxData: []const u8, ticks_to_wait: ?TickType_t) ?[]u8 {
            return self.messageBuffer.receive(rxData, ticks_to_wait);
        }
    };
}

/// Message Buffer
pub const MessageBuffer = struct {
    /// Handle to the message buffer
    handle: MessageBufferHandle_t = undefined,

    /// Create a message buffer with the given size
    pub inline fn create(xBufferSizeBytes: usize) !@This() {
        var self: @This() = undefined;

        self.handle = c.xStreamBufferGenericCreate(xBufferSizeBytes, 0, pdTRUE, null, null);

        return if (self.handle != null) self else FreeRtosError.MessageBufferCreationFailed;
    }

    pub fn initStatic(buffer: []u8, staticMessageBuffer: *StaticStreamBuffer_t) !@This() {
        var self: @This() = undefined;

        self.handle = c.xStreamBufferGenericCreateStatic(buffer.len, 0, pdTRUE, buffer.ptr, staticMessageBuffer, null, null);

        return if (self.handle != null) self else FreeRtosError.MessageBufferCreationFailed;
    }

    pub inline fn createFromHandle(handle: MessageBufferHandle_t) @This() {
        return @This(){ .handle = handle };
    }

    /// Send a message to the message buffer
    pub inline fn send(self: *const @This(), txData: []const u8, comptime xTicksToWait: ?TickType_t) usize {
        return c.xMessageBufferSend(self.handle, txData.ptr, txData.len, xTicksToWait orelse portMAX_DELAY);
    }

    /// Receive a message from the message buffer
    /// - `rxData`is the buffer to receive the data into
    /// - `ticks_to_wait` is the optional number of ticks to wait for the message to arrive
    /// Returns: A slice of the received data or null if no data was received
    pub fn receive(self: *const @This(), rxData: []const u8, ticks_to_wait: ?TickType_t) ?[]u8 {
        const rx_len: usize = c.xMessageBufferReceive(self.handle, @constCast(rxData.ptr), rxData.len, ticks_to_wait orelse portMAX_DELAY);

        return if (rx_len != 0) @constCast(rxData)[0..rx_len] else null;
    }
};

pub fn StaticQueue(comptime itemType: type, comptime numItems: usize) type {
    return struct {
        queue: Queue(itemType, numItems) = undefined,
        staticQueue: StaticQueue_t = undefined,
        buffer: [numItems]itemType = undefined,

        pub inline fn create(self: *@This()) !void {
            self.queue.createStatic(self.buffer[0..], &self.staticQueue);
        }

        pub inline fn delete(self: *@This()) void {
            self.queue.delete();
        }

        pub inline fn send(self: *const @This(), item: *const itemType, ticks_to_wait: ?TickType_t) !void {
            return self.queue.send(item, ticks_to_wait);
        }

        pub inline fn recieve(self: *const @This(), ticks_to_wait: ?TickType_t) ?itemType {
            return self.queue.recieve(ticks_to_wait);
        }

        pub inline fn recieveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) ?itemType {
            return self.queue.recieveFromIsr(pxHigherPriorityTaskWoken);
        }

        pub inline fn sendFromIsr(self: *const @This(), item: *const itemType, pxHigherPriorityTaskWoken: *BaseType_t) !void {
            return self.queue.sendFromIsr(item, pxHigherPriorityTaskWoken);
        }
        pub inline fn reset(self: *@This()) void {
            self.queue.reset();
        }
    };
}

/// Create a FreeRTOS queue
pub fn Queue(comptime itemType: type, comptime numItems: usize) type {
    return struct {
        handle: QueueHandle_t = undefined,
        fn create(self: *@This()) !void {
            self.handle = c.xQueueCreate(@intCast(numItems), @sizeOf(itemType));
        }
        fn delete(self: *@This()) void {
            c.vQueueDelete(self.handle);
        }
        fn createStatic(self: *@This(), buffer: []itemType, staticQueue: *StaticQueue_t) void {
            self.handle = c.xQueueCreateStatic(numItems, @sizeOf(itemType), @as([*c]u8, @ptrCast(buffer.ptr)), staticQueue);
        }
        fn send(self: *const @This(), item: *const itemType, ticks_to_wait: ?TickType_t) !void {
            if (pdPASS != c.xQueueSend(self.handle, @as([*c]u8, @constCast(@ptrCast(item))), ticks_to_wait orelse portMAX_DELAY)) return FreeRtosError.QueueSendFailed;
        }
        fn recieve(self: *const @This(), ticks_to_wait: ?TickType_t) ?itemType {
            var item: itemType = undefined;
            return if (pdPASS == c.xQueueReceive(self.handle, @ptrCast(&item), ticks_to_wait orelse portMAX_DELAY)) item else null;
        }
        fn recieveFromIsr(self: *const @This(), pxHigherPriorityTaskWoken: *BaseType_t) ?itemType {
            var item: itemType = undefined;
            return if (pdPASS == c.xQueueReceiveFromISR(self.handle, @ptrCast(&item), pxHigherPriorityTaskWoken)) item else null;
        }
        fn sendFromIsr(self: *const @This(), item: *const itemType, pxHigherPriorityTaskWoken: *BaseType_t) !void {
            if (pdPASS != c.xQueueSendFromISR(self.handle, @as([*c]u8, @constCast(@ptrCast(item))), pxHigherPriorityTaskWoken)) return FreeRtosError.QueueSendFailed;
        }
        fn reset(self: *@This()) void {
            _ = c.xQueueReset(self.handle);
        }
    };
}

/// Allocator to use in a FreeRTOS application
pub const allocator = std.mem.Allocator{ .ptr = undefined, .vtable = &allocator_vtable };

/// VTable for the FreeRTOS allocator
const allocator_vtable = std.mem.Allocator.VTable{
    .alloc = freertos_alloc,
    .resize = freertos_resize,
    .free = freertos_free,
};

/// FreeRTOS allocator
fn freertos_alloc(
    _: *anyopaque,
    len: usize,
    log2_ptr_align: u8,
    ret_addr: usize,
) ?[*]u8 {
    _ = ret_addr;
    _ = log2_ptr_align;
    //std.debug.assert(log2_ptr_align <= comptime std.math.log2_int(usize, @alignOf(std.c.max_align_t)));
    // Note that this pointer cannot be aligncasted to max_align_t because if
    // len is < max_align_t then the alignment can be smaller. For example, if
    // max_align_t is 16, but the user requests 8 bytes, there is no built-in
    // type in C that is size 8 and has 16 byte alignment, so the alignment may
    // be 8 bytes rather than 16. Similarly if only 1 byte is requested, malloc
    // is allowed to return a 1-byte aligned pointer.
    return @as(?[*]u8, @ptrCast(vPortMalloc(len)));
}

fn freertos_resize(
    _: *anyopaque,
    buf: []u8,
    log2_old_align: u8,
    new_len: usize,
    ret_addr: usize,
) bool {
    _ = log2_old_align;
    _ = ret_addr;
    return new_len <= buf.len;
}

fn freertos_free(
    _: *anyopaque,
    buf: []u8,
    log2_old_align: u8,
    ret_addr: usize,
) void {
    _ = log2_old_align;
    _ = ret_addr;
    vPortFree(buf.ptr);
}
