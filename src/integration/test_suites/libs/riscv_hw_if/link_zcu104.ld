OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS {
    . = 0x80010000;
  .text   : { *(.text*) } =0x0000,
 _end = .;
  .data  :  { *(.*data) *(.rodata*) *(.srodata*) *(.sbss) } =0x0000,
  .bss : { *(.bss) } =0x0000,
  STACK = ALIGN(16) + 0x1000;
  . = 0x90021008;
  .data.io .  : { *(.data.io) }
}
