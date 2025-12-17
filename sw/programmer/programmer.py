bin_file="../ibex_sw/verilog_bin.bin" # Binary file to send

program_start_addr = 0

read_bin_file="../read_back.bin" # Binary file to read
read_back_start_addr = 12288 # 12KByte
# read_back_start_addr = 12416 # 12KByte + 128Byte
# read_back_start_addr = 0 # 12KByte + 128Byte
size = 12288

# serial_port = "COM5"

import serial
import time
import os
import sys, argparse

if os.name == 'posix':
    serial_port="/dev/ttyUSB0"      # Change depending on your system (LINUX)
elif os.name == 'nt':
    serial_port = "COM5"            # Change depending on your system (WINDOWS)


ser = serial.Serial(serial_port, 115200,
                     bytesize=serial.EIGHTBITS,
                     parity=serial.PARITY_NONE,
                     stopbits=serial.STOPBITS_ONE,
                     timeout=2,
                     xonxoff=False,
                     rtscts=False,
                     dsrdtr=False
)

def write_bin(bin, ser, start_addr):
    counter = 0
    with open(bin, mode='rb') as file:                     # b is important -> binary
        size=os.path.getsize(bin)
        # Write bin file by chunks of 16 bytes
        for i in range(int(size/16)):
            fileContent = file.read(16)                         # Ger BIN file 16 bytes
            packet = (counter+start_addr).to_bytes(2, 'big')+fileContent     # Add EEPROM pointer address in front of BIN file data

            ser.write(bytes('W', 'utf-8')+packet)                                   # Write EEPROM pointer (2 bytes) and data (16 bytes) to serial
            ser.flush()                                         # Ensure it's written out
            received_packet = ser.read(18)                      # Get writen data back from EEPROM (should be same)

            if received_packet == packet:
                # print(f"OK {i}")
                nop=0 #do nothing
            else:
                print(f"STOP {i}")
                print(packet)
                print(received_packet)
                print("")
                # exit("ERROR")
                return -1
            counter += 16 # Increase counter by 16

    return counter


def read_bin(ser, start_addr, size):
    counter = 0
    data = bytes()
    for i in range(int(size/16)):
        packet = (counter+start_addr).to_bytes(2, 'big') + bytes(16)
        ser.write(bytes('R', 'utf-8')+packet)
        ser.flush()                                         # Ensure it's written out
        received_packet = ser.read(18)                      # Get writen data back from EEPROM (should be same)

        if received_packet[0:1]==packet[0:1]:
            # print(f"READ OK {i}")
            data+=received_packet[2:18]
        else:
            print(f"STOP {i}")
            print(f"Address mismatch")
            print(packet)
            print(received_packet)
            print("")
            # exit("ERROR")
            return -1
        counter += 16 # Increase counter by 16
    return data
def save_read_bin(bin, ser, start_addr, size):
    data = read_bin(ser, start_addr, size)
    if (data==-1):
        return -1
    with open(bin, mode='wb') as file:                     # b is important -> binary
        file.write(data)
    return 0

# Make sure DTR and RTS are not asserted
ser.setDTR(False)
ser.setRTS(False)

time.sleep(2)               # Wait for arduino to initialize
ser.reset_input_buffer()    # Clear the serial input buffer
ser.reset_output_buffer()   # Clear the serial input buffer


# parser = argparse.ArgumentParser()
parser = argparse.ArgumentParser(description="Demo of argparse")

parser.add_argument("--write", action="store_true", help=f"write bin file")
parser.add_argument("--read", action="store_true", help=f"read back from EEPROM to bin file")
parser.add_argument("--check", action="store_true", help=f"read back from EEPROM two times: old data and data written back by bootloader, check whether data is the same (recomended to do everytime writei is called)")
parser.add_argument("-i", "--input", help=f"binary file to be writen to EEPROM (default: {bin_file})")
parser.add_argument("-wa", "--w_addr", help=f"address to write bin file to EEPROM (default: {program_start_addr} bytes)")
parser.add_argument("-o", "--output", help=f"binary file to store read back from EEPROM (default: {read_bin_file} bytes)")
parser.add_argument("-ra", "--r_addr", help=f"address starting which read from EEPROM (default: {read_back_start_addr} bytes)")
parser.add_argument("-s", "--size", help=f"read size from EEPROM (default: {size} bytes)")


args = parser.parse_args()

if args.output:
    print("Output file set to:", args.output)
    read_bin_file=args.output
if args.r_addr:
    print("Read start address set to:", args.r_addr)
    read_back_start_addr=int(args.r_addr)
if args.input:
    print("Input file set to:", args.input)
    bin_file=args.input
if args.w_addr:
    print("Write start address set to:", args.w_addr)
    program_start_addr=int(args.w_addr)
if args.size:
    print("Read size set to:", args.size)
    size=int(args.size)

if args.check:
    print(f"Reading data from EEPROM starting on {hex(program_start_addr)} address for size of {hex(size)}")
    data1 = read_bin(ser, program_start_addr, size)
    if (data1==-1):
        exit("ERROR")
    print("Reading done successfully")
    print(f"Reading data from EEPROM starting on {hex(read_back_start_addr)} address for size of {hex(size)}")
    data2 = read_bin(ser, read_back_start_addr, size)
    if (data2==-1):
        exit("ERROR")
    print("Reading done successfully")
    if (data1!=data2):
        print("Data is not matching!")
        print("Either checking was called before the EEPROM was pluged into the FPGA, or the bootloader is not working correctly")
        input("Press ENTER to continue")
    else:
        print("Data is matching:)")


if args.write:
    print(f"Writing {bin_file} file to EEPROM starting on {hex(program_start_addr)} address")
    size=write_bin(bin_file,ser,program_start_addr)
    if (size == -1):
        exit("ERROR")
    print("Writing done successfully")

# if args.size:
#     print("Read size set to:", args.size)
#     program_start_addr=int(args.size)

if args.read:
    print(f"Reading data from EEPROM starting on {hex(read_back_start_addr)} address for size of {hex(size)} to file {read_bin_file}")
    if (save_read_bin(read_bin_file,ser,read_back_start_addr,size) == -1):
        exit("ERROR")
    print("Reading done successfully")


# size=write_bin(bin_file,ser,program_start_addr)
# read_bin(read_bin_file,ser,read_back_start_addr,size)


ser.close()
