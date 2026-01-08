#include "main.h"

volatile gpio_handle g_gpio_handle;
uint8_t g_main_flag = 0;

void TEST_imem_call_0(const uint8_t called_from_main) {
  SYS_FILL_IMEM_2KB();
  if (called_from_main) {
    g_gpio_handle.regs->OE = GPIO_PIN_0;
    g_gpio_handle.regs->OUT = GPIO_PIN_0;
    TEST_imem_call_1();
    main();
  } else {
    g_gpio_handle.regs->OE |= GPIO_PIN_4;
    g_gpio_handle.regs->OUT |= GPIO_PIN_4;
    main();
  }
  SYS_FILL_IMEM_2KB();
  main();
  g_gpio_handle.regs->OE |= GPIO_PIN_6;
  g_gpio_handle.regs->OUT |= GPIO_PIN_6;
}

void TEST_imem_call_2() {
  g_gpio_handle.regs->OE |= GPIO_PIN_2;
  g_gpio_handle.regs->OUT |= GPIO_PIN_2;
  SYS_FILL_IMEM_2KB();
  main();
  SYS_FILL_IMEM_256B();
  TEST_imem_call_3();
  main();
  SYS_FILL_IMEM_2KB();
}

int main() {
  // For random memory hopping.
  if (g_main_flag) {
    return 0;
  }
  g_main_flag = 1;
  enum test_state state = TEST_STATE_INITIALIZED;
  gpio_handle_init(&g_gpio_handle);
  g_gpio_handle.regs->INTE = GPIO_PIN_8;
  g_gpio_handle.regs->CTRL = GPIO_CTRL_ENA_INT;
  state = TEST_STATE_WAIT_GPIO_PIN_8_IRQ;
  while (1) {
    if (state == TEST_STATE_WAIT_GPIO_PIN_8_IRQ) {
      if (g_gpio_handle.ints == GPIO_PIN_8) {
        g_gpio_handle.ints = 0;
        state = TEST_STATE_STARTED;
      } else {
        continue;
      }
    } else if (state == TEST_STATE_STARTED) {
      state = TEST_STATE_IMEM_HOPPING_STARTED;
      TEST_imem_call_0(1);
      state = TEST_STATE_IMEM_HOPPING_FINISHED;
    } else if (state == TEST_STATE_IMEM_HOPPING_FINISHED) {
      g_gpio_handle.regs->OE |= GPIO_PIN_7;
      g_gpio_handle.regs->OUT |= GPIO_PIN_7;
      break;
    } else {
      const int DEBUG_MAIN_WHILE_UNKNOWN_TEST_STATE = 1;
      while (DEBUG_MAIN_WHILE_UNKNOWN_TEST_STATE);
    }
  }
  return 0;
}

void gpio_irq_handler_callback(volatile gpio_handle *gpio) {
  g_gpio_handle.regs->OE = GPIO_PIN_0;
  g_gpio_handle.regs->OUT = GPIO_PIN_0;
}

void TEST_imem_call_1() {
  main();
  g_gpio_handle.regs->OE |= GPIO_PIN_1;
  g_gpio_handle.regs->OUT |= GPIO_PIN_1;
  SYS_FILL_IMEM_2KB();
  main();
  TEST_imem_call_2();
}

void TEST_imem_call_3() {
  main();
  g_gpio_handle.regs->OE |= GPIO_PIN_3;
  g_gpio_handle.regs->OUT |= GPIO_PIN_3;
  SYS_FILL_IMEM_1KB();
  TEST_imem_call_0(0);
  SYS_FILL_IMEM_2KB();
  main();
  SYS_FILL_IMEM_1KB();
  SYS_FILL_IMEM_64B();
  SYS_FILL_IMEM_16B();
  SYS_FILL_IMEM_16B();
  SYS_FILL_IMEM_16B();
  g_gpio_handle.regs->OE |= GPIO_PIN_5;
  main();
  SYS_FILL_IMEM_4B();
  SYS_FILL_IMEM_4B();
  SYS_FILL_IMEM_4B();
  g_gpio_handle.regs->OUT |= GPIO_PIN_5;
  main();
}