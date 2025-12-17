.section .text

reset_handler:
  # set all registers to zero
  mv  x1, x0
  mv  x2, x1
  mv  x3, x1
  mv  x4, x1
  mv  x5, x1
  mv  x6, x1
  mv  x7, x1
  mv  x8, x1
  mv  x9, x1
  mv x10, x1
  mv x11, x1
  mv x12, x1
  mv x13, x1
  mv x14, x1
  mv x15, x1
  mv x16, x1
  mv x17, x1
  mv x18, x1
  mv x19, x1
  mv x20, x1
  mv x21, x1
  mv x22, x1
  mv x23, x1
  mv x24, x1
  mv x25, x1
  mv x26, x1
  mv x27, x1
  mv x28, x1
  mv x29, x1
  mv x30, x1
  mv x31, x1

  # Initialize stack pointer
  la   x2, _stack_start
  
_start:
  .global _start

  # Set MSTATUS bit 3 (Enable interrupts)
  addi x5,x0,8  
  csrrw x0, mstatus, x5
  # Set MIE reg bits 21 (UART_TX), 20 (UART_RX), 17 (I2C), 11 (GPIO), AND 7 (Timer) to enable their interrupts
  li x5, 0x320880
  csrrw x0, mie, x5
  
  # Load BSS start and end addresses
  la x26, _bss_start
  la x27, _bss_end

  bge x26, x27, zero_loop_end
  
  # Zero out BSS section
zero_loop:
  sw x0, 0(x26)
  addi x26, x26, 4
  ble x26, x27, zero_loop
zero_loop_end:


main_entry:
  # Jump to main (argc = argv = 0)
  addi x10, x0, 0
  addi x11, x0, 0
  jal x1, main

  # Sleep loop if main returns
sleep_loop:
  wfi
  j sleep_loop

# Add two nops at the end for prefetch buffer protection  
.section .nops, "ax"
nop
nop

#
# === [ exceptions ] === 
# This section has to be down here, since we have to disable rvc for it  

  .section .vectors, "ax" ;#Alocatable and executable
  .option norvc; # Disable compressed instructions for the vector table

 # All unimplemented interrupts/exceptions go to the DEFAULT_IRQHandler
 
  .org 0x00

  # --- Vectors for Interrupt IDs 0-6 ---
  .rept 7
  jal x0, DEFAULT_IRQHandler
  .endr

  # --- Vector for Machine Timer Interrupt (ID 7) ---
  jal x0, TIMER_IRQHandler

  # --- Vectors for Interrupt IDs 8-10 ---
  .rept 3
  jal x0, DEFAULT_IRQHandler
  .endr

  # --- Vector for External Interrupt (ID 11, GPIO) ---
  jal x0, GPIO_IRQHandler

  # --- Vectors for Interrupt IDs 12-16 ---
  .rept 5
  jal x0, DEFAULT_IRQHandler
  .endr

  # --- Vector for Fast Interrupt (ID 17, I2C) ---
  jal x0, I2C_IRQHandler

  # --- Vector for Fast Interrupt (ID 18, UART_RX_HALF_FULL) ---
  jal x0, UART_RX_HALF_FULL_IRQHandler

  # --- Vector for Fast Interrupt (ID 19, UART_TX_HALF_EMPTY) ---
  jal x0, UART_TX_HALF_EMPTY_IRQHandler

  # --- Vector for Fast Interrupt (ID 20, UART_RX_NOT_EMPTY) ---
  jal x0, UART_RX_NOT_EMPTY_IRQHandler

  # --- Vector for Fast Interrupt (ID 21, UART_TX_NOT_FULL) ---
  jal x0, UART_TX_NOT_FULL_IRQHandler

  # --- Fill the rest of the table ---
  .rept 9
  jal x0, DEFAULT_IRQHandler
  .endr

  .org 0x80
  jal x0, reset_handler
