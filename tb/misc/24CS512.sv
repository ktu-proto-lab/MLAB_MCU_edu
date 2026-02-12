// *******************************************************************************************************
// **                                                                                                   **
// **   24CS512.v - Microchip 24CS512 512K-BIT I2C SERIAL EEPROM (VCC = +1.7V TO +5.5V)                 **
// **                                                                                                   **
// *******************************************************************************************************
// **                                                                                                   **
// **                   This information is distributed under license from Young Engineering.           **
// **                              COPYRIGHT (c) 2021 YOUNG ENGINEERING                                 **
// **                                      ALL RIGHTS RESERVED                                          **
// **                                                                                                   **
// **                                                                                                   **
// **   Young Engineering provides design expertise for the digital world                               **
// **   Started in 1990, Young Engineering offers products and services for your electronic design      **
// **   project.  We have the expertise in PCB, FPGA, ASIC, firmware, and software design.              **
// **   From concept to prototype to production, we can help you.                                       **
// **                                                                                                   **
// **   http://www.young-engineering.com/                                                               **
// **                                                                                                   **
// *******************************************************************************************************
// **   This information is provided to you for your convenience and use with Microchip products only.  **
// **   Microchip disclaims all liability arising from this information and its use.                    **
// **                                                                                                   **
// **   THIS INFORMATION IS PROVIDED "AS IS." MICROCHIP MAKES NO REPRESENTATION OR WARRANTIES OF        **
// **   ANY KIND WHETHER EXPRESS OR IMPLIED, WRITTEN OR ORAL, STATUTORY OR OTHERWISE, RELATED TO        **
// **   THE INFORMATION PROVIDED TO YOU, INCLUDING BUT NOT LIMITED TO ITS CONDITION, QUALITY,           **
// **   PERFORMANCE, MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR PURPOSE.                         **
// **   MICROCHIP IS NOT LIABLE, UNDER ANY CIRCUMSTANCES, FOR SPECIAL, INCIDENTAL OR CONSEQUENTIAL      **
// **   DAMAGES, FOR ANY REASON WHATSOEVER.                                                             **
// **                                                                                                   **
// **   It is your responsibility to ensure that your application meets with your specifications.       **
// **                                                                                                   **
// *******************************************************************************************************
// **   Revision       : 1.0                                                                            **
// **   Modified Date  : 1/19/2021                                                                      **
// **   Revision History:                                                                               **
// **                                                                                                   **
// **   1/19/2021:  Initial design                                                                      **
// **                                                                                                   **
// *******************************************************************************************************
// **                                       TABLE OF CONTENTS                                           **
// *******************************************************************************************************
// **---------------------------------------------------------------------------------------------------**
// **   DECLARATIONS                                                                                    **
// **---------------------------------------------------------------------------------------------------**
// **---------------------------------------------------------------------------------------------------**
// **   INITIALIZATION                                                                                  **
// **---------------------------------------------------------------------------------------------------**
// **---------------------------------------------------------------------------------------------------**
// **   I/O LOGIC - I2C                                                                                 **
// **---------------------------------------------------------------------------------------------------**
// **   1.01:  START Bit Detection                                                                      **
// **   1.02:  STOP Bit Detection                                                                       **
// **   1.03:  Input Shift Register                                                                     **
// **   1.04:  Input Bit Counter                                                                        **
// **   1.05:  Control Byte Register                                                                    **
// **   1.06:  Word Address Register                                                                    **
// **   1.07:  Write Data Buffer                                                                        **
// **   1.08:  Write Acknowledge Generator                                                              **
// **   1.09:  Acknowledge Detect                                                                       **
// **   1.10:  STOP Flag Removal                                                                        **
// **   1.11:  Read Data Processor                                                                      **
// **   1.12:  Read Address Increment                                                                   **
// **   1.13:  SDA Data I/O Buffer                                                                      **
// **   1.14:  High Speed Mode                                                                          **
// **   1.15:  Manufacturer ID Read Logic                                                               **
// **                                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **   CORE LOGIC - EEPROM                                                                             **
// **---------------------------------------------------------------------------------------------------**
// **   2.01:  EEPROM Write Operation Logic                                                             **
// **   2.02:  EEPROM Memory Write Cycle                                                                **
// **   2.03:  EEPROM Memory Read Logic                                                                 **
// **   2.04:  EEPROM Write Protection Logic                                                            **
// **                                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **   CORE LOGIC - SECURITY/CONFIG REGISTER                                                           **
// **   3.01:  Security/Config Reg Write Operation Logic                                                **
// **   3.02:  Security/Config Reg Write Cycle                                                          **
// **   3.03:  Security/Config Reg Read Logic                                                           **
// **   
// **---------------------------------------------------------------------------------------------------**
// **---------------------------------------------------------------------------------------------------**
// **   DEBUG LOGIC                                                                                     **
// **---------------------------------------------------------------------------------------------------**
// **   4.01:  Memory Data Bytes                                                                        **
// **   4.02:  Write Data Buffer                                                                        **
// **                                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **   TIMING CHECKS                                                                                   **
// **---------------------------------------------------------------------------------------------------**
// **                                                                                                   **
// *******************************************************************************************************

