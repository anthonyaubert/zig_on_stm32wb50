#pragma once

#include "FreeRTOS.h"
#include "cmsis_os2.h"
#include "event_groups.h"
#include "queue.h"

#include <stdbool.h>
#include <stdint.h>

#include "cmsis_gcc.h"


/**
 *  \brief Critical Section definition
 **/

#define BACKUP_PRIMASK()    uint32_t primask_bit= __get_PRIMASK()
#define DISABLE_IRQ()       __disable_irq()
#define RESTORE_PRIMASK()   __set_PRIMASK(primask_bit)

#define PLATFORM_ENTER_CRITICAL_SECTION( )   BACKUP_PRIMASK();\
                                    DISABLE_IRQ()

#define PLATFORM_EXIT_CRITICAL_SECTION( )    RESTORE_PRIMASK()



#define Platform_Malloc pvPortMalloc
#define Platform_Free   vPortFree

#define Platform_Delay(delayMs) vTaskDelay(pdMS_TO_TICKS(delayMs))
