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
uint8_t g_UART_TX_cmpl_callback = 0;
volatile GPIO_reg_map_t *GPIO;
UART_HandleTypeDef huart;
char uart_tx_buf[38] = "[SUCCESS]: UART non-blocking transmit\n";


int main() {
  enum TEST_STATE test_state = TEST_STATE_START;

  GPIO = GPIO_init();
  volatile timer_reg_map_t *const TIMER = timer_init();
  I2C_HandleTypeDef I2C;
  const uint32_t I2C_SPEED_KHZ = 400;
  const uint32_t CPU_FREQ_MHZ = 80;
  OC_I2C_Init(&I2C, I2C_BASE_ADDR, I2C_SPEED_KHZ, CPU_FREQ_MHZ);
  // 2 addr bytes (addr 0x8000 decimal 32768) + 2 data bytes.
  uint8_t TEST_WRITE_DATA[4] = {0x80, 0x00, 0xBC, 0xBD};
  uint8_t TEST_READ_DATA[2];
  const uint8_t I2C_DEV_ADDR = 0b10100000;

  huart.Init.BaudRate = UART_BAUD_INTERVAL(80, 115200);
  huart.Init.WordLength = 0;
  huart.Init.StopBits = 0;
  huart.Init.Parity = 0;
  huart.Init.ParityMode = 0;
  huart.Init.ParityLock = 0;

  UART_Init(&huart);
  UART_TX_Enable(&huart);
  UART_RX_Enable(&huart);

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
        // GPIO_PIN_0 and 1 are used by the UART.
        GPIO->OE = GPIO_PIN_2;
        GPIO->OUT = GPIO_PIN_2;
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
        GPIO->OE |= GPIO_PIN_3;
        GPIO->OUT |= GPIO_PIN_3;
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
        GPIO->OE |= GPIO_PIN_4;
        GPIO->OUT |= GPIO_PIN_4;
        test_state = TEST_STATE_I2C_READ_FROM_EEPROM;
        break;
      case TEST_STATE_I2C_READ_FROM_EEPROM:
        OC_I2C_Master_Receive(&I2C, I2C_DEV_ADDR, TEST_READ_DATA, sizeof(uint16_t));
        test_state = TEST_STATE_SET_GPIO_3;
        break;
      case TEST_STATE_SET_GPIO_3:
        GPIO->OE |= GPIO_PIN_5;
        GPIO->OUT |= GPIO_PIN_5;
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
        GPIO->OE |= GPIO_PIN_6;
        GPIO->OUT |= GPIO_PIN_6;
        test_state = TEST_STATE_UART_TX;
        break;
      case TEST_STATE_UART_TX:
        UART_Transmit_IT(&huart, (uint8_t *)uart_tx_buf, sizeof(uart_tx_buf));
        test_state = TEST_STATE_UART_TX_WAIT_CPLT;
        break;
      case TEST_STATE_UART_TX_WAIT_CPLT:
        // State changes when the UART_TxCpltCallback is called.
        if (g_UART_TX_cmpl_callback) {
          UART_TX_Disable(&huart);
          test_state = TEST_STATE_UART_TX_CPLT;
        }
        break;
      case TEST_STATE_UART_TX_CPLT:
        GPIO->OE |= GPIO_PIN_7;
        GPIO->OUT |= GPIO_PIN_7;
        // TODO: change to rx state, when receive is implemented
        test_state = TEST_STATE_FINISH;
        break;
      case TEST_STATE_UART_RX:
        // void UART_Receive_IT(UART_HandleTypeDef *huart, uint8_t *pData, uint16_t Size);
        const int DEBUG_WHILE_TEST_STATE_UART_RX = 1;
        while(DEBUG_WHILE_TEST_STATE_UART_RX);
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

void UART_TxCpltCallback(UART_HandleTypeDef *huart) {
  g_UART_TX_cmpl_callback = 1;
}

void UART_RxCpltCallback(UART_HandleTypeDef *huart) { }