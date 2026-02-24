PROGRAM = uart_simple

COMMON_DIR := $(abspath ../../common)

C_SOURCES =  \
core/src/main.c \
core/src/int.c  \
drivers/src/gpio.c \
drivers/src/uart.c


C_INCLUDES =  \
-Icore/inc \
-Idrivers/inc \
-I$(COMMON_DIR)/lib/newlib_build/riscv64-unknown-elf/include \
-specs=$(COMMON_DIR)/lib/newlib_build/riscv64-unknown-elf/lib/nosys.specs



#OBJS = $(patsubst %.c,$(BUILD_DIR)%.o,$(SRCS))

include $(COMMON_DIR)/common.mk
