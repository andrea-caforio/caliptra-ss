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
#include "soc_address_map.h"
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
    #define RESET_GPIO_ADDR 0x90020030
    #define MCU_RESET_VECTOR_ADDR 0x90020038
    #define MCU_LMEM_BASE_ADDR 0x80010000
    #define MCU_RECOVERY_IMAGE_READY_POLL_ADDR (MCU_LMEM_BASE_ADDR + 0xA000)
    #define MCU_RECOVERY_IMAGE_EXEC_ADDR (MCU_LMEM_BASE_ADDR + 0xB000)
    #define MCU_RECOVERY_IMAGE_SAVE_ADDR (MCU_LMEM_BASE_ADDR + 0xC000)
    volatile char *stdout = (char *)0x90021008;
#else
    #define RESET_GPIO_ADDR 0x82020030 /*FIXME*/
    #define MCU_RESET_VECTOR_ADDR 0x82020038 /*FIXME*/
    #define MCU_LMEM_BASE_ADDR 0x90010000
    #define MCU_RECOVERY_IMAGE_READY_POLL_ADDR (MCU_LMEM_BASE_ADDR + 0xA000)
    #define MCU_RECOVERY_IMAGE_EXEC_ADDR (MCU_LMEM_BASE_ADDR + 0xB000)
    #define MCU_RECOVERY_IMAGE_SAVE_ADDR (MCU_LMEM_BASE_ADDR + 0xC000)
    volatile char *stdout = (char *)0xd0580000;
#endif

volatile uint32_t intr_count = 0;
#ifdef CPT_VERBOSITY
enum printf_verbosity verbosity_g = CPT_VERBOSITY;
#else
enum printf_verbosity verbosity_g = LOW;
#endif

#define BLOCK_DW_COUNT 4
#define RCVY_IMAGE_SIZE 29


void caliptra_sleep(int cycles) {
      for (uint16_t slp = 0; slp < cycles; slp++) {
        __asm__ volatile ("nop");
    }
}

void cptra_bringup (void) {
    int argc=0;
    char *argv[1];
    uint32_t boot_fsm_ps;

    VPRINTF(LOW, "\nMCU: Caliptra Bringup\n\n")

    ////////////////////////////////////
    // Fuse and Boot Bringup
    //
    // Wait for ready_for_fuses
    while(!(lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_READY_FOR_FUSES_MASK));

    // Initialize fuses
    VPRINTF(LOW, "  * MCU: Set fuse wr done\n");
    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_FUSE_WR_DONE, SOC_IFC_REG_CPTRA_FUSE_WR_DONE_DONE_MASK);

    // Wait for Boot FSM to stall (on breakpoint) or finish bootup
    boot_fsm_ps = (lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    while(boot_fsm_ps != BOOT_DONE && boot_fsm_ps != BOOT_WAIT) {
        for (uint8_t ii = 0; ii < 16; ii++) {
            __asm__ volatile ("nop"); // Sleep loop as "nop"
        }
        boot_fsm_ps = (lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    }

    // Advance from breakpoint, if set
    VPRINTF(LOW, "  * MCU: Set BootFSM GO\n");
    if (boot_fsm_ps == BOOT_WAIT) {
        lsu_write_32(SOC_SOC_IFC_REG_CPTRA_BOOTFSM_GO, SOC_IFC_REG_CPTRA_BOOTFSM_GO_GO_MASK);
    }

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
  printf("  * MCU: Configure HC Timing\n");
  lsu_write_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_FREE_REG, 0x27);
  lsu_write_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_IDLE_REG, 0x3e8);
  lsu_write_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_AVAL_REG, 0x30d40);
  printf("  * T_FREE: 0x%x\n", lsu_read_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_FREE_REG) );
  printf("  * T_IDLE: 0x%x\n", lsu_read_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_IDLE_REG) );
  printf("  * T_AVAL: 0x%x\n", lsu_read_32(SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_AVAL_REG) );
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

void poll_for_recovery_image_ready(){
  uint32_t data;
  uint8_t flag = 1;

  // Poll for Recovery Image Ready
  while (lsu_read_32(MCU_RECOVERY_IMAGE_READY_POLL_ADDR) != 0x00000001) {
    if (flag) {
      printf("  * MCU: Polling for recovery image ready...\n");
      flag = 0;
    }
    caliptra_sleep(32);
  }
  flag = 1; // reset flag
  printf("  * MCU: Recovery image ready\n\n");
}

void send_payload(uintptr_t image_addr, uint32_t image_size){
    uint32_t image_dw_remaining;
    printf("  * BMC: Sending payload [0x%x dwords] to Recovery, from address 0x%x\n", image_size, image_addr);

    image_dw_remaining = (image_size);
  
    while (image_dw_remaining > BLOCK_DW_COUNT) {
        printf("    ==== 0x%x remaining ====\n", image_dw_remaining);
        // Wait for FIFO EMPTY
        while(lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_INDIRECT_FIFO_STATUS_0) != 0x1) {
            caliptra_sleep(1);
        }
        printf("    fifo empty\n    ");
        // Send 1 block of data
        for (uint32_t dw_cnt = 0; dw_cnt < BLOCK_DW_COUNT; dw_cnt++) {
            lsu_write_32(SOC_I3CCSR_PIOCONTROL_TX_DATA_PORT, lsu_read_32(image_addr));
            image_addr+=4;
            printf(">");
        }
        printf("\n");
        image_dw_remaining -= BLOCK_DW_COUNT;
    }
    if (image_dw_remaining) {
        printf("    ==== 0x%x remaining ====\n", image_dw_remaining);
        // Wait for FIFO EMPTY
        while(lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_INDIRECT_FIFO_STATUS_0) != 0x1) {
            caliptra_sleep(1);
        }
        printf("    fifo empty\n    ");
        // Send remaining data
        for (uint32_t dw_cnt = 0; dw_cnt < image_dw_remaining; dw_cnt++) {
            lsu_write_32(SOC_I3CCSR_PIOCONTROL_TX_DATA_PORT, lsu_read_32(image_addr));
            image_addr+=4;
            printf(">");
        }
        printf("\n");
    }
    printf("  * BMC: Payload sent\n");
}

