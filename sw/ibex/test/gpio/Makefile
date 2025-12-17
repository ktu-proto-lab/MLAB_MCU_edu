PROGRAM = gpio_example

COMMON_DIR := $(abspath ../../common)

C_SOURCES =  \
core/src/main.c \
core/src/int.c \
drivers/src/gpio.c

C_INCLUDES =  \
-Icore/inc \
-Idrivers/inc


#OBJS = $(patsubst %.c,$(BUILD_DIR)%.o,$(SRCS))

include $(COMMON_DIR)/common.mk
