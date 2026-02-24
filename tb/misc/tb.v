`include "boot_defs.svh"

module tb();
    integer memory_write_back_test_success = 1;
    integer i;
    task wait_bootloader();
        begin
`ifndef BOOT_SKIP

    `ifdef BOOT_WRITEBACK
            #725_000_000; // Bootloader working
    `else
            #120_000_000; // Bootloader working
    `endif
            // Outputs to vcd file waveform 5ms before bootloader is done (there is no need to see whole bootloader process)
    `ifdef DUMPVCD
            $dumpfile("output.vcd");
            $dumpvars(0,simple_system_tb);
    `endif
            #4_524_000; // Bootloader is done
`endif
        end
    endtask
    
    task memory_write_back_test();
        begin
            #6_000_000; // wait until eeprom saves any data from buffer page (takes ussually 5ms)
            for (i = 0; i < `IMEM_SIZE+`DMEM_SIZE; i=i+1) begin
                if (simple_system_tb.eeprom.MemoryBlock[`EEPROM_READ_ADDR+i] != simple_system_tb.eeprom.MemoryBlock[`EEPROM_WRITE_ADDR+i]) begin
                    memory_write_back_test_success = 0;
                    $display("Data on original data address 0x%0h and on re-writen data adrress 0x%0h are not the same!", `EEPROM_READ_ADDR+i , `EEPROM_WRITE_ADDR+i);
                    $display("Data 0x%0h does not match with 0x%0h", simple_system_tb.eeprom.MemoryBlock[`EEPROM_READ_ADDR+i] , simple_system_tb.eeprom.MemoryBlock[`EEPROM_WRITE_ADDR+i]);
                    $display("Memory write back test is not passed");
`ifdef LOG_OUTPUT
                    $fwrite(simple_system_tb.fd, "[   FAIL]: data on original data address 0x%0h and re-writen data address 0x%0h are not the same: read = 0x%0h written = 0x%0h\n", 
                            `EEPROM_READ_ADDR+i ,
                            `EEPROM_WRITE_ADDR+i,
                            simple_system_tb.eeprom.MemoryBlock[`EEPROM_READ_ADDR+i],
                            simple_system_tb.eeprom.MemoryBlock[`EEPROM_WRITE_ADDR+i]);
`else
                    $stop();
`endif
                end
            end
            if (!memory_write_back_test_success) begin
                $display("[   FAIL]: memory write back test (tb/misc/tb.memory_write_back_test)");
`ifdef LOG_OUTPUT
                $fwrite(simple_system_tb.fd, "[   FAIL]: memory write back test (tb/misc/tb.memory_write_back_test)\n");
`endif
            end else begin
                $display("[SUCCESS]: memory write back test (tb/misc/tb.memory_write_back_test)");
`ifdef LOG_OUTPUT
                $fwrite(simple_system_tb.fd, "[SUCCESS]: memory write back test (tb/misc/tb.memory_write_back_test)\n");
`endif
            end
        end
    endtask
endmodule
