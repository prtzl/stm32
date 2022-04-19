#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

    void SWO_PrintChar(char const c, uint8_t const portNumber);
    void SWO_PrintString(char const* s, uint8_t const portNumber);
    void SWO_PrintDefault(char const* str);
    void SWO_PrintDefaultN(char const* str, size_t const len);

#ifdef __cplusplus
}
#endif