`timescale 1ns/10ps

module M24CS512 (A0, A1, A2, WP, SDA, SCL, RESET);

   input                A0;                             // chip select bit
   input                A1;                             // chip select bit
   input                A2;                             // chip select bit

   input                WP;                             // write protect pin

   inout                SDA;                            // serial data I/O
   input                SCL;                            // serial data clock

   input                RESET;                          // system reset

   parameter  MEMInitFile = "";
// *******************************************************************************************************
// **   DECLARATIONS                                                                                    **
// *******************************************************************************************************

   parameter            SERIAL_NUM_0 = 8'hFF;           // default value
   parameter            SERIAL_NUM_1 = 8'hFF;           // default value
   parameter            SERIAL_NUM_2 = 8'hFF;           // default value
   parameter            SERIAL_NUM_3 = 8'hFF;           // default value
   parameter            SERIAL_NUM_4 = 8'hFF;           // default value
   parameter            SERIAL_NUM_5 = 8'hFF;           // default value
   parameter            SERIAL_NUM_6 = 8'hFF;           // default value
   parameter            SERIAL_NUM_7 = 8'hFF;           // default value
   parameter            SERIAL_NUM_8 = 8'hFF;           // default value
   parameter            SERIAL_NUM_9 = 8'hFF;           // default value
   parameter            SERIAL_NUM_A = 8'hFF;           // default value
   parameter            SERIAL_NUM_B = 8'hFF;           // default value
   parameter            SERIAL_NUM_C = 8'hFF;           // default value
   parameter            SERIAL_NUM_D = 8'hFF;           // default value
   parameter            SERIAL_NUM_E = 8'hFF;           // default value
   parameter            SERIAL_NUM_F = 8'hFF;           // default value

   parameter            CONFIG_REG_DEFAULTS = 16'h0000; // default value
   
   parameter            MAN_ID = 24'b0000_0000_1101_0000_1100_1_000; // manufacturer ID value

`define CTRL_BYTE_EEPROM    {4'b1010,ChipAddress}       // control byte for EEPROM access
`define CTRL_BYTE_SECCFGREG {4'b1011,ChipAddress}       // control byte for Security/Config register access
`define CTRL_BYTE_MANID     7'b1111100                  // control byte for Manufacturer ID
`define CTRL_BYTE_HSMODE    7'b00001??                  // control byte for HS mode

// .......................................................................................................

   reg                  SDA_DO;                         // serial data - output
   reg                  SDA_OE;                         // serial data - output enable

   wire                 SDA_DriveEnable;                // serial data output enable
   reg                  SDA_DriveEnableDlyd;            // serial data output enable - delayed

   wire [02:00]         ChipAddress;                    // hardwired chip address

   reg  [03:00]         BitCounter;                     // serial bit counter
   reg  [31:00]         ByteCounter;                    // byte counter

   reg                  START_Rcvd;                     // START bit received flag
   reg                  STOP_Rcvd;                      // STOP bit received flag
   reg                  CTRL_Rcvd;                      // control byte received flag
   reg                  ADHI_Rcvd;                      // byte address hi received flag
   reg                  ADLO_Rcvd;                      // byte address lo received flag
   reg                  ACK_Rcvd;                       // acknowledge received flag

   reg                  SECCFG_Access;                  // Security/config reg access operation
   reg                  MANID_Access;                   // Manufacturer ID access operation
   reg                  EEPROM_Access;                  // EEPROM access operation

   reg                  Valid_MANID_Dummy;              // valid man ID dummy write received
   reg                  Valid_SECCFG_Dummy;             // valid sec/cfg reg dummy write received

   reg                  WrOperation;                    // memory write cycle
   reg                  RdOperation;                    // memory read cycle

   reg  [07:00]         ShiftRegister;                  // input data shift register

   reg  [07:00]         ControlByte;                    // control byte register
   wire                 CTRL_Valid;                     // control byte valid
   
   reg                  I2C_FirstRead;                  // I2C first data read flag

   reg  [15:00]         AddressPointer;                 // memory access address pointer
   reg  [07:00]         PageBuffer [0:127];             // memory write data buffer
   reg                  BufferWrFlags [0:127];          // memory buffer write flags
   
   reg  [23:00]         CfgRegBuffer;                   // config reg buffer
   
   wire                 AddressValid;                   // valid address
   wire                 EEPROM_Protected;               // EEPROM write protect flag

   wire [07:00]         RdDataByte;                     // memory read data
   
   event                EEPROM_WrEvent;                 // EEPROM write event
   event                SECREG_WrEvent;                 // Security register write event
   event                CFGREG_WrEvent;                 // Config register write event
   event                SECREG_LockEvent;               // Security register lock event
   
   wire [07:00]         EEPROM_RdData;                  // EEPROM memory read data multiplexer
   reg [07:00]          SECCFG_RdData;                  // sec/cfg reg read data multiplexer
   wire [07:00]         MANID_RdData;                   // manufacturer ID read data multiplexer
   
   wire [07:00]         SECCFG_SecData;                 // security register read data
   wire [07:00]         SECCFG_CfgData;                 // config register read data

   reg                  WriteActive;                    // memory write cycle active
   reg                  HSModeEnabled;                  // high-speed mode enabled
   reg                  SecRegLock;                     // Security register lock bit

   reg  [07:00]         MemoryBlock [0:65535];          // EEPROM data memory array

   reg  [07:00]         SecurityReg [0:255];            // Security reg memory array
   reg  [23:00]         ManIDBuffer;                    // manufacturer ID cyclical buffer
   
   wire                 CFGREG_ECS;                     // error correction status bit, read-only
   reg                  CFGREG_EWPM;                    // enhanced write protect mode bit
   reg                  CFGREG_LOCK;                    // config reg lock bit
   reg [07:00]          CFGREG_SWP;                     // software write protect bits
   
   integer              LoopIndex;                      // iterative loop index

   integer              tAA;                            // timing parameter
   integer              tWC;                            // timing parameter


// *******************************************************************************************************
// **   INITIALIZATION                                                                                  **
// *******************************************************************************************************

   initial begin
`ifdef XILINX_SIMULATOR
      // Code specificaly to only be used by Vivado's simulator (XSim)
      // Using a portable 'for' loop that Vivado understands.
      integer i;
      for (i = 0; i < $size(MemoryBlock); i = i + 1) begin
         MemoryBlock[i] <= 0;
      end
`else
      // This code will be used by all other simulators (like Cadence Xrun)
      MemoryBlock <= '{default: '0};
`endif
      #1; $readmemh(MEMInitFile, MemoryBlock);
   end

   initial begin
      tAA = 400;                                        // SCL to SDA output delay
      tWC = 5000000;                                    // memory write cycle time
   end

   initial begin
      SDA_DO = 0;
      SDA_OE = 0;
   end

   initial begin
      START_Rcvd = 0;
      STOP_Rcvd  = 0;
      CTRL_Rcvd  = 0;
      ADHI_Rcvd  = 0;
      ADLO_Rcvd  = 0;
      ACK_Rcvd  = 0;
   end

   initial begin
      BitCounter  = 0;
      ByteCounter = 0;
      ControlByte = 0;
      AddressPointer = 0;
   end

   initial begin
      WrOperation = 0;
      RdOperation = 0;

      WriteActive = 0;
      
      EEPROM_Access = 0;
      SECCFG_Access = 0;
      MANID_Access = 0;
      
      Valid_MANID_Dummy = 0;
      Valid_SECCFG_Dummy = 0;
      
      HSModeEnabled = 0;
   end
   
   initial begin
      SecurityReg[0] = SERIAL_NUM_0;
      SecurityReg[1] = SERIAL_NUM_1;
      SecurityReg[2] = SERIAL_NUM_2;
      SecurityReg[3] = SERIAL_NUM_3;
      SecurityReg[4] = SERIAL_NUM_4;
      SecurityReg[5] = SERIAL_NUM_5;
      SecurityReg[6] = SERIAL_NUM_6;
      SecurityReg[7] = SERIAL_NUM_7;
      SecurityReg[8] = SERIAL_NUM_8;
      SecurityReg[9] = SERIAL_NUM_9;
      SecurityReg[10] = SERIAL_NUM_A;
      SecurityReg[11] = SERIAL_NUM_B;
      SecurityReg[12] = SERIAL_NUM_C;
      SecurityReg[13] = SERIAL_NUM_D;
      SecurityReg[14] = SERIAL_NUM_E;
      SecurityReg[15] = SERIAL_NUM_F;
      
      SecRegLock = 0;
      
      {CFGREG_EWPM,CFGREG_LOCK,CFGREG_SWP} = CONFIG_REG_DEFAULTS[9:0];
   end

   assign ChipAddress = {A2,A1,A0};
   assign CFGREG_ECS = 0;               // ECC not modeled, ECS bit always remains 0

// *******************************************************************************************************
// **   I/O LOGIC - I2C                                                                                 **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      1.01:  START Bit Detection
// -------------------------------------------------------------------------------------------------------

   always @(negedge SDA) begin
      if (SCL == 1) begin
         START_Rcvd <= 1;
         STOP_Rcvd  <= 0;
         CTRL_Rcvd  <= 0;
         ADHI_Rcvd  <= 0;
         ADLO_Rcvd  <= 0;
         ACK_Rcvd   <= 0;
         I2C_FirstRead <= 1;
         BitCounter <= 0;
         ByteCounter <= 0;

         WrOperation <= #1 0;
         RdOperation <= #1 0;
         
         EEPROM_Access <= #1 0;
         SECCFG_Access <= #1 0;
         MANID_Access <= #1 0;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.02:  STOP Bit Detection
// -------------------------------------------------------------------------------------------------------

   always @(posedge SDA) begin
      if (SCL == 1) begin
         START_Rcvd <= 0;
         STOP_Rcvd  <= 1;
         CTRL_Rcvd  <= 0;
         ADHI_Rcvd  <= 0;
         ADLO_Rcvd  <= 0;
         ACK_Rcvd  <= 0;
         I2C_FirstRead <= 0;
         BitCounter <= #1 10;

         WrOperation <= #1 0;
         RdOperation <= #1 0;
         
         ByteCounter <= #1 0;

         EEPROM_Access <= #1 0;
         SECCFG_Access <= #1 0;
         MANID_Access <= #1 0;

         Valid_MANID_Dummy <= 0;
         Valid_SECCFG_Dummy <= 0;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.03:  Input Shift Register
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      ShiftRegister <= {ShiftRegister[6:0], SDA};
   end

// -------------------------------------------------------------------------------------------------------
//      1.04:  Input Bit Counter
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      BitCounter <= BitCounter + 1;
      if (BitCounter == 8) begin        // Increment byte counter when bit count is transitioning to 9
         ByteCounter <= ByteCounter + 32'd1;
      end
   end
   
   always @(negedge SCL) begin
      if (BitCounter == 9) begin
         BitCounter <= 0;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.05:  Control Byte Register
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if (START_Rcvd & (BitCounter == 7)) begin
         START_Rcvd <= 0;

         if (!WriteActive) begin
            if (SDA == 0) begin
               WrOperation <= 1;
               for (LoopIndex = 0; LoopIndex < 128; LoopIndex = LoopIndex + 1) begin
                  BufferWrFlags[LoopIndex] <= 0;
               end
            end
            else begin
               RdOperation <= 1;
            end
            
            ControlByte <= {ShiftRegister[6:0],SDA};
            
            // Clear SEC/CFG valid dummy write flag for any control byte except the Sec/Cfg reg control byte
            if (ShiftRegister[6:0] != `CTRL_BYTE_SECCFGREG) Valid_SECCFG_Dummy <= 0;
            
            // Clear Man ID valid dummy write flag for any control byte except the man ID control byte
            if (ShiftRegister[6:0] != `CTRL_BYTE_MANID) Valid_MANID_Dummy <= 0;
            
            casez (ShiftRegister[6:0])
               `CTRL_BYTE_EEPROM :
                  begin
                     CTRL_Rcvd <= 1;
                     EEPROM_Access <= 1;
                  end
               `CTRL_BYTE_SECCFGREG :
                  begin
                     // For sec/cfg reg reads, do not proceed unless a valid sec/cfg dummy write occurred first
                     if ((SDA && Valid_SECCFG_Dummy) || !SDA) begin
                        CTRL_Rcvd <= 1;
                        SECCFG_Access <= 1;
                     end
                  end
               `CTRL_BYTE_MANID :
                  begin
                     // For man ID reads, do not proceed unless a valid man ID dummy write occurred first
                     if ((SDA && Valid_MANID_Dummy) || !SDA) begin
                        CTRL_Rcvd <= 1;
                        MANID_Access <= 1;
                     end
                  end
               `CTRL_BYTE_HSMODE :
                  begin
                     HSModeEnabled <= 1;
                  end
               default :
                  begin
                     WrOperation <= 0;
                     RdOperation <= 0;
                  end
            endcase
         end
      end
   end
   
   assign CTRL_Valid = CTRL_Rcvd && !WriteActive && ((ControlByte[7:1]==`CTRL_BYTE_EEPROM) ||
                                                     (ControlByte[7:1]==`CTRL_BYTE_SECCFGREG) ||
                                                     (ControlByte[7:1]==`CTRL_BYTE_MANID));

// -------------------------------------------------------------------------------------------------------
//      1.06:  Word Address Register
// -------------------------------------------------------------------------------------------------------

   // Handle most significant address byte
   always @(posedge SCL) begin
      if (CTRL_Valid && WrOperation && (BitCounter == 7)) begin
         CTRL_Rcvd <= 0;

         if (EEPROM_Access) begin
            AddressPointer[15:08] <= {ShiftRegister[6:0],SDA};
            ADHI_Rcvd <= 1;
         end
         else if (SECCFG_Access) begin
            // For cfg reg, only ACK xxxxx10x upper address byte,
            //   and for sec reg, only ACK xxxx0110 upper address byte and only if not already locked
            if (ShiftRegister[2:1] == 2'b10 ||
                ({ShiftRegister[2:0],SDA} == 4'b0110 && !SecRegLock)) begin
               AddressPointer[15:08] <= {ShiftRegister[6:0],SDA};
               ADHI_Rcvd <= 1;
            end
            else begin
               ADHI_Rcvd <= 0;
               ADLO_Rcvd <= 0;
               ACK_Rcvd <= 0;
               I2C_FirstRead <= 0;
               BitCounter <= 10;

               WrOperation <= #1 0;
               RdOperation <= #1 0;
               
               ByteCounter <= #1 0;

               EEPROM_Access <= #1 0;
               SECCFG_Access <= #1 0;
               MANID_Access <= #1 0;
               
               Valid_MANID_Dummy <= 0;
               Valid_SECCFG_Dummy <= 0;
            end
         end
         else if (MANID_Access) begin
            if (ShiftRegister[6:0] == `CTRL_BYTE_EEPROM) begin
               Valid_MANID_Dummy <= 1;
               ManIDBuffer = MAN_ID;
               ADHI_Rcvd <= 1;
            end
            else begin
               ADHI_Rcvd <= 0;
               ADLO_Rcvd <= 0;
               ACK_Rcvd <= 0;
               I2C_FirstRead <= 0;
               BitCounter <= 10;

               WrOperation <= #1 0;
               RdOperation <= #1 0;
               
               ByteCounter <= #1 0;

               EEPROM_Access <= #1 0;
               SECCFG_Access <= #1 0;
               MANID_Access <= #1 0;
               
               Valid_MANID_Dummy <= 0;
               Valid_SECCFG_Dummy <= 0;
            end
         end
      end
   end

   // Handle least significant address byte
   always @(posedge SCL) begin
      if (ADHI_Rcvd && WrOperation && (BitCounter == 7)) begin
         ADHI_Rcvd <= 0;

         AddressPointer[07:00] <= {ShiftRegister[6:0],SDA};
         ADLO_Rcvd <= 1;
         
         if (SECCFG_Access) begin
            Valid_SECCFG_Dummy <= 1;
         end
         else if (MANID_Access) begin
            // Getting this far in the protocol will abort a man ID read
            ADHI_Rcvd <= 0;
            ADLO_Rcvd <= 0;
            ACK_Rcvd <= 0;
            I2C_FirstRead <= 0;
            BitCounter <= 10;

            WrOperation <= #1 0;
            RdOperation <= #1 0;
              
            ByteCounter <= #1 0;

            EEPROM_Access <= #1 0;
            SECCFG_Access <= #1 0;
            MANID_Access <= #1 0;
               
            Valid_MANID_Dummy <= 0;
            Valid_SECCFG_Dummy <= 0;
         end
      end
   end
   
   assign AddressValid = EEPROM_Access ||
                         (SECCFG_Access && (AddressPointer[11:10] == 2'b10 || AddressPointer[11:8] == 4'b0110)) ||
                         MANID_Access;

// -------------------------------------------------------------------------------------------------------
//      1.07:  Write Data Buffer
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if (ADLO_Rcvd && (BitCounter == 7) && AddressValid && WrOperation) begin
         if (EEPROM_Access) begin
            PageBuffer[AddressPointer[6:0]] <= {ShiftRegister[6:0],SDA};
            BufferWrFlags[AddressPointer[6:0]] <= 1;
            
            AddressPointer[6:0] <= AddressPointer[6:0] + 7'd1;
         end
         if (SECCFG_Access) begin
            // Clear valid Sec/Cfg reg dummy write flag if any data bytes are received
            Valid_SECCFG_Dummy <= 0;
            
            if (AddressPointer[15] == 1'b0) begin
               PageBuffer[AddressPointer[6:0]] <= {ShiftRegister[6:0],SDA};
               BufferWrFlags[AddressPointer[6:0]] <= 1;
            
               AddressPointer[6:0] <= AddressPointer[6:0] + 7'd1;
            end
            else begin
               if (ByteCounter <= 32'd5) begin
                  CfgRegBuffer <= {CfgRegBuffer[15:0],ShiftRegister[6:0],SDA};
               end
               else begin
                  // Config reg write aborted if extra bytes are sent
                  CTRL_Rcvd <= 0;
                  ADHI_Rcvd <= 0;
                  ADLO_Rcvd <= 0;
                  ACK_Rcvd <= 0;
                  I2C_FirstRead <= 0;
                  BitCounter <= 10;

                  WrOperation <= #1 0;
                  RdOperation <= #1 0;
                   
                  ByteCounter <= #1 0;

                  EEPROM_Access <= #1 0;
                  SECCFG_Access <= #1 0;
                  MANID_Access <= #1 0;
               end
            end
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.08:  Write Acknowledge Generator
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if ((CTRL_Valid || ADHI_Rcvd || ADLO_Rcvd) && WrOperation) begin
         if (BitCounter == 8) begin
            SDA_DO <= 0;
            SDA_OE <= 1;
         end
         if (BitCounter == 9) begin
            SDA_DO <= 0;
            SDA_OE <= 0;
         end
      end
   end 

// -------------------------------------------------------------------------------------------------------
//      1.09:  Acknowledge Detect
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if (RdOperation && (BitCounter == 8)) begin
         if (SDA_OE == 0) begin
            if (SDA == 0) ACK_Rcvd <= 1;
            else begin
               CTRL_Rcvd <= 0;
               ADHI_Rcvd <= 0;
               ADLO_Rcvd <= 0;
               ACK_Rcvd <= 0;
               I2C_FirstRead <= 0;
               BitCounter <= 10;

               WrOperation <= #1 0;
               RdOperation <= #1 0;
               
               ByteCounter <= #1 0;

               EEPROM_Access <= #1 0;
               SECCFG_Access <= #1 0;
               MANID_Access <= #1 0;
               
               Valid_MANID_Dummy <= 0;
               Valid_SECCFG_Dummy <= 0;
            end
         end
      end
   end

   always @(negedge SCL) ACK_Rcvd <= 0;

// -------------------------------------------------------------------------------------------------------
//      1.10:  STOP Flag Removal 
// -------------------------------------------------------------------------------------------------------

   always @(posedge STOP_Rcvd) begin
      #(1);
      STOP_Rcvd = 0;
   end

// -------------------------------------------------------------------------------------------------------
//      1.11:  Read Data Processor
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if (RdOperation && CTRL_Valid && AddressValid) begin
         if (I2C_FirstRead) begin
            if (BitCounter == 8) begin
               SDA_DO <= 0;
               SDA_OE <= 1;
            end
            if (BitCounter == 9) begin
               SDA_DO <= RdDataByte[7];
               SDA_OE <= 1;
               I2C_FirstRead <= 0;
            end
         end
         else begin
            if (BitCounter == 8) begin
               SDA_DO <= 0;
               SDA_OE <= 0;
            end
            else if (BitCounter == 9) begin
               SDA_DO <= RdDataByte[7];
               SDA_OE <= ACK_Rcvd;
            end
            else begin
               SDA_DO <= RdDataByte[7-BitCounter];
            end
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      1.12:  Read Address Increment
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if (BitCounter == 8 && RdOperation && !I2C_FirstRead) begin
         if (EEPROM_Access) AddressPointer <= AddressPointer + 16'd1;
         else if (SECCFG_Access && AddressPointer[15] == 0)
            AddressPointer[07:00] <= AddressPointer[07:00] + 8'd1;
         else if (MANID_Access) begin
            ManIDBuffer = {ManIDBuffer[15:0],ManIDBuffer[23:16]};
         end
      end
   end

   assign RdDataByte = EEPROM_Access ? EEPROM_RdData : (SECCFG_Access ? SECCFG_RdData : (MANID_Access ? MANID_RdData : 8'bx));

// -------------------------------------------------------------------------------------------------------
//      1.13:  SDA Data I/O Buffer
// -------------------------------------------------------------------------------------------------------

   bufif1 (SDA, 1'b0, SDA_DriveEnableDlyd);

   assign SDA_DriveEnable = !SDA_DO & SDA_OE;
   initial SDA_DriveEnableDlyd <= 0;
   always @(SDA_DriveEnable) SDA_DriveEnableDlyd <= #(tAA) SDA_DriveEnable;

// -------------------------------------------------------------------------------------------------------
//      1.14:  High Speed Mode
// -------------------------------------------------------------------------------------------------------

   always @(HSModeEnabled) begin
      if (HSModeEnabled) tAA <= 70;
      else tAA <= 400;
   end

   always @(posedge STOP_Rcvd) begin
      HSModeEnabled <= 0;
   end

// -------------------------------------------------------------------------------------------------------
//      1.15:  Manufacturer ID Read Logic
// -------------------------------------------------------------------------------------------------------

   assign MANID_RdData = ManIDBuffer[23:16];

// *******************************************************************************************************
// **   CORE LOGIC - EEPROM                                                                             **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      2.01:  EEPROM Write Operation Logic
// -------------------------------------------------------------------------------------------------------

   always @(posedge STOP_Rcvd) begin
      if (EEPROM_Access && WrOperation && (BitCounter == 1) && (ByteCounter >= 4) && !EEPROM_Protected) begin
            ->EEPROM_WrEvent;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      2.02:  EEPROM Memory Write Cycle
// -------------------------------------------------------------------------------------------------------

   always @(EEPROM_WrEvent) begin
      WriteActive = 1;
      #(tWC);
      WriteActive = 0;
      for (LoopIndex = 0; LoopIndex < 128; LoopIndex = LoopIndex + 1) begin
         if (BufferWrFlags[LoopIndex]) begin
            MemoryBlock[{AddressPointer[15:7],LoopIndex[6:0]}] = PageBuffer[LoopIndex];
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      2.03:  EEPROM Memory Read Logic
// -------------------------------------------------------------------------------------------------------

   assign EEPROM_RdData = MemoryBlock[AddressPointer[15:0]];
   
// -------------------------------------------------------------------------------------------------------
//      2.04:  EEPROM Write Protection Logic
// -------------------------------------------------------------------------------------------------------

    // For enhanced WP, the three address pointer MSb's map back to the relevant SWP bit
    assign EEPROM_Protected = CFGREG_EWPM ? CFGREG_SWP[AddressPointer[15:13]] : WP;

// *******************************************************************************************************
// **   CORE LOGIC - SECURITY/CONFIG REGISTER                                                           **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      3.01:  Security/Config Reg Write Operation Logic
// -------------------------------------------------------------------------------------------------------

   always @(posedge STOP_Rcvd) begin
      if (SECCFG_Access && WrOperation && (BitCounter == 1) && (ByteCounter >= 4)) begin
         casez (AddressPointer)
            16'b0???_10??_1???_????: begin
               if (!SecRegLock && !WP && ByteCounter >= 4)
                  ->SECREG_WrEvent;
            end
            16'b????_0110_????_????: begin
               // WP intentionally not checked here as it does not affect the sec reg lock operation
               if (!SecRegLock && ByteCounter >= 4)
                  ->SECREG_LockEvent;
            end
            16'b1???_10??_????_????: begin
               if (!CFGREG_LOCK && ByteCounter == 6) begin
                  if ((CfgRegBuffer[16] == 0 && CfgRegBuffer[7:0] == 8'h66) ||
                      (CfgRegBuffer[16] == 1 && CfgRegBuffer[7:0] == 8'h99))
                     ->CFGREG_WrEvent;
               end
            end
         endcase
      end
   end

// -------------------------------------------------------------------------------------------------------
//      3.02:  Security/Config Reg Write Cycle
// -------------------------------------------------------------------------------------------------------

   always @(SECREG_WrEvent) begin
      WriteActive = 1;
      #(tWC);
      WriteActive = 0;
      for (LoopIndex = 0; LoopIndex < 128; LoopIndex = LoopIndex + 1) begin
         if (BufferWrFlags[LoopIndex]) begin
            SecurityReg[{1'b1,LoopIndex[6:0]}] = PageBuffer[LoopIndex];
         end
      end
   end
   
   always @(SECREG_LockEvent) begin
      WriteActive = 1;
      #(tWC);
      WriteActive = 0;
      SecRegLock = 1;
   end
   
   always @(CFGREG_WrEvent) begin
      WriteActive = 1;
      #(tWC);
      WriteActive = 0;
      {CFGREG_EWPM,CFGREG_LOCK,CFGREG_SWP} = CfgRegBuffer[17:8];
   end

// -------------------------------------------------------------------------------------------------------
//      3.03:  Security/Config Reg Read Logic
// -------------------------------------------------------------------------------------------------------

   always @(AddressPointer or SECCFG_SecData or SECCFG_CfgData) begin
      SECCFG_RdData = 8'bx;     // Default to unknown value
      casez (AddressPointer[15:8])
         8'b0???_10??: SECCFG_RdData = SECCFG_SecData;
         8'b1???_10??: SECCFG_RdData = SECCFG_CfgData;
      endcase
   end

   assign SECCFG_SecData = SecurityReg[AddressPointer[7:0]];
   assign SECCFG_CfgData = ByteCounter[0] ? {CFGREG_ECS,5'b00000,CFGREG_EWPM,CFGREG_LOCK} : 
                                            CFGREG_SWP;  // ByteCounter is at 1 when reading first data byte

// *******************************************************************************************************
// **   DEBUG LOGIC                                                                                     **
// *******************************************************************************************************
// -------------------------------------------------------------------------------------------------------
//      4.01:  Memory Data Bytes
// -------------------------------------------------------------------------------------------------------

   wire [07:00] MemoryByte_000 = MemoryBlock[00];
   wire [07:00] MemoryByte_001 = MemoryBlock[01];
   wire [07:00] MemoryByte_002 = MemoryBlock[02];
   wire [07:00] MemoryByte_003 = MemoryBlock[03];
   wire [07:00] MemoryByte_004 = MemoryBlock[04];
   wire [07:00] MemoryByte_005 = MemoryBlock[05];
   wire [07:00] MemoryByte_006 = MemoryBlock[06];
   wire [07:00] MemoryByte_007 = MemoryBlock[07];
   wire [07:00] MemoryByte_008 = MemoryBlock[08];
   wire [07:00] MemoryByte_009 = MemoryBlock[09];
   wire [07:00] MemoryByte_00A = MemoryBlock[10];
   wire [07:00] MemoryByte_00B = MemoryBlock[11];
   wire [07:00] MemoryByte_00C = MemoryBlock[12];
   wire [07:00] MemoryByte_00D = MemoryBlock[13];
   wire [07:00] MemoryByte_00E = MemoryBlock[14];
   wire [07:00] MemoryByte_00F = MemoryBlock[15];

// -------------------------------------------------------------------------------------------------------
//      4.02:  Page Write Buffer
// -------------------------------------------------------------------------------------------------------

   wire [07:00] PageBuffer_00 = PageBuffer[00];
   wire [07:00] PageBuffer_01 = PageBuffer[01];
   wire [07:00] PageBuffer_02 = PageBuffer[02];
   wire [07:00] PageBuffer_03 = PageBuffer[03];
   wire [07:00] PageBuffer_04 = PageBuffer[04];
   wire [07:00] PageBuffer_05 = PageBuffer[05];
   wire [07:00] PageBuffer_06 = PageBuffer[06];
   wire [07:00] PageBuffer_07 = PageBuffer[07];
   wire [07:00] PageBuffer_08 = PageBuffer[08];
   wire [07:00] PageBuffer_09 = PageBuffer[09];
   wire [07:00] PageBuffer_0A = PageBuffer[10];
   wire [07:00] PageBuffer_0B = PageBuffer[11];
   wire [07:00] PageBuffer_0C = PageBuffer[12];
   wire [07:00] PageBuffer_0D = PageBuffer[13];
   wire [07:00] PageBuffer_0E = PageBuffer[14];
   wire [07:00] PageBuffer_0F = PageBuffer[15];

   wire [07:00] PageBuffer_10 = PageBuffer[16];
   wire [07:00] PageBuffer_11 = PageBuffer[17];
   wire [07:00] PageBuffer_12 = PageBuffer[18];
   wire [07:00] PageBuffer_13 = PageBuffer[19];
   wire [07:00] PageBuffer_14 = PageBuffer[20];
   wire [07:00] PageBuffer_15 = PageBuffer[21];
   wire [07:00] PageBuffer_16 = PageBuffer[22];
   wire [07:00] PageBuffer_17 = PageBuffer[23];
   wire [07:00] PageBuffer_18 = PageBuffer[24];
   wire [07:00] PageBuffer_19 = PageBuffer[25];
   wire [07:00] PageBuffer_1A = PageBuffer[26];
   wire [07:00] PageBuffer_1B = PageBuffer[27];
   wire [07:00] PageBuffer_1C = PageBuffer[28];
   wire [07:00] PageBuffer_1D = PageBuffer[29];
   wire [07:00] PageBuffer_1E = PageBuffer[30];
   wire [07:00] PageBuffer_1F = PageBuffer[31];

   wire [07:00] PageBuffer_20 = PageBuffer[32];
   wire [07:00] PageBuffer_21 = PageBuffer[33];
   wire [07:00] PageBuffer_22 = PageBuffer[34];
   wire [07:00] PageBuffer_23 = PageBuffer[35];
   wire [07:00] PageBuffer_24 = PageBuffer[36];
   wire [07:00] PageBuffer_25 = PageBuffer[37];
   wire [07:00] PageBuffer_26 = PageBuffer[38];
   wire [07:00] PageBuffer_27 = PageBuffer[39];
   wire [07:00] PageBuffer_28 = PageBuffer[40];
   wire [07:00] PageBuffer_29 = PageBuffer[41];
   wire [07:00] PageBuffer_2A = PageBuffer[42];
   wire [07:00] PageBuffer_2B = PageBuffer[43];
   wire [07:00] PageBuffer_2C = PageBuffer[44];
   wire [07:00] PageBuffer_2D = PageBuffer[45];
   wire [07:00] PageBuffer_2E = PageBuffer[46];
   wire [07:00] PageBuffer_2F = PageBuffer[47];

   wire [07:00] PageBuffer_30 = PageBuffer[48];
   wire [07:00] PageBuffer_31 = PageBuffer[49];
   wire [07:00] PageBuffer_32 = PageBuffer[50];
   wire [07:00] PageBuffer_33 = PageBuffer[51];
   wire [07:00] PageBuffer_34 = PageBuffer[52];
   wire [07:00] PageBuffer_35 = PageBuffer[53];
   wire [07:00] PageBuffer_36 = PageBuffer[54];
   wire [07:00] PageBuffer_37 = PageBuffer[55];
   wire [07:00] PageBuffer_38 = PageBuffer[56];
   wire [07:00] PageBuffer_39 = PageBuffer[57];
   wire [07:00] PageBuffer_3A = PageBuffer[58];
   wire [07:00] PageBuffer_3B = PageBuffer[59];
   wire [07:00] PageBuffer_3C = PageBuffer[60];
   wire [07:00] PageBuffer_3D = PageBuffer[61];
   wire [07:00] PageBuffer_3E = PageBuffer[62];
   wire [07:00] PageBuffer_3F = PageBuffer[63];

   wire [07:00] PageBuffer_40 = PageBuffer[64];
   wire [07:00] PageBuffer_41 = PageBuffer[65];
   wire [07:00] PageBuffer_42 = PageBuffer[66];
   wire [07:00] PageBuffer_43 = PageBuffer[67];
   wire [07:00] PageBuffer_44 = PageBuffer[68];
   wire [07:00] PageBuffer_45 = PageBuffer[69];
   wire [07:00] PageBuffer_46 = PageBuffer[70];
   wire [07:00] PageBuffer_47 = PageBuffer[71];
   wire [07:00] PageBuffer_48 = PageBuffer[72];
   wire [07:00] PageBuffer_49 = PageBuffer[73];
   wire [07:00] PageBuffer_4A = PageBuffer[74];
   wire [07:00] PageBuffer_4B = PageBuffer[75];
   wire [07:00] PageBuffer_4C = PageBuffer[76];
   wire [07:00] PageBuffer_4D = PageBuffer[77];
   wire [07:00] PageBuffer_4E = PageBuffer[78];
   wire [07:00] PageBuffer_4F = PageBuffer[79];

   wire [07:00] PageBuffer_50 = PageBuffer[80];
   wire [07:00] PageBuffer_51 = PageBuffer[81];
   wire [07:00] PageBuffer_52 = PageBuffer[82];
   wire [07:00] PageBuffer_53 = PageBuffer[83];
   wire [07:00] PageBuffer_54 = PageBuffer[84];
   wire [07:00] PageBuffer_55 = PageBuffer[85];
   wire [07:00] PageBuffer_56 = PageBuffer[86];
   wire [07:00] PageBuffer_57 = PageBuffer[87];
   wire [07:00] PageBuffer_58 = PageBuffer[88];
   wire [07:00] PageBuffer_59 = PageBuffer[89];
   wire [07:00] PageBuffer_5A = PageBuffer[90];
   wire [07:00] PageBuffer_5B = PageBuffer[91];
   wire [07:00] PageBuffer_5C = PageBuffer[92];
   wire [07:00] PageBuffer_5D = PageBuffer[93];
   wire [07:00] PageBuffer_5E = PageBuffer[94];
   wire [07:00] PageBuffer_5F = PageBuffer[95];

   wire [07:00] PageBuffer_60 = PageBuffer[96];
   wire [07:00] PageBuffer_61 = PageBuffer[97];
   wire [07:00] PageBuffer_62 = PageBuffer[98];
   wire [07:00] PageBuffer_63 = PageBuffer[99];
   wire [07:00] PageBuffer_64 = PageBuffer[100];
   wire [07:00] PageBuffer_65 = PageBuffer[101];
   wire [07:00] PageBuffer_66 = PageBuffer[102];
   wire [07:00] PageBuffer_67 = PageBuffer[103];
   wire [07:00] PageBuffer_68 = PageBuffer[104];
   wire [07:00] PageBuffer_69 = PageBuffer[105];
   wire [07:00] PageBuffer_6A = PageBuffer[106];
   wire [07:00] PageBuffer_6B = PageBuffer[107];
   wire [07:00] PageBuffer_6C = PageBuffer[108];
   wire [07:00] PageBuffer_6D = PageBuffer[109];
   wire [07:00] PageBuffer_6E = PageBuffer[110];
   wire [07:00] PageBuffer_6F = PageBuffer[111];

   wire [07:00] PageBuffer_70 = PageBuffer[112];
   wire [07:00] PageBuffer_71 = PageBuffer[113];
   wire [07:00] PageBuffer_72 = PageBuffer[114];
   wire [07:00] PageBuffer_73 = PageBuffer[115];
   wire [07:00] PageBuffer_74 = PageBuffer[116];
   wire [07:00] PageBuffer_75 = PageBuffer[117];
   wire [07:00] PageBuffer_76 = PageBuffer[118];
   wire [07:00] PageBuffer_77 = PageBuffer[119];
   wire [07:00] PageBuffer_78 = PageBuffer[120];
   wire [07:00] PageBuffer_79 = PageBuffer[121];
   wire [07:00] PageBuffer_7A = PageBuffer[122];
   wire [07:00] PageBuffer_7B = PageBuffer[123];
   wire [07:00] PageBuffer_7C = PageBuffer[124];
   wire [07:00] PageBuffer_7D = PageBuffer[125];
   wire [07:00] PageBuffer_7E = PageBuffer[126];
   wire [07:00] PageBuffer_7F = PageBuffer[127];


// *******************************************************************************************************
// **   TIMING CHECKS                                                                                   **
// *******************************************************************************************************

   wire TimingCheckEnable = (RESET == 0) & (SDA_OE == 0);
   wire NonHSTimingCheckEnable = TimingCheckEnable & (HSModeEnabled == 0);
   wire HSTimingCheckEnable = TimingCheckEnable & (HSModeEnabled == 1);
   wire tstSTOP = STOP_Rcvd;

   specify
      // High-speed mode timing definitions
      specparam
         tHS_HI = 60,                           // SCL pulse width - high
         tHS_LO = 160,                          // SCL pulse width - low
         tHS_SU_STA = 160,                      // SCL to SDA setup time
         tHS_HD_STA = 160,                      // SCL to SDA hold time
         tHS_SU_DAT = 10,                       // SDA to SCL setup time
         tHS_SU_STO = 160;                      // SCL to SDA setup time

      // Non high-speed mode timing definitions
      specparam
         tHI = 400,                             // SCL pulse width - high
         tLO = 400,                             // SCL pulse width - low
         tSU_STA = 250,                         // SCL to SDA setup time
         tHD_STA = 250,                         // SCL to SDA hold time
         tSU_DAT = 50,                          // SDA to SCL setup time
         tSU_STO = 250;                         // SCL to SDA setup time
         
      // Generic timing definitions
      specparam
         tBUF = 500,                            // Bus free time
         tSU_WP = 600,                          // WP to SDA setup time
         tHD_WP = 1300;                         // WP to SDA hold time

      // High-speed mode timing checks
      $width (posedge SCL &&& HSTimingCheckEnable, tHS_HI);
      $width (negedge SCL &&& HSTimingCheckEnable, tHS_LO);

      $setup (posedge SCL, negedge SDA &&& HSTimingCheckEnable, tHS_SU_STA);
      $setup (SDA, posedge SCL &&& HSTimingCheckEnable, tHS_SU_DAT);
      $setup (posedge SCL, posedge SDA &&& HSTimingCheckEnable, tHS_SU_STO);

      $hold  (negedge SDA &&& HSTimingCheckEnable, negedge SCL, tHS_HD_STA);
      
      // Non high-speed mode timing checks
      $width (posedge SCL &&& NonHSTimingCheckEnable, tHI);
      $width (negedge SCL &&& NonHSTimingCheckEnable, tLO);

      $setup (posedge SCL, negedge SDA &&& NonHSTimingCheckEnable, tSU_STA);
      $setup (SDA, posedge SCL &&& NonHSTimingCheckEnable, tSU_DAT);
      $setup (posedge SCL, posedge SDA &&& NonHSTimingCheckEnable, tSU_STO);

      $hold  (negedge SDA &&& NonHSTimingCheckEnable, negedge SCL, tHD_STA);
      
      // Generic timing checks
      $width (posedge SDA &&& SCL, tBUF);

      $setup (WP, posedge tstSTOP &&& TimingCheckEnable, tSU_WP);

      $hold  (posedge tstSTOP &&& TimingCheckEnable, WP, tHD_WP);
   endspecify

endmodule
