
#include "soc_address_map.h"
#include "printf.h"
#include "riscv_hw_if.h"
#include "soc_ifc.h"
#include <string.h>
#include <stdint.h>

volatile char* stdout = (char *)0xd0580000;
#ifdef CPT_VERBOSITY
    enum printf_verbosity verbosity_g = CPT_VERBOSITY;
#else
    enum printf_verbosity verbosity_g = LOW;
#endif

void main (void) {
    int argc=0;
    char *argv[1];
    enum boot_fsm_state_e boot_fsm_ps;
    const uint32_t mbox_dlen = 64;
    uint32_t mbox_data[] = { 0x00000000,
                             0x11111111,
                             0x22222222,
                             0x33333333,
                             0x44444444,
                             0x55555555,
                             0x66666666,
                             0x77777777,
                             0x88888888,
                             0x99999999,
                             0xaaaaaaaa,
                             0xbbbbbbbb,
                             0xcccccccc,
                             0xdddddddd,
                             0xeeeeeeee,
                             0xffffffff };
    uint32_t mbox_resp_dlen;
    uint32_t mbox_resp_data;
    uint32_t i3c_reg_data;

    VPRINTF(LOW, "=================\nMCU Caliptra Bringup\n=================\n\n")

    ////////////////////////////////////
    // Fuse and Boot Bringup
    //
    // Wait for ready_for_fuses
    while(!(lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_READY_FOR_FUSES_MASK));

    // Initialize fuses
    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_FUSE_WR_DONE, SOC_IFC_REG_CPTRA_FUSE_WR_DONE_DONE_MASK);
    VPRINTF(LOW, "MCU: Set fuse wr done\n");

    // Wait for Boot FSM to stall (on breakpoint) or finish bootup
    boot_fsm_ps = (lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    while(boot_fsm_ps != BOOT_DONE && boot_fsm_ps != BOOT_WAIT) {
        for (uint8_t ii = 0; ii < 16; ii++) {
            __asm__ volatile ("nop"); // Sleep loop as "nop"
        }
        boot_fsm_ps = (lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_MASK) >> SOC_IFC_REG_CPTRA_FLOW_STATUS_BOOT_FSM_PS_LOW;
    }

    // Advance from breakpoint, if set
    if (boot_fsm_ps == BOOT_WAIT) {
        lsu_write_32(SOC_SOC_IFC_REG_CPTRA_BOOTFSM_GO, SOC_IFC_REG_CPTRA_BOOTFSM_GO_GO_MASK);
    }
    VPRINTF(LOW, "MCU: Set BootFSM GO\n");

    ////////////////////////////////////
    // Mailbox command test
    //

    // MBOX: Wait for ready_for_fw
    while(!(lsu_read_32(SOC_SOC_IFC_REG_CPTRA_FLOW_STATUS) & SOC_IFC_REG_CPTRA_FLOW_STATUS_READY_FOR_FW_MASK)) {
        for (uint8_t ii = 0; ii < 16; ii++) {
            __asm__ volatile ("nop"); // Sleep loop as "nop"
        }
    }
    VPRINTF(LOW, "MCU: Ready for FW\n");

    // MBOX: Setup valid AXI ID
    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_VALID_AXI_ID_0, 0);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_VALID_AXI_ID_1, 1);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_VALID_AXI_ID_2, 2);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_VALID_AXI_ID_3, 3);
    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_0, SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_0_LOCK_MASK);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_1, SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_1_LOCK_MASK);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_2, SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_2_LOCK_MASK);
