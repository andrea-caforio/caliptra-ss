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

#ifdef CALIPTRA_SS_FPGA
    #define RECOVERY_BASE_ADDR 0x82030000
    #define RESET_GPIO_ADDR 0x82020030
    #define MCU_RESET_VECTOR_ADDR 0x82020038
    #define MCU_LMEM_BASE_ADDR 0x82010000
    volatile char *stdout = (char *)82021008;
#else
    #define RECOVERY_BASE_ADDR 0x20004000
    #define RESET_GPIO_ADDR 0x82020030
    #define MCU_RESET_VECTOR_ADDR 0x82020038
    #define MCU_LMEM_BASE_ADDR 0x80010000
    volatile char *stdout = (char *)STDOUT;
#endif

volatile uint32_t intr_count = 0;
#ifdef CPT_VERBOSITY
enum printf_verbosity verbosity_g = CPT_VERBOSITY;
#else
enum printf_verbosity verbosity_g = LOW;
#endif


int check_and_report_value(uint32_t value, uint32_t expected) {
  if (value == expected) {
    printf("CORRECT\n");
    return 0;
  } else {
    printf("ERROR (0x%x vs 0x%x)\n", value, expected);
    return 1;
  }
}


void main() {
  int error;
  int data;

  uint32_t* dbg_ptr = (uint32_t*)(MCU_LMEM_BASE_ADDR + 0x6000);

  printf("---------------------------\n");
  printf(" I3C CSR Smoke Test \n");
  printf("---------------------------\n");


  // Run test for I3C Base registers ------------------------------------------
  printf("Test access to I3C Base registers\n");
  printf("---\n");

  // Read RO register
  data = read_i3c_reg(I3C_REG_I3CBASE_HCI_VERSION);
  printf("Check I3C HCI Version: ");
  error += check_and_report_value(data, HCI_VERSION);

  // Configure timing
  printf("Configure HC Timing\n");
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_FREE_REG, 0x27);
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_IDLE_REG, 0x3e8);
  write_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_AVAL_REG, 0x30d40);
  printf("T_FREE: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_FREE_REG) );
  printf("T_IDLE: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_IDLE_REG) );
  printf("T_AVAL: 0x%x\n", read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_AVAL_REG) );
//  *dbg_ptr = read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_FREE_REG);
//  dbg_ptr += 2;
//  *dbg_ptr = read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_IDLE_REG);
//  dbg_ptr += 2;
//  *dbg_ptr = read_i3c_reg(I3C_REG_I3C_EC_SOCMGMTIF_T_AVAL_REG);
//  dbg_ptr += 2;

  // Enable I3C Host Controller
  printf("Enable HC Control\n");
  write_i3c_reg_field(I3C_REG_I3CBASE_HC_CONTROL,
    I3C_REG_I3CBASE_HC_CONTROL_BUS_ENABLE_LOW, I3C_REG_I3CBASE_HC_CONTROL_BUS_ENABLE_MASK, 1);

  // Set PID

  // Set recovery ready


  while(1);

}
