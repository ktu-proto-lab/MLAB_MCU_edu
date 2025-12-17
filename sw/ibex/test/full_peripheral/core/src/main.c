#include "main.h"

#include <stdint.h>

#include "test.h"

// Interrupts.
#include "int.h"

// Drivers.
#include "gpio.h"
#include "i2c_master.h"
#include "timer.h"

uint32_t g_GPIO_int_status = 0;
uint16_t g_TIMER_int_status = 0;
volatile GPIO_reg_map_t *GPIO;

int main() {
  GPIO = GPIO_init();
  enum TEST_STATE test_state = TEST_STATE_START;
  volatile timer_reg_map_t *const TIMER = timer_init();
  I2C_HandleTypeDef I2C;
  const uint32_t I2C_SPEED_KHZ = 400;
  const uint32_t CPU_FREQ_MHZ = 80;
  OC_I2C_Init(&I2C, I2C_BASE_ADDR, I2C_SPEED_KHZ, CPU_FREQ_MHZ);
  // 2 addr bytes (addr 0x8000 decimal 32768) + 2 data bytes.
  const uint8_t TEST_WRITE_DATA[4] = {0x80, 0x00, 0xBC, 0xBD};
  uint8_t TEST_READ_DATA[2];
  const uint8_t I2C_DEV_ADDR = 0b10100000;

  while (1) {
    switch (test_state) {
      case TEST_STATE_START:
        GPIO->INTE = GPIO_PIN_8;
        test_state = TEST_STATE_WAIT_GPIO_8_IRQ;
        GPIO->CTRL = GPIO_CTRL_ENABLE_INT;
        break;
      case TEST_STATE_WAIT_GPIO_8_IRQ:
        if ((g_GPIO_int_status & GPIO_PIN_8)) {
          g_GPIO_int_status = 0;
          GPIO->CTRL = 0;
          test_state = TEST_STATE_SET_GPIO_0;
        }
        break;
      case TEST_STATE_SET_GPIO_0:
        GPIO->OE = GPIO_PIN_0;
        GPIO->OUT = GPIO_PIN_0;
        test_state = TEST_STATE_SET_TIMER;
        break;
      case TEST_STATE_SET_TIMER:
        timer_set(TIMER, (uint16_t)0x400, (uint16_t)0x0);
        timer_en(TIMER);
        test_state = TEST_STATE_WAIT_TIMER_IRQ;
        break;
      case TEST_STATE_WAIT_TIMER_IRQ:
        if (g_TIMER_int_status) {
          g_TIMER_int_status = 0;
          timer_clear_ctrl(TIMER);
          test_state = TEST_STATE_SET_GPIO_1;
        }
        break;
      case TEST_STATE_SET_GPIO_1:
        GPIO->OE |= GPIO_PIN_1;
        GPIO->OUT |= GPIO_PIN_1;
        test_state = TEST_STATE_I2C_WRITE_TO_EEPROM;
        break;
      case TEST_STATE_I2C_WRITE_TO_EEPROM:
        // Write test data buffer to EEPROM.
        OC_I2C_Master_Transmit(&I2C, I2C_DEV_ADDR, TEST_WRITE_DATA, sizeof(TEST_WRITE_DATA));
        // Set EEPROM pointer.
        OC_I2C_Master_Transmit(&I2C, I2C_DEV_ADDR, TEST_WRITE_DATA, sizeof(uint16_t));
        test_state = TEST_STATE_SET_GPIO_2;
        break;
      case TEST_STATE_SET_GPIO_2:
        GPIO->OE |= GPIO_PIN_2;
        GPIO->OUT |= GPIO_PIN_2;
        test_state = TEST_STATE_I2C_READ_FROM_EEPROM;
        break;
      case TEST_STATE_I2C_READ_FROM_EEPROM:
        OC_I2C_Master_Receive(&I2C, I2C_DEV_ADDR, TEST_READ_DATA, sizeof(uint16_t));
        test_state = TEST_STATE_SET_GPIO_3;
        break;
      case TEST_STATE_SET_GPIO_3:
        GPIO->OE |= GPIO_PIN_3;
        GPIO->OUT |= GPIO_PIN_3;
        test_state = TEST_STATE_CHECK_RW_DATA;
        break;
      case TEST_STATE_CHECK_RW_DATA:
        for (uint32_t i = 0; i < sizeof(uint16_t); i++) {
          const uint8_t WRITE_BYTE = TEST_WRITE_DATA[i + 2];  // Offset of 2, because 2 first bytes are address bytes
          const uint8_t READ_BYTE = TEST_READ_DATA[i];
          // Stall if rw bytes don't match (test failed).
          if (WRITE_BYTE != READ_BYTE) {
            const int DEBUG_WHILE_RW_DATA_CHECK_FAIL = 1;
            while (DEBUG_WHILE_RW_DATA_CHECK_FAIL);
          }
        }
        test_state = TEST_STATE_SET_GPIO_4;
        break;
      case TEST_STATE_SET_GPIO_4:
        GPIO->OE |= GPIO_PIN_4;
        GPIO->OUT |= GPIO_PIN_4;
        test_state = TEST_STATE_FINISH;
        break;
      case TEST_STATE_FINISH:
        const int DEBUG_WHILE_TEST_SUCCESS = 1;
        while (DEBUG_WHILE_TEST_SUCCESS);
        break;
      default:
        const int DEBUG_DEFAULT_WHILE = 1;
        while (DEBUG_DEFAULT_WHILE);
    }
  }

  return 0;
}

void gpio_handler() {
  // Record interrupt status and clear all interrupts.
  g_GPIO_int_status = GPIO->INTS;
  GPIO->INTS = 0;
}