//    lsu_write_32(SOC_SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_3, SOC_IFC_REG_CPTRA_MBOX_AXI_ID_LOCK_3_LOCK_MASK);
    VPRINTF(LOW, "MCU: Configured MBOX Valid AXI ID\n");

    // MBOX: Acquire lock
    while((lsu_read_32(SOC_MBOX_CSR_MBOX_LOCK) & MBOX_CSR_MBOX_LOCK_LOCK_MASK));
    VPRINTF(LOW, "MCU: Mbox lock acquired\n");

    // MBOX: Write CMD
    lsu_write_32(SOC_MBOX_CSR_MBOX_CMD, 0xFADECAFE | MBOX_CMD_FIELD_RESP_MASK); // Resp required

    // MBOX: Write DLEN
    lsu_write_32(SOC_MBOX_CSR_MBOX_DLEN, 64);

    // MBOX: Write datain
    for (uint32_t ii = 0; ii < mbox_dlen/4; ii++) {
        lsu_write_32(SOC_MBOX_CSR_MBOX_DATAIN, mbox_data[ii]);
    }

    // MBOX: Execute
    lsu_write_32(SOC_MBOX_CSR_MBOX_EXECUTE, MBOX_CSR_MBOX_EXECUTE_EXECUTE_MASK);
    VPRINTF(LOW, "MCU: Mbox execute\n");

    // MBOX: Poll status
    while(((lsu_read_32(SOC_MBOX_CSR_MBOX_STATUS) & MBOX_CSR_MBOX_STATUS_STATUS_MASK) >> MBOX_CSR_MBOX_STATUS_STATUS_LOW) != DATA_READY) {
        for (uint8_t ii = 0; ii < 16; ii++) {
            __asm__ volatile ("nop"); // Sleep loop as "nop"
        }
    }
    VPRINTF(LOW, "MCU: Mbox response ready\n");

    // MBOX: Read response data length
    mbox_resp_dlen = lsu_read_32(SOC_MBOX_CSR_MBOX_DLEN);

    // MBOX: Read dataout
    for (uint32_t ii = 0; ii < (mbox_resp_dlen/4 + (mbox_resp_dlen%4 ? 1 : 0)); ii++) {
        mbox_resp_data = lsu_read_32(SOC_MBOX_CSR_MBOX_DATAOUT);
    }
    VPRINTF(LOW, "MCU: Mbox response received\n");

    // MBOX: Clear Execute
    lsu_write_32(SOC_MBOX_CSR_MBOX_EXECUTE, 0);
    VPRINTF(LOW, "MCU: Mbox execute clear\n");


    // ////////////////////////////////////
    // // I3C Bringup
    // // tb.reg_map.I3C_EC.SOCMGMTIF.T_R_REG = 2
    // // tb.reg_map.I3C_EC.SOCMGMTIF.T_HD_DAT_REG = 10 
    // // tb.reg_map.I3C_EC.SOCMGMTIF.T_SU_DAT_REG =  10
    // // tb.reg_map.I3C_EC.STDBYCTRLMODE.STBY_CR_CONTROL.STBY_CR_ENABLE_INIT = 2
    // // tb.reg_map.I3C_EC.STDBYCTRLMODE.STBY_CR_CONTROL.TARGET_XACT_ENABLE = 1
    // // tb.reg_map.I3CBASE.HC_CONTROL.BUS_ENABLE = 1
    
    VPRINTF(LOW, "MCU: Bringing up I3C Interface .. Started \n");

    lsu_write_32( SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_R_REG, 2);
    lsu_write_32( SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_HD_DAT_REG , 10);
    lsu_write_32( SOC_I3CCSR_I3C_EC_SOCMGMTIF_T_SU_DAT_REG, 10);

    i3c_reg_data = lsu_read_32( SOC_I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL);
    i3c_reg_data = 2 << I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL_STBY_CR_ENABLE_INIT_LOW | i3c_reg_data;
    i3c_reg_data = 1 << I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL_TARGET_XACT_ENABLE_LOW | i3c_reg_data;
    lsu_write_32( SOC_I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL, i3c_reg_data);

    i3c_reg_data = lsu_read_32( SOC_I3CCSR_I3CBASE_HC_CONTROL);
    i3c_reg_data = 1 << I3CCSR_I3CBASE_HC_CONTROL_BUS_ENABLE_LOW | i3c_reg_data;
    lsu_write_32( SOC_I3CCSR_I3CBASE_HC_CONTROL, i3c_reg_data);

    VPRINTF(LOW, "MCU: Bringing up I3C Interface .. Completed \n");

    // lsu_write_32( I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL_STBY_CR_ENABLE_INIT_MASK, 2);
    // lsu_write_32( I3CCSR_I3C_EC_STDBYCTRLMODE_STBY_CR_CONTROL_TARGET_XACT_ENABLE_MASK, 1);
    // lsu_write_32( I3CCSR_I3CBASE_HC_CONTROL_BUS_ENABLE_MASK , 1);
    
    SEND_STDOUT_CTRL(0xff);

}
