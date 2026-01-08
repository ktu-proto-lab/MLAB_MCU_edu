#include "main.h"

typedef struct {
  uint8_t timer;
  uint8_t gpio;
  uint8_t i2c_tx;
  uint8_t i2c_rx;
} int_ack;

void int_ack_init(volatile int_ack *ack);

volatile int_ack g_ack;

timer_handle g_timer_handle;
gpio_handle g_gpio_handle;
i2c_handle g_i2c_handle;
uint8_t g_i2c_dev_addr = 0b10100000;
uint8_t g_i2c_tx_buf[4] = {0x80, 0x00, 0xBC, 0xBD};
uint8_t g_i2c_rx_buf[2] = {0x00, 0x00};

int main() {
  // Acknowledgement flag setup.
  int_ack_init(&g_ack);

  // Timer setup.
  timer_handle_init(&g_timer_handle);
  g_timer_handle.regs->MOD = 0x40U;
  g_timer_handle.regs->CTRL = TIMER_CTRL_PRE_SCALR(0x0U);

  // GPIO setup.
  gpio_handle_init(&g_gpio_handle);
#if FPGA == 0
  g_gpio_handle.regs->INTE = GPIO_PIN_0;
#else
  g_gpio_handle.regs->INTE = GPIO_PIN_8;
#endif


  // I2C setup.
  i2c_handle_init(&g_i2c_handle, I2C_BASE_ADDR, 400, 80);

  // Enable interrupts on both peripherals.
  g_gpio_handle.regs->CTRL = GPIO_CTRL_ENA_INT;
  g_timer_handle.regs->CTRL |= (TIMER_CTRL_CNT_EN | TIMER_CTRL_ENA_INT);

  // Wait for timer's interrupt acknowledgement.
  while (!g_ack.timer);

  // Inform in simulation that the nested interrupt test is passed.
  g_gpio_handle.regs->OE |= GPIO_PIN_7;
  g_gpio_handle.regs->OUT |= GPIO_PIN_7;

  return 0;
}

void int_ack_init(volatile int_ack *ack) {
  ack->timer = 0;
  ack->gpio = 0;
  ack->i2c_tx = 0;
  ack->i2c_rx = 0;
}

void timer_irq_handler_callback(timer_handle *timer_handle) {
  // Reset control register to stop the counter completelly.
  timer_handle->regs->CTRL = 0x0U;
  // Wait for GPIO 0 pin interrupt.
  while (!g_ack.gpio);

  // Acknowledge.
  g_ack.timer = 1;

  // See in simulation that timer interrupt is exited successfully.
  timer_handle->regs->MOD = 0xFFFFU;

  // Inform in simulation that timer interrupt is exiting.
  g_gpio_handle.regs->OE |= GPIO_PIN_6;
  g_gpio_handle.regs->OUT |= GPIO_PIN_6;
}

void gpio_irq_handler_callback(gpio_handle *gpio) {
#if FPGA == 0
  const uint32_t GPIO_INT_PIN =  GPIO_PIN_0;
#else
  const uint32_t GPIO_INT_PIN =  GPIO_PIN_8;
#endif
  // Wait for GPIO 0 (GPIO 8 on FPGA build) pin interrupt.
  if ((gpio->ints & GPIO_INT_PIN)) {
      gpio->ints = 0;
      g_ack.gpio = 1;

      // Disable interrupts on GPIO's.
      gpio->regs->INTE = 0x0U;

      // See that the GPIO 0 (GPIO 8 on FPGA) interrupt is successfull.
      gpio->regs->OE = GPIO_PIN_0;
      gpio->regs->OUT = GPIO_PIN_0;

      // Start i2c write to eeprom.
      i2c_master_tx_it(&g_i2c_handle, g_i2c_dev_addr, g_i2c_tx_buf, sizeof(g_i2c_tx_buf));
      
      // Inform that i2c transmit is called.
      gpio->regs->OE |= GPIO_PIN_1;
      gpio->regs->OUT |= GPIO_PIN_1;

      // Now we wait for the full transmit-receive from i2c.
      while (!g_ack.i2c_tx && !g_ack.i2c_rx);

      // Inform that gpio handler callback got the acknowledgement of the i2c.
      gpio->regs->OE |= GPIO_PIN_5;
      gpio->regs->OUT |= GPIO_PIN_5;
    }
}

void i2c_master_tx_cplt_callback(i2c_handle *i2c) {
  // I2C transmit is done.
  g_ack.i2c_tx = 1;

  // Inform that i2c transmit is completed.
  g_gpio_handle.regs->OE |= GPIO_PIN_2;
  g_gpio_handle.regs->OUT |= GPIO_PIN_2;

  // Set address where to write.
  i2c_master_tx(i2c, g_i2c_dev_addr, g_i2c_tx_buf, sizeof(uint16_t));
  i2c_master_rx_it(i2c, g_i2c_dev_addr, g_i2c_rx_buf, sizeof(g_i2c_rx_buf));
}

void i2c_master_rx_cplt_callback(i2c_handle *i2c) {
  // I2C receive is done.
  g_ack.i2c_rx = 1;

  // Inform that i2c receive is completed.
  g_gpio_handle.regs->OE |= GPIO_PIN_3;
  g_gpio_handle.regs->OUT |= GPIO_PIN_3;

  // Check received data (must match transmitted).
  for (int i = 0; i < sizeof(uint16_t); ++i) {
    const uint8_t tx_byte = g_i2c_tx_buf[i+2];
    const uint8_t rx_byte = g_i2c_rx_buf[i];

    // If data is not matching - stall.
    if (tx_byte != rx_byte) {
      // For easer assembly reading.
      const int DEBUG_I2C_RX_CPLT_CALLBACK_FAILURE = 1;
      while(DEBUG_I2C_RX_CPLT_CALLBACK_FAILURE);
    }
  }

  // Inform that i2c transmit-receive data check is successfull.
  g_gpio_handle.regs->OE |= GPIO_PIN_4;
  g_gpio_handle.regs->OUT |= GPIO_PIN_4;
}