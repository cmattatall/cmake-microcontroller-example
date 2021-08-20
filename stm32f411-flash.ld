/* 
 * Linker script for stm32f411 microcontroller 
 * Author: Carl Mattatall
 * Date: Feb 6, 2019
**/

/* Entry Point */
ENTRY(Reset_Handler) 

/* According to CMSIS v4, Reset_Handler should be the first entry in the
 * vector table for this device. 
 * 
 * However, device datasheet aliases the boot address at 0x0000
 * so even if Reset_Handler is not present in the resolvable symbols, we will
 * default to 0x0000000000 <-- lots of zeroes, and the device will alias the
 * startup code in flash bank 1 / 2 (based on boot pins) and bootstrap will
 * occur correctly anyway. Not a best practice, but it is a nice failsafe if 
 * for some reason the vector table gets overrun/corrupted. As a side effect,
 * the linker coincidentally will also cause startup from 0x000 <-- lots of zero
 * and will have a similar result.
*/

_estack = 0x20020000;    /* end of RAM */
_Min_Heap_Size = 0x200;  /* required amount of heap  */
_Min_Stack_Size = 0x400; /* required amount of stack */

/* Specify the memory areas */
MEMORY
{
    RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 128K
    FLASH (rx)      : ORIGIN = 0x8000000, LENGTH = 512K
}

/* Define output sections */
SECTIONS
{
    /* The startup code goes first into FLASH */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector)) /* Startup code */
        . = ALIGN(4);
    } >FLASH

    /* The program code and other data goes into FLASH */
    .text :
    {
        . = ALIGN(4);
        *(.text)           /* .text sections (code) */
        *(.text*)          /* .text* sections (code) */
        *(.glue_7)         /* glue arm to thumb code */
        *(.glue_7t)        /* glue thumb to arm code */
        *(.eh_frame)

        KEEP (*(.init))
        KEEP (*(.fini))

        . = ALIGN(4);
        _etext = .;        /* define a global symbols at end of code */
    } >FLASH

    /* Constant data goes into FLASH */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)         /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
        . = ALIGN(4);
    } >FLASH

    . = ALIGN(4);

    .sysconfig : 
    {
        . = ALIGN(4);
        KEEP(*(.sysconfig_defaults))
        . = ALIGN(4);
    } > FLASH

    . = ALIGN(4);

    .ARM.extab   : 
    { 
        *(.ARM.extab* .gnu.linkonce.armextab.*) 
    } > FLASH

    .ARM : 
    {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } >FLASH

    .preinit_array     :
    {
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array*))
        PROVIDE_HIDDEN (__preinit_array_end = .);
    } >FLASH


    .init_array :
    {
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array*))
        PROVIDE_HIDDEN (__init_array_end = .);
    } >FLASH

    .fini_array :
    {
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array*))
        PROVIDE_HIDDEN (__fini_array_end = .);
    } >FLASH

    _sidata = LOADADDR(.data);

    .data : 
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start */
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */
        . = ALIGN(4);
        _edata = .;        /* define a global symbol at data end */
    } >RAM AT> FLASH

  
    . = ALIGN(4);
    .bss :
    {
        _sbss = .;         /* define a global symbol at bss start */
        __bss_start__ = _sbss;
        *(.bss)
        *(.bss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end */
        __bss_end__ = _ebss;
    } >RAM

    /* User_heap_stack section, used to check that there is enough RAM left */
    ._user_heap_stack :
    {
        . = ALIGN(8);
        PROVIDE ( end = . );
        PROVIDE ( _end = . );
        . = . + _Min_Heap_Size;
        . = . + _Min_Stack_Size;
        . = ALIGN(8);
    } >RAM

    /* Remove information from the standard libraries */
    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }

    .ARM.attributes 0 : { *(.ARM.attributes) } /* METADATA */
}
