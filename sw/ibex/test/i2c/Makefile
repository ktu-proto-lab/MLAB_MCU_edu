PROGRAM = i2c

COMMON_DIR := $(abspath ../../common)

C_SOURCES =  \
core/src/main.c \
core/src/int.c \
drivers/src/i2c_master.c


C_INCLUDES =  \
-Icore/inc \
-Idrivers/inc


#OBJS = $(patsubst %.c,$(BUILD_DIR)%.o,$(SRCS))

include $(COMMON_DIR)/common.mk
