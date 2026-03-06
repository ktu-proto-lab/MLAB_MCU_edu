PROGRAM = flash_memory

COMMON_DIR := $(abspath ../../common)

C_SOURCES = \
core/src/main.c \
core/src/int.c	\
drivers/src/gpio.c \
drivers/src/timer.c \
drivers/src/i2c_master.c


C_INCLUDES =  \
-Icore/inc \
-Idrivers/inc


include $(COMMON_DIR)/common.mk
