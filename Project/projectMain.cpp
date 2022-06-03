#include "main.h"
#include <Project/SWO.h>
#include <Project/projectMain.h>
#include <array>
#include <cstdio>
#include <span>

struct Led
{
    explicit Led(GPIO_TypeDef* t_gpio, uint16_t t_pin)
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
    uint16_t pin;
};

void projectMain()
{
    Led led(GPIOD, GPIO_PIN_15);

    // Newer C++ features
    constexpr auto arr = std::to_array({1, 2, 3, 4, 5});
    auto view = std::span(arr);

    while (true)
    {
        led.toggle();
        SWO_PrintDefault("Hello, world!\n");
        HAL_Delay(1000);
    }
}
