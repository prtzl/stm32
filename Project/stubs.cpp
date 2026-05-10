#include "SWO.h"

#include <cstdio>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

extern "C"
{

    // the following 5 are to shut up newlib when printf is used
    int _close(int file)
    {
        return -1;
    }

    int _fstat(int file, struct stat* st)
    {
        st->st_mode = S_IFCHR;
        return 0;
    }

    int _isatty(int file)
    {
        return 1;
    }

    int _lseek(int file, int ptr, int dir)
    {
        return 0;
    }

    int _read(int file, char* ptr, int len)
    {
        return 0;
    }

    // the following two are needed for -u _printf_float
    int _kill(int pid, int sig)
    {
        errno = EINVAL;
        return -1;
    }

    int _getpid(void)
    {
        return 1;
    }

    // project-specific stub for writing (printf mainly)
    ssize_t _write(int fd, const void* buffer, size_t count)
    {
        // Optional: only support stdout/stderr
        if (fd != STDOUT_FILENO && fd != STDERR_FILENO)
        {
            return -1;
        }

        if (buffer == nullptr)
        {
            return -1;
        }

        auto* data = static_cast<const char*>(buffer);

        for (size_t i = 0; i < count; ++i)
        {
            SWO_PrintChar(data[i], 0);
        }

        return static_cast<ssize_t>(count);
    }
}
