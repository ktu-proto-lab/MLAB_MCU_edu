// ARDUINO A4 pin --> Custom PMod 3 pin --> EEPROM SDA (5 pin)
// ARDUINO A5 pin --> Custom PMod 4 pin --> EEPROM SCL (6 pin)
// To SDA and SCL pins 10k pullups is added


//Custom PMod pinout
// 01 02 03 04 05 06
// 07 08 09 10 11 12


//EEPROM 23CS512 pinout

//               __ ___
// GND <-- A0  1 |    | 8 VCC --> +5V
// GND <-- A1  2 |    | 7 WP  --> GND
// GND <-- A2  3 |    | 6 SCL --> ARDUINO A4
// GND <-- VSS 4 |    | 5 SDA --> ARDUINO A5
//               ------


#define DATA_LENGTH 19 // 1 bit R/W, 2 bits addr pointer, 16 bits data 
#define EEPROM_ADDR 0xA0 >> 1

#include <Arduino.h>
#include <Wire.h>



uint8_t data[DATA_LENGTH];

// Setup, initialize 
void setup() 
{
  Wire.begin(D2, D1); // SDA = D2 (GPIO4), SCL = D1 (GPIO5)
  Wire.setClock(100000);  // Go back to safe default
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
    Serial.write('R');  // Tell host you're ready for next packet
}
  

// Loop forever
void loop() 
{
  //Wait until data from serial gets transfered

  if (Serial.available() == DATA_LENGTH) {
    digitalWrite(LED_BUILTIN,0);
    // read the incoming byte:
    uint8_t bytesRead = Serial.readBytes(data, DATA_LENGTH); // Get the data
    
//    Serial.write(data,bytesRead);
    if (data[0]=='W'){
      // Remove first element from array (R/W bit)
      uint8_t data_to_write[bytesRead-1];
      for (int i=1; i<=bytesRead; i++){
        data_to_write[i-1]=data[i];
      }
      Wire.beginTransmission(EEPROM_ADDR); //Write EEPROM I2C address
      Wire.write(data_to_write, bytesRead-1); // Write data received from serial
      Wire.endTransmission();
    
      delay(6); //Wait for EEPROM to save data from buffer
    
      Wire.beginTransmission(EEPROM_ADDR); //Write EEPROM I2C address
      Wire.write(data_to_write[0]); //Set EEPROM pointer address 
      Wire.write(data_to_write[1]); //Set EEPROM pointer address 
      Wire.endTransmission(); 

      Serial.write(data_to_write[0]); //Send EEPROM pointer address back to serial
      Serial.write(data_to_write[1]); //Send EEPROM pointer address back to serial

      Wire.requestFrom(EEPROM_ADDR, bytesRead-3); // Read writen data from EEPORM
      while(Wire.available()) {
        uint8_t c = Wire.read();    // Receive a byte as character
        Serial.write(c);         // Print the character to serial
      }
    }
    if (data[0]=='R'){
      Wire.beginTransmission(EEPROM_ADDR); //Write EEPROM I2C address
      Wire.write(data[1]); //Set EEPROM pointer address 
      Wire.write(data[2]); //Set EEPROM pointer address 
      Wire.endTransmission();
      
      Serial.write(data[1]); //Send EEPROM pointer address back to serial
      Serial.write(data[2]); //Send EEPROM pointer address back to serial
      
      Wire.requestFrom(EEPROM_ADDR, bytesRead-3); // Read writen data from EEPORM
      while(Wire.available()) {
        uint8_t c = Wire.read();    // Receive a byte as character
        Serial.write(c);         // Print the character to serial
      }
    }
  }
  digitalWrite(LED_BUILTIN,1);
}
