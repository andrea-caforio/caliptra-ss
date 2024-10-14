# SPDX-License-Identifier: Apache-2.0
# Copyright 2020 Western Digital Corporation or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

.set    mfdc, 0x7f9
.set    mrac, 0x7c0
.section .text.init
.align 4
.global _start
_start:

        la x1, _trap
        csrw mtvec, x1

        // MRAC
        // Disable Caches on all regions except...
        //  - Set cacheable for ROM to improve perf
        // Set side-effects (SE) at peripheral address regions:
        //  - [UNMAPPED] @ 0x0000_0000:    SE
        //  - [UNMAPPED] @ 0x1000_0000:    SE
        //  - [UNMAPPED] @ 0x2000_0000:    SE
        //  - soc_ifc    @ 0x3000_0000:    SE
        //  - [UNMAPPED] @ 0x4000_0000:    SE
        //  - DCCM       @ 0x5000_0000: no SE
        //  - PIC        @ 0x6000_0000:    SE
        //  - [UNMAPPED] @ 0x7000_0000:    SE
        //  - imem/lmem  @ 0x8000_0000: no SE, +Cache FIXME
        //  - [UNMAPPED] @ 0x9000_0000:    SE
        //  - ...
        //  - [UNMAPPED] @ 0xC000_0000:    SE
        //  - STDOUT     @ 0xD000_0000:    SE
        //  - [UNMAPPED] @ 0xE000_0000:    SE
        //  - [UNMAPPED] @ 0xF000_0000:    SE
        li t0, 0xAAAAA2AA
        csrw mrac, t0

        la sp, STACK

        call main

        # Map exit code of main() to command to be written to tohost
        snez a0, a0
        bnez a0, _finish
        li   a0, 0xFF

.global _finish
_finish:
        la t0, tohost
        sb a0, 0(t0)
        li a0, 1
        sw a0, 0(t0)
        beq x0, x0, _finish
        .rept 10
        nop
        .endr

.align 4
_trap:
    la t0, tohost
    li a0, 0x2e
    sb a0, 0(t0)
    // mcause
    csrr a0, 0x342
    fence.i
    srli t1, a0, 28
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 24
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 20
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 16
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 12
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 8
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 4
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    //srli t1, a0, 28
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    // sep '.'
    li a0, 0x2e
    sb a0, 0(t0)
    // mscause
    csrr a0, 0x7ff
    fence.i
    srli t1, a0, 28
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 24
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 20
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 16
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 12
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 8
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    srli t1, a0, 4
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    //srli t1, a0, 28
    andi t1, t1, 0xf
    addi t1, t1, 0x30
    sb t1, 0(t0)
    // Failure
    li a0, 1 # failure
    j _finish

.section .data.io
.global tohost
tohost: .word 0
