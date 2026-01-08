#include <stdint.h>

#include "gpio.h"

#define SYS_FILL_IMEM_4B() asm volatile("nop" ::: "memory")

#define SYS_FILL_IMEM_16B() \
  SYS_FILL_IMEM_4B();       \
  SYS_FILL_IMEM_4B();       \
  SYS_FILL_IMEM_4B();       \
  SYS_FILL_IMEM_4B()

#define SYS_FILL_IMEM_64B() \
  SYS_FILL_IMEM_16B();      \
  SYS_FILL_IMEM_16B();      \
  SYS_FILL_IMEM_16B();      \
  SYS_FILL_IMEM_16B()

#define SYS_FILL_IMEM_256B() \
  SYS_FILL_IMEM_64B();       \
  SYS_FILL_IMEM_64B();       \
  SYS_FILL_IMEM_64B();       \
  SYS_FILL_IMEM_64B();

#define SYS_FILL_IMEM_1KB() \
  SYS_FILL_IMEM_256B();     \
  SYS_FILL_IMEM_256B();     \
  SYS_FILL_IMEM_256B();     \
  SYS_FILL_IMEM_256B();

#define SYS_FILL_IMEM_2KB() \
  SYS_FILL_IMEM_1KB();      \
  SYS_FILL_IMEM_1KB();

enum test_state {
  TEST_STATE_INITIALIZED,
  TEST_STATE_WAIT_GPIO_PIN_8_IRQ,
  TEST_STATE_STARTED,
  TEST_STATE_IMEM_HOPPING_STARTED,
  TEST_STATE_IMEM_HOPPING_FINISHED
};

extern volatile gpio_handle g_gpio_handle;

void TEST_imem_call_0(const uint8_t called_from_main);
void TEST_imem_call_1();
void TEST_imem_call_2();
void TEST_imem_call_3();

int main();