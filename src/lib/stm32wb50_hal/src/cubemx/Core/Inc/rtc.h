/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    rtc.h
  * @brief   This file contains all the function prototypes for
  *          the rtc.c file
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __RTC_H__
#define __RTC_H__

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "common.h"

/* USER CODE BEGIN Includes */

#define CFG_RTCCLK_DIV            (16U)
#define CFG_RTC_WUCKSEL_DIVIDER   (0U)
#define CFG_RTC_ASYNCH_PRESCALER  (0x7FU)
#define CFG_RTC_SYNCH_PRESCALER   (0x00FFU)

#define CFG_TS_TICK_VAL           DIVR( (CFG_RTCCLK_DIV * 1000000U), LSE_VALUE )
#define CFG_TS_TICK_VAL_PS        DIVR( ((uint64_t)CFG_RTCCLK_DIV * 1e12U), (uint64_t)LSE_VALUE )

#define MS_TO_TICK(value) (value * 1000U / CFG_TS_TICK_VAL)

/* USER CODE END Includes */

extern RTC_HandleTypeDef hrtc;

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

void MX_RTC_Init(void);

/* USER CODE BEGIN Prototypes */

/* USER CODE END Prototypes */

#ifdef __cplusplus
}
#endif

#endif /* __RTC_H__ */

