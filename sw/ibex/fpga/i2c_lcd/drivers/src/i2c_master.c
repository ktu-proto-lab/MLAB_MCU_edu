#include "i2c_master.h"

void I2C_Init(I2C_HandleTypeDef *i2c, uint32_t BaseAddress, uint16_t Speed,
                 uint8_t CPUFreq) {
  uint16_t prescale =
      I2C_PRESCALE(CPUFreq, Speed);  // Calculate I2C prescaler based on core
                                        // frequency and desired i2c speed

  i2c->regs = (volatile I2C_reg_map_t *)
      BaseAddress;  // Initialize I2C registers struct

  I2C_WAIT_BUSY(i2c);  // Wait until any pending I2C transfers ends
  I2C_DISABLE(i2c);    // Disable I2C core
  if (OC_ISSET(i2c->regs->CSR,
               I2C_IF)) {  // Clear any interupt status if any
    i2c->regs->CSR |= I2C_IACK;
  }

  i2c->regs->PRER_LO = prescale;         // Set prescale lo-byte
  i2c->regs->PRER_HI = (prescale << 8);  // Set prescale hi-byte

  I2C_ENABLE(i2c);  // Enable I2C core

  i2c->State = I2C_STATE_READY;

  return;
}

uint8_t I2C_Master_Send_Byte(I2C_HandleTypeDef *i2c, uint8_t byte,
                                uint8_t flags) {
  // Suggestion: Can add retries if slave fails to ack

  i2c->regs->TRXR = byte;  // Write to Transmit register
  i2c->regs->CSR = flags;  // Write to Control register

  // OC_I2C_WAIT_TIP(i2c);
  __asm__ volatile("nop");  // Do nothing for one instruction (transfer in
                            // progress (TIP) bit sets too late)
  I2C_WAIT_TIP(i2c);     // Wait for transfer in progress to negate

  return I2C_ACK_RECEIVED(i2c) ? 0 : -1;  // Return ACK
}

uint8_t I2C_Master_Read_Byte(I2C_HandleTypeDef *i2c, uint8_t flags) {
  // Suggestion: Can add retries if slave fails to ack

  i2c->regs->CSR = flags;  // Write to Control register

  __asm__ volatile("nop");  // Do nothing for one instruction (transfer in
                            // progres (TIP) sets too late)
  I2C_WAIT_TIP(i2c);

  return (uint8_t)(i2c->regs->TRXR);  // Return received data
}

void I2C_Master_Transmit(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                            uint8_t *Data, uint16_t Size) {
  // Check whether I2C core is busy (for example interupt driven transmision is
  // in progress)
  if (i2c->State != I2C_STATE_READY) {
    return;
  }

  // Send I2C slave address until slaves acknowledges it
  while (
      I2C_Master_Send_Byte(i2c, DevAddress & 0xFE, I2C_STA | I2C_WR));

  // Send data to the I2C slave
  while (Size > 0) {
    uint8_t flags = I2C_WR;  // Always set write data flag
    if (Size == 1) {
      flags |= I2C_STO;
    }  // If last byte is being transfered, set STOP condition
    I2C_Master_Send_Byte(i2c, *Data, flags);  // Send data, and set flags
    Data++;
    Size--;
  }
  i2c->regs->CSR =
      I2C_IACK;  // Clear pending interrupt (Interrupt acknowledge)
}

void I2C_Master_Receive(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                           uint8_t *Data, uint16_t Size) {
  // Check whether I2C core is busy (for example interupt driven transmision is
  // in progress)
  if (i2c->State != I2C_STATE_READY) {
    return;
  }

  // Send I2C slave address until slaves acknowledges it
  while (
      I2C_Master_Send_Byte(i2c, DevAddress | 0x01, I2C_STA | I2C_WR));

  // Receive data from the I2C slave
  while (Size > 0) {
    uint8_t flags = I2C_RD;  // Always set read data flag
    if (Size == 1) {
      flags |= I2C_ACK;
    }  // If last byte is being received, set ACK bit
    *Data = I2C_Master_Read_Byte(i2c, flags);  // Set flags and read data
    Data++;
    Size--;
  }
  i2c->regs->CSR = I2C_STO;  // Generate stop condition
  i2c->regs->CSR =
      I2C_IACK;  // Clear pending interrupt (Interrupt acknowledge)
}

