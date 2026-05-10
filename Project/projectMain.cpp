#include "main.h"
#include <Project/SWO.h>
#include <Project/projectMain.h>

#include <array>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <span>
#include <unistd.h>

struct Led
{
    explicit Led(GPIO_TypeDef* t_gpio, std::uint16_t t_pin)
        : gpio(t_gpio)
        , pin(t_pin)
    {
    }
    void on()
    {
        HAL_GPIO_WritePin(gpio, pin, GPIO_PIN_SET);
    }
    void off()
    {
        HAL_GPIO_WritePin(gpio, pin, GPIO_PIN_RESET);
    }
    void toggle()
    {
        HAL_GPIO_TogglePin(gpio, pin);
    }
    auto state() -> bool
    {
        return HAL_GPIO_ReadPin(gpio, pin);
    }

private:
    GPIO_TypeDef* gpio;
    std::uint16_t pin;
};

extern "C" ssize_t _write(int fd, const void* buffer, size_t count)
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

void projectMain()
{
    Led led(GPIOD, GPIO_PIN_15);

    // Newer C++ features
    constexpr auto arr = std::to_array({1, 2, 3, 4, 5});
    auto view = std::span(arr);

    while (true)
    {
        led.toggle();

        static std::uint8_t index = 0;
        constexpr auto maxIndexDigits = std::numeric_limits<decltype(index)>::digits10 + 1;

        printf("%.*d Hello, world!\n", maxIndexDigits, index++);
        // SWO_PrintDefault("Hello, world!\n");

        HAL_Delay(1000);
    }
}
