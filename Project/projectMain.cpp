#include <Project/SWO.h>
#include <Project/projectMain.h>

#include <array>
#include <cstdint>
#include <limits>
#include <print>
#include <span>

#include <stm32f407xx.h>
#include <stm32f4xx_hal.h>
#include <stm32f4xx_hal_gpio.h>

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

void projectMain()
{
    Led led(GPIOD, GPIO_PIN_15);

    // Newer C++ features
    constexpr auto arr = std::to_array({1, 2, 3, 4, 5});
    [[maybe_unused]] auto view = std::span(arr);

    while (true)
    {
        led.toggle();

        static std::uint8_t index = 0;
        constexpr auto maxIndexDigits = std::numeric_limits<decltype(index)>::digits10 + 1;

        static float myFloat = 0.55f;

        std::print(
            "{:0{}} Hello, world! {:.6f}\n", index++, maxIndexDigits, myFloat += 0.237f);

        HAL_Delay(1000);
    }
}