void I2C_Master_Send_Byte_IT(I2C_HandleTypeDef *i2c, uint8_t byte,
                                uint8_t flags) {
  // Suggestion: Can add retries if slave fails to ack

  i2c->regs->TRXR = byte;  // Write to Transmit register
  i2c->regs->CSR = flags;  // Write to Control register
}

void I2C_Master_Read_Byte_IT(I2C_HandleTypeDef *i2c, uint8_t flags) {
  // Suggestion: Can add retries if slave fails to ack
  i2c->regs->CSR = flags;
}

void I2C_Master_Transmit_IT_Sequence(I2C_HandleTypeDef *i2c) {
  if (i2c->Interupt_Transmit.State == I2C_STATE_TX_IT_ADDRESS) {
    // Check if ACK of slave address is received
    // Proceed to data transmision
    // Repeat address transmision
    i2c->Interupt_Transmit.State = I2C_ACK_RECEIVED(i2c) ?
              I2C_STATE_TX_IT_DATA : I2C_STATE_TX_IT_READY;
  }
  if (i2c->Interupt_Transmit.State == I2C_STATE_TX_IT_DATA) {
    // Check if ACK from slave is received
    if (I2C_ACK_RECEIVED(i2c)) {
      uint8_t flags = I2C_WR;  // Always set write data flag
      // If last byte is being sent, set stop condition
      if (i2c->Interupt_Transmit.Size == 1) {
        flags |= I2C_STO;
        i2c->Interupt_Transmit.State = I2C_STATE_TX_IT_END;
      }

      I2C_Master_Send_Byte_IT(i2c, *(i2c->Interupt_Transmit.Data),
                                 flags);  // Send data, and set flags
      i2c->Interupt_Transmit.Data++;
      i2c->Interupt_Transmit.Size--;
      return;
    } else {
      i2c->Interupt_Transmit.State = I2C_STATE_TX_IT_END;
    }
  }
  if (i2c->Interupt_Transmit.State == I2C_STATE_TX_IT_END) {
    i2c->Interupt_Transmit.State = I2C_STATE_TX_IT_READY;
    i2c->State = I2C_STATE_READY;
    I2C_DISABLE_INT(i2c);
    I2C_MasterTxCpltCallback(i2c);
    return;
  }
  if (i2c->Interupt_Transmit.State == I2C_STATE_TX_IT_READY) {
    I2C_Master_Send_Byte_IT(
        i2c, i2c->Interupt_Transmit.Address & 0xFE,
        I2C_STA | I2C_WR);  // Send I2C slave address

    i2c->Interupt_Transmit.State = I2C_STATE_TX_IT_ADDRESS;
    return;
  }
}

