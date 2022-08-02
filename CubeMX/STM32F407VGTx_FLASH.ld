/* Entry point to first function executed */
ENTRY(Reset_Handler) /* Reset_Handler is stored somewhere in FLASH */

/* End of stack (start) is at end of RAM, as stack grows down */
_estack = 0x20020000;    /* ORIGIN (0x20000000) + LENGTH (0x20000) */

/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 0x200;  /* required amount of heap  */
_Min_Stack_Size = 0x400; /* required amount of stack */

/* Specify the memory areas (datasheet) */

MEMORY
{
RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 128K     /* main memory */
CCMRAM (xrw)   : ORIGIN = 0x10000000, LENGTH = 64K      /* core coupled memory */
FLASH (rx)     : ORIGIN = 0x8000000,  LENGTH = 1024K    /* flash ROM */
}

/* Output sections - where is data placed */

/* 
ADDRESS:    | 0x08000000     | 0x08000000 + (0) | 0x08000000 + (1)    | 0x08000000 + (2) | 0x08000000 + (3)  | 0x08000000 + (4) | 0x08000000 + (5) | ~ | 0x08000000 + (6), 0x20000000 | / | 0x20000000 + (7)                 | 0x20000000 + (8) 
SEQUENCE:   | 0              | 1                | 2                   | 3                | 4                 | 5                | 6                | ~ | 7                            | / | 8                                | 9 
FUNCTION:   | vector table   | code             | constants           | arm data         | constructors      | constructors     | destructors      | ~ | initialized global variables | / | uninitialized global variables " | check, end of static ram data  
SECTIONS:   | .isr_vector    | .text, .text*    | .rodata, .rodata*   | .ARM*            | .preinit_array*   | .init_array*     | .fini_array*     | ~ | .data, .data*                | / | .bss, .bss*                      | ._user_heap_stack   
REGION:     | [FLASH]        | [   FLASH   ]    | [FLASH]             | [FLASH]          | [FLASH]           | [FLASH]          | [FLASH]          | ~ | [   FLASH   ] -> [   RAM   ] | / | [   RAM   ]                      | [   [RAM]   ]  
                                           ^                                                                                                             ^                ^         ^       ^         ^                                    ^  
                                           |                                                                                                             |                |         |       |         |                                    |  
SYMBOLS:                                _etext                                                                                                        _sidata          _sdata    _edata   _sbss     _ebss                              _end, end
 */

SECTIONS
{
  /* Initial stack position, reset_handler and vector table */
  .isr_vector :
  {
    . = ALIGN(4);        /* All data, unless specified else, is 4B (word) aligned */
    KEEP(*(.isr_vector)) /* Keep this section even if unused */
    . = ALIGN(4);
  } >FLASH               /* Store section in FLASH, LMA and VMA are the same */

  /* The program code and other data*/
  .text :
  {
    . = ALIGN(4);
    *(.text)           
    *(.text*)          
    *(.glue_7)         /* Compiler glue/helper functions */
    *(.glue_7t)        /* -||- */
    *(.eh_frame)       /* Exception unwinding information (empty as it is disabled) */
    KEEP (*(.init))    /* Support for constructors and destructors  */
    KEEP (*(.fini))    /* -||- */
    . = ALIGN(4);
    _etext = .;        /* define a global symbol at end of code section */
  } >FLASH

  /* Constants*/
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)         
    *(.rodata*)        
    . = ALIGN(4);
  } >FLASH

  /* ARM's stuff */
  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >FLASH
  .ARM : {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } >FLASH

  /* Pre-initialization functions, only in dynamic executables (empty for us) */
  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .); /* Same as PROVIDE but limited to current file */
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >FLASH

  /* Constructor arrays */
  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >FLASH

  /* Destructor arrays */
  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >FLASH

  /* define global symbol at beginning of initial values for global variables in FLASH for RAM */
  _sidata = LOADADDR(.data); /* get absolute load memory address of section */

  /* Initialized data (initialized global variables) */
  .data : 
  {
    . = ALIGN(4);
    _sdata = .;        /* define a global symbol at data start */
    *(.data)           
    *(.data*)          
    . = ALIGN(4);
    _edata = .;        /* define a global symbol at data end */
  } >RAM AT> FLASH     /* AT specifies that load memory address is in FLASH, RAM is VMA*/

  /* define global symbol at beginning of initial values for global variables in FLASH for CCRAM */
  _siccmram = LOADADDR(.ccmram);

  /* CCM-RAM section 
     Provided startup file does not initialize data in CCRAM!
     Implementation can be the same as for .data
  */
  .ccmram :
  {
    . = ALIGN(4);
    _sccmram = .;       /* define a global symbol at ccmram start */
    *(.ccmram)
    *(.ccmram*)
    . = ALIGN(4);
    _eccmram = .;       /* define a global symbol at ccmram end */
  } >CCMRAM AT> FLASH

  /* Uninitialized data section *uninitialized global variables) */
  . = ALIGN(4);
  .bss :
  {
    _sbss = .;         /* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
  } >RAM

  /* User_heap_stack section, used to check that there is enough RAM left */
  ._user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE ( end = . ); /* these two sybols can be re-defined/used */
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

  .ARM.attributes 0 : { *(.ARM.attributes) }
}

