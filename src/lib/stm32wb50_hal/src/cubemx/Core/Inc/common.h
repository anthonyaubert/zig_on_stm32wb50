/**
 *
 * @file common.h
 * @brief Definition of common macros
 */

#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#if defined( UNITTEST )
    #include "minunit.h"
#endif

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

/**
 *  \brief Basic definitions
 **/

#undef NULL
#define NULL                    0

#undef FALSE
#define FALSE                   0

#undef TRUE
#define TRUE                    (!0)

#define EVENT_BIT( event )    ( ( uint32_t ) 0x1 << event )


/**
 *  \brief Macro delimiters
 **/

#define M_BEGIN     do {

#define M_END       } while(0)


/**
 * Stringify macro.
 */
#define STRINGIFY(x)      STRINGIFY_(x)

/**
 * Stringify macro.
 * Private use for macro-expansion
 */
#define STRINGIFY_(x)     #x

/**
 * Get parts of integers
 * @{
 */
#define GET_MSB_U8(u8_val)              (u8)((u8_val & 0xF0) >> 4)
#define GET_LSB_U8(u8_val)              (u8)(u8_val & 0x0F)
#define GET_MSB_U16(u16_val)            (u8)((u16_val & 0xFF00) >> 8)
#define GET_LSB_U16(u16_val)            (u8)(u16_val & 0x00FF)
/** @} */


/** @} */

/*! @brief Computes the number of elements in an array. */
#if !defined(ARRAY_SIZE)
    #define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#endif

/**
 *  \brief Enum for exec. states.
 */
typedef enum
{
  eNOK = 0,
  eOK = 1
}eStatus;

/**
 *  \brief build an eStatus from bool
 */
#define BUILD_ESTATUS(b_value) ((b_value) ? eOK : eNOK)

/**
 *  \brief AND operation for eStatus
 */
#define AND_ESTATUS(firstEvaledStatement, secondEvaledStatement) (eOK == (firstEvaledStatement) ? (secondEvaledStatement) : eNOK)

#ifndef UNUSED
#define UNUSED(X) (void)(X)      /* To avoid gcc/g++ warnings */
#endif

#define __FILENAME__ (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#if !defined( UNITTEST )
    #define ASSERT(expr) ((expr) ? (void)0U : assert_failed((uint8_t *)__FILENAME__, __LINE__))
    void assert_failed(uint8_t* file, uint32_t line);
#else
    #define ASSERT(expr)   ((expr) ? (void)0U : printf("ASSERT %s %d",__FILENAME__,__LINE__))
#endif

/* Test condition at compile time, not run time */
#ifndef BUILD_ASSERT
#define BA1(cond, file, line, msg)    _Static_assert(cond, file ":" #line ": " msg " (" #cond ")")
#define BA0(c, f, l, msg)             BA1(c, f, l, msg)
/* Pass in an option message to display after condition */
#define BUILD_ASSERT(cond, ...)       BA0(cond, __FILE__, __LINE__, __VA_ARGS__)
#endif
/**
 *  Some useful macro definitions
 **/

#ifndef MAX
#define MAX( x, y )          (((x)>(y))?(x):(y))
#endif

#ifndef MIN
#define MIN( x, y )          (((x)<(y))?(x):(y))
#endif

#ifndef ABS
#define ABS( x, y )          (((x) > (y))?((x)-(y)):((y)-(x)))
#endif

#define MODINC( a, m )       M_BEGIN  (a)++;  if ((a)>=(m)) (a)=0;  M_END

#define MODDEC( a, m )       M_BEGIN  if ((a)==0) (a)=(m);  (a)--;  M_END

#define MODADD( a, b, m )    M_BEGIN  (a)+=(b);  if ((a)>=(m)) (a)-=(m);  M_END

#define MODSUB( a, b, m )    MODADD( a, (m)-(b), m )

#define DIVF( x, y )         ((x)/(y))

#define DIVC( x, y )         (((x)+(y)-1)/(y))

#define DIVR( x, y )         (((x)+((y)/2))/(y))

#define SHRR( x, n )         ((((x)>>((n)-1))+1)>>1)

#define BITN( w, n )         (((w)[(n)/32] >> ((n)%32)) & 1)

#define BITNSET( w, n, b )   M_BEGIN (w)[(n)/32] |= ((U32)(b))<<((n)%32); M_END

#define BIT(rank)            (1 << (rank))

#define BIT_SET(value, rank) ((value) |= BIT(rank))

#define BIT_CLEAR(value, rank) ((value) &= ~BIT(rank))


/*
 * 32-bit integer manipulation macros (little endian)
 */
#define U8PTR_TO_UINT32_BE(uint32_n,pu8_b)                     \
{                                                              \
    (uint32_n) =  ( (uint32_t) (pu8_b)[0] << 24 )              \
                | ( (uint32_t) (pu8_b)[1] << 16 )              \
                | ( (uint32_t) (pu8_b)[2] << 8  )              \
                | ( (uint32_t) (pu8_b)[3] );                   \
}

#define UINT32_TO_U8PTR_LE(uint32_n,pu8_b)                     \
{                                                              \
    (pu8_b)[0] = (uint8_t) ( ( (uint32_n)       ) & 0xFF );    \
    (pu8_b)[1] = (uint8_t) ( ( (uint32_n) >>  8 ) & 0xFF );    \
    (pu8_b)[2] = (uint8_t) ( ( (uint32_n) >> 16 ) & 0xFF );    \
    (pu8_b)[3] = (uint8_t) ( ( (uint32_n) >> 24 ) & 0xFF );    \
}

/**
 *  \brief Compiler
 **/
#define PLACE_IN_SECTION( __x__ )  __attribute__((section (__x__)))

#ifdef WIN32
#define ALIGN(n)
#else
#define ALIGN(n)             __attribute__((aligned(n)))
#endif


#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __COMMON_H__ */

/** @} */