void main() {
  int error;
  uint32_t data;
  int flag = 1;
  void (* call_update_img) (void) = (void*) MCU_RECOVERY_IMAGE_EXEC_ADDR;
  

//  uint32_t* dbg_ptr = (uint32_t*)(MCU_LMEM_BASE_ADDR + 0x6000);

  printf("---------------------------\n");
  printf(" Caliptra Subsystem Recovery Demo\n");
  printf("---------------------------\n\n");


  // Run test for I3C Base registers ------------------------------------------
  printf("\nMCU: Test access to I3C Base registers\n");

  // Read RO register
  data = lsu_read_32(SOC_I3CCSR_I3CBASE_HCI_VERSION);
  printf("  * Check I3C HCI Version (0x%x): ", data);
  error += check_and_report_value(data, HCI_VERSION);
  data = lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_EXTCAP_HEADER);
  printf("  * Check I3C EXTCAP (0x%x): ", data);
  error += check_and_report_value(data, 0x20c0);
  putchar('\n');

  printf("\nMCU: configuring timing \n\n");
  configure_i3c_timing();
  enable_i3c_target();
  cptra_bringup();

  printf("\nMCU: Wait for image update\n");

  //-- dummy BMC steps start 
  //-- from MCU to I3C -- FIXME

      //     // -( Start of recovery)  : Wait in loop for Byte 0 to be written with 0x3 in DEVICE_STATUS register - I3C Read
      data = lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_DEVICE_STATUS_0);
      while((data & 0x3) != 0x3) {
        if(flag) {
          printf("\nBMC: Polling for recovery mode...\n");
          flag = 0;
        }
        data = lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_DEVICE_STATUS_0);
        caliptra_sleep(1);
      }
      flag = 1; // reset flag
      printf("  * BMC: Recovery mode enabled\n");

      // - BMC programs INDIRECT_FIFO_CTRL with Image size (multiple of 4B) & reset FIFO. - I3C Write
      printf("\nBMC: Write FIFO control\n");
      data  = (0<<0) |
              (1<<8) |
              (RCVY_IMAGE_SIZE << 16);    //- Image Size (4 Data words, Resetting the fifo, CMS=0)
      lsu_write_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_INDIRECT_FIFO_CTRL_0, data);
      data  = RCVY_IMAGE_SIZE >> 16;          //- Image length for upper DWORD
      lsu_write_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_INDIRECT_FIFO_CTRL_1, data);
      printf("  * BMC: FIFO control written... \n");
      
      // - BMC Starts sending payloads in chunks of 256B (image payload) + 4B (header) - I3C Write  
      printf("\nBMC: Send and Activate Image\n");
//      /*=========== FIXME ===========*/
//      lsu_write_32(MCU_RECOVERY_IMAGE_SAVE_ADDR, 0xabadd00d);
//      lsu_write_32(MCU_RECOVERY_IMAGE_SAVE_ADDR+ 4, 0xba5eba11);
//      lsu_write_32(MCU_RECOVERY_IMAGE_SAVE_ADDR+8, 0xcafebabe);
//      lsu_write_32(MCU_RECOVERY_IMAGE_SAVE_ADDR+0xC, 0xdeadbeef);
//      /*=========== FIXME ===========*/
      send_payload(MCU_RECOVERY_IMAGE_SAVE_ADDR, RCVY_IMAGE_SIZE);

      // - If image is greater than 256B, number of I3C writes will be (Image size / 256B) + (Image size % 256B?== 1? 1:0) 
      // - BMC writes to RECOVERY_CTRL register to activate the image. - I3C Write byte 2 with 0xf
      data = (0x0f << 16); //-- Activating Image
      lsu_write_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_RECOVERY_CTRL, data);
      printf("  * BMC: Image activated... \n");

      // - BMC reads from RECOVERY_CTRL register to confirm, image activation was read. - I3C read (optional) - (end of recovery)
      data = lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_RECOVERY_CTRL);
      while(data != 0x10000) {
//        if(flag) {
          printf("  * BMC: Polling for deassertion of recovery image activation... (0x%x)\n", data);
//          flag = 0;
//        }
        data = lsu_read_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_RECOVERY_CTRL);
        caliptra_sleep(64);
      }
      printf("  * BMC: Recovery image activation deasserted\n");
      // - Update with RECOVERY_STATUS by incrementing image index. - I3C Write
      lsu_write_32(SOC_I3CCSR_I3C_EC_SECFWRECOVERYIF_RECOVERY_STATUS, 0x1);
      printf("  * BMC: Image index incremented in RECOVERY_STATUS\n");

  //-- dummy steps end

  // Poll for Recovery Image Ready
  poll_for_recovery_image_ready();

  printf("\nMCU: Transitioning to recovery image...\n");
  call_update_img();

  printf("\nMCU: ERROR! Failed to load recovery image\n");
  while(1);

}
