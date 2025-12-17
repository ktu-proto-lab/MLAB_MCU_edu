OUTPUT_ARCH(riscv)

MEMORY
{
    rom	(rx)	 : ORIGIN = 0x80000000, LENGTH = 0x2000  /* Instructions (8192 bytes)*/
	ram (rwx)    : ORIGIN = 0x90000000, LENGTH = 0x1000  /* Data & Stack (4096 bytes)*/
}

/* Stack information variables */
_min_stack      = 0x400;   /* 1KB - minimum stack space to reserve */
_stack_len     = LENGTH(ram);
_stack_start   = ORIGIN(ram) + LENGTH(ram);

_entry_point = _vectors_start + 0x80;
ENTRY(_entry_point) /* First instruction to execute*/

SECTIONS
{
    .vectors :
    {
        . = ALIGN(4);
		_vectors_start = .;
        KEEP(*(.vectors))
		_vectors_end = .;
    } > rom

    .text : {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    }  > rom

    .nops : {
        . = ALIGN(4);
        *(.nops)
    } > rom

    .rodata : {
        . = ALIGN(4);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata);
        *(.rodata.*)
        . = ALIGN(4);
    } > rom

    .data : {
        . = ALIGN(4);
        /* Small data before large data */
        *(.sdata)
        *(.sdata.*)
        *(.data);
        *(.data.*)
        . = ALIGN(4);
    } > ram

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        /* Small BSS before large BSS */
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > ram

    . = ALIGN(4);
    _end = .; /* Heap starts here and grows upwards */

    /* ensure there is enough room for stack */
    .stack (NOLOAD): {
        . = ALIGN(4);
        . = . + _min_stack ;
        . = ALIGN(4);
        stack = . ;
        _stack = . ;
        _stack_bottom = _stack_start - _min_stack;
    } > ram
}
