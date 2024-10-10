OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS {
    . = 0x82010000;
  .text   : { *(.text*) }
 _end = .;
  .data  :  { *(.*data) *(.rodata*) *(.srodata*) *(.sbss) }
  .bss : { *(.bss) }
  STACK = ALIGN(16) + 0x1000;
  . = 0x82021008;
  .data.io .  : { *(.data.io) }
}
