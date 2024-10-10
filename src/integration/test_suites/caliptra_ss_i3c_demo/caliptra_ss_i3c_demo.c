// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#include "printf.h"
#include "riscv_hw_if.h"
#include "caliptra_reg.h"
#include "soc_ifc.h"
#include "i3c_csr_accessors.h"
#include "I3CCSR.h"

#define HCI_VERSION (0x120)
#define TEST_ADDR (0x5f)
#define TEST_WORD1 (0xdeadbeef)
#define TEST_WORD2 (0xabcd9876)
//#define TX_QUEUE_SIZE (I3CCSR__PIOCONTROL__QUEUE_SIZE__TX_DATA_BUFFER_SIZE_reset)
//#define RX_QUEUE_SIZE (I3CCSR__PIOCONTROL__QUEUE_SIZE__RX_DATA_BUFFER_SIZE_reset)
#define PIO_CONTROL_ENABLED (0x7)
#define RETRY_CNT (0x2)
#define AUTOCMD_HDR (0xc3)

// Helpers for Recovery Flow CSRs
#define I3C_DEVICE_ID_LOW 0x0
#define I3C_DEVICE_ID_MASK 0x1
#define I3C_DEVICE_STATUS_LOW 0x0
#define I3C_DEVICE_STATUS_MASK 0x3
#define I3C_LOCAL_C_IMAGE_SUPPORT_LOW 0x6
#define I3C_LOCAL_C_IMAGE_SUPPORT_MASK 0x40
#define I3C_PUSH_C_IMAGE_SUPPORT_LOW 0x7
#define I3C_PUSH_C_IMAGE_SUPPORT_MASK 0x80
#define I3C_INDIRECT_CONTROL_LOW 0x5
#define I3C_INDIRECT_CONTROL_MASK 0x20
#define I3C_RECOVERY_STATUS_LOW 0x0
#define I3C_RECOVERY_STATUS_MASK 0xff

#ifdef CALIPTRA_SS_FPGA
    #define RECOVERY_BASE_ADDR 0x82030000
    #define RESET_GPIO_ADDR 0x82020030
    #define MCU_RESET_VECTOR_ADDR 0x82020038
    #define MCU_LMEM_BASE_ADDR 0x82010000
    #define CPTRA_SOC_IFC_REG_BASE_ADDR /*FIXME*/
    volatile char *stdout = (char *)0x82021008;
#else
    #define RECOVERY_BASE_ADDR 0x20004000
    #define RESET_GPIO_ADDR 0x82020030
    #define MCU_RESET_VECTOR_ADDR 0x82020038
    #define MCU_LMEM_BASE_ADDR 0x90010000
    #define CPTRA_SOC_IFC_REG_BASE_ADDR CLP_SOC_IFC_REG_BASE_ADDR
    volatile char *stdout = (char *)0xd0580000;
#endif

volatile uint32_t intr_count = 0;
#ifdef CPT_VERBOSITY
enum printf_verbosity verbosity_g = CPT_VERBOSITY;
#else
enum printf_verbosity verbosity_g = LOW;
#endif

void cptra_bringup (void) {
    int argc=0;
    char *argv[1];
    uint32_t boot_fsm_ps;

    VPRINTF(LOW, "MCU: Caliptra Bringup\n\n")

    ////////////////////////////////////
    // Fuse and Boot Bringup
    //
    // Wait for ready_for_fuses
    while(!(lsu_read_32(CPTRA_SOC_IFC_REG_BASE_ADDR + SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_READY_FOR_FUSES_MASK));

    // Initialize fuses
    lsu_write_32(CPTRA_SOC_IFC_REG_BASE_ADDR + SOC_IFC_REG_CPTRA_FUSE_WR_DONE, SOC_IFC_REG_CPTRA_FUSE_WR_DONE_DONE_MASK);
    VPRINTF(LOW, "MCU: Set fuse wr done\n");

    // Wait for Boot FSM to stall (on breakpoint) or finish bootup
    boot_fsm_ps = (lsu_read_32(CPTRA_SOC_IFC_REG_BASE_ADDR + SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    while(boot_fsm_ps != BOOT_DONE && boot_fsm_ps != BOOT_WAIT) {
        for (uint8_t ii = 0; ii < 16; ii++) {
            __asm__ volatile ("nop"); // Sleep loop as "nop"
        }
        boot_fsm_ps = (lsu_read_32(CPTRA_SOC_IFC_REG_BASE_ADDR + SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    }

    // Advance from breakpoint, if set
    if (boot_fsm_ps == BOOT_WAIT) {
        lsu_write_32(CPTRA_SOC_IFC_REG_BASE_ADDR + SOC_IFC_REG_CPTRA_BOOTFSM_GO, SOC_IFC_REG_CPTRA_BOOTFSM_GO_GO_MASK);
    }
    VPRINTF(LOW, "MCU: Set BootFSM GO\n");

}

int check_and_report_value(uint32_t value, uint32_t expected) {
  if (value == expected) {
    printf("CORRECT\n");
    return 0;
  } else {
    printf("ERROR (0x%x vs 0x%x)\n", value, expected);
    return 1;
  }
}

void configure_i3c_timing() {
  // Configure timing
  printf("MCU: Configure HC Timing\n");
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_FREE_REG, 0x27);
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_IDLE_REG, 0x3e8);
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_AVAL_REG, 0x30d40);
  printf("T_FREE: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_FREE_REG) );
  printf("T_IDLE: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_IDLE_REG) );
  printf("T_AVAL: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_AVAL_REG) );
  putchar('\n');
}

void enable_i3c_target() {
    // Optional steps
//    // Enable I3C Host Controller
//    printf("Enable HC Control\n");
//    write_i3c_reg_field(I3C_REG_I3CBASE_HC_CONTROL, I3C_REG_I3CBASE_HC_CONTROL_BUS_ENABLE_LOW, I3C_REG_I3CBASE_HC_CONTROL_BUS_ENABLE_MASK, 1);
//
//    // Enable Standby Controller Mode
//    // Set PID

    return;
}

void main() {
  int error;
  int data;

//  uint32_t* dbg_ptr = (uint32_t*)(MCU_LMEM_BASE_ADDR + 0x6000);

  printf("---------------------------\n");
  printf(" Caliptra Subsystem Recovery Demo\n");
  printf("---------------------------\n\n");


  // Run test for I3C Base registers ------------------------------------------
  printf("MCU: Test access to I3C Base registers\n");

  // Read RO register
  data = read_i3c_reg(I3C_REG_I3CBASE_HCI_VERSION);
  printf("Check I3C HCI Version (0x%x): ", data);
  error += check_and_report_value(data, HCI_VERSION);
  putchar('\n');

  configure_i3c_timing();
  enable_i3c_target();

  cptra_bringup();

  while(1);

}
