/*
 * File: I2C_LCD_cfg.c
 * Driver Name: [[ I2C_LCD Display ]]
 * SW Layer:   ECUAL
 * Created on: Jan 28, 2024
 * Author:     Khaled Magdy
 * -------------------------------------------
 * For More Information, Tutorials, etc.
 * Visit Website: www.DeepBlueMbedded.com
 *
 */

#include "I2C_LCD_cfg.h"
#include "I2C_LCD.h"

extern I2C_HandleTypeDef i2c;

const I2C_LCD_CfgType I2C_LCD_CfgParam[I2C_LCD_MAX] =
{
	{   /*  Configuration Parameter For I2C_LCD Instance #1   */
		I2C_LCD_1,	/* Index of I2C_LCD Instance #1           */
		&i2c,		/* Hardware I2C Module's Handle           */
		0x27,		/* Hardware I2C_LCD Device Address        */
		20,			/* LCD Columns Count                      */
		4			/* LCD Rows Count                         */
	}
};