void I2C_Master_Receive_IT_Sequence(I2C_HandleTypeDef *i2c) {
  if (i2c->Interupt_Receive.State == I2C_STATE_RX_IT_ADDRESS) {
    // Check if ACK of slave address is received?
    //    Proceed to data transmision : Repeat address transmision
    i2c->Interupt_Receive.State = I2C_ACK_RECEIVED(i2c) ?
              I2C_STATE_RX_IT_DATA : I2C_STATE_RX_IT_READY;
  }
  if (i2c->Interupt_Receive.State == I2C_STATE_RX_IT_GET_DATA) {
    // Check if ACK from slave is received
    if (I2C_ACK_RECEIVED(i2c)) {
      *(i2c->Interupt_Receive.Data) = (uint8_t)(i2c->regs->TRXR);
      i2c->Interupt_Receive.Data++;
      i2c->Interupt_Receive.State = I2C_STATE_RX_IT_DATA;
    }
    else {
      i2c->Interupt_Receive.State = I2C_STATE_RX_IT_END;
    }
  }
  if (i2c->Interupt_Receive.State == I2C_STATE_RX_IT_DATA) {
    // Always set read data flag
    // If last byte is being read, set stop condition
    uint8_t flags = (i2c->Interupt_Receive.Size == 1) ?
                                  (I2C_RD | I2C_ACK) : I2C_RD ;

    I2C_Master_Read_Byte_IT(i2c, flags);  // Read data, and set flags
    i2c->Interupt_Receive.State = I2C_STATE_RX_IT_GET_DATA;
    i2c->Interupt_Receive.Size--;
    return;
  }
  if (i2c->Interupt_Receive.State == I2C_STATE_RX_IT_END) {
    *(i2c->Interupt_Receive.Data) = (uint8_t)(i2c->regs->TRXR);
    i2c->Interupt_Receive.State = I2C_STATE_RX_IT_READY;
    i2c->State = I2C_STATE_READY;  // Return to i2c ready state
    I2C_DISABLE_INT(i2c);          // Disable i2c core interupt
    i2c->regs->CSR = I2C_STO;      // Generate stop condition
    I2C_MasterRxCpltCallback(i2c); // Receive complete callback to user
    return;
  }
  if (i2c->Interupt_Receive.State == I2C_STATE_RX_IT_READY) {
    I2C_Master_Send_Byte_IT(
        i2c, i2c->Interupt_Receive.Address | 0x01,
        I2C_STA | I2C_WR);  // Send I2C slave address

    i2c->Interupt_Receive.State = I2C_STATE_RX_IT_ADDRESS;
    return;
  }
}

void I2C_Master_Transmit_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                               uint8_t *Data, uint16_t Size) {
  // Check whether I2C core is busy
  if (i2c->State != I2C_STATE_READY) {
    return;
  }
  i2c->State = I2C_STATE_BUSY_TX_IT;  // Set I2C state to busy transmiting
                                         // using interupt
  I2C_ENABLE_INT(i2c);                // Enable I2C core interupt

  i2c->Interupt_Transmit.State = I2C_STATE_TX_IT_READY;
  i2c->Interupt_Transmit.Address = DevAddress;  // Save i2c slave address
  i2c->Interupt_Transmit.Data = Data;  // Save data to be transmited pointer
  i2c->Interupt_Transmit.Size = Size;  // Save size of data to be transmited

  I2C_Master_Transmit_IT_Sequence(i2c);
}
void I2C_Master_Receive_IT(I2C_HandleTypeDef *i2c, uint8_t DevAddress,
                              uint8_t *Data, uint16_t Size) {
  // Check whether I2C core is busy
  if (i2c->State != I2C_STATE_READY) {
    return;
  }
  i2c->State = I2C_STATE_BUSY_RX_IT;  // Set I2C state to busy transmiting
                                         // using interupt
  I2C_ENABLE_INT(i2c);                // Enable I2C core interupt

  i2c->Interupt_Receive.State = I2C_STATE_RX_IT_READY;
  i2c->Interupt_Receive.Address = DevAddress;  // Save i2c slave address
  i2c->Interupt_Receive.Data = Data;           // Save received data pointer
  i2c->Interupt_Receive.Size = Size;  // Save size of data to be received

  I2C_Master_Receive_IT_Sequence(i2c);
}

void I2C_IRQ_Handler(I2C_HandleTypeDef *i2c) {
  i2c->regs->CSR =
      I2C_IACK;  // Clear pending interrupt (Interrupt acknowledge)
  // Check if the interrupt was during non-blocking transmit or receive
  if (i2c->State == I2C_STATE_BUSY_TX_IT) {
    I2C_Master_Transmit_IT_Sequence(i2c);
  } else if (i2c->State == I2C_STATE_BUSY_RX_IT) {
    I2C_Master_Receive_IT_Sequence(i2c);
  }
}
