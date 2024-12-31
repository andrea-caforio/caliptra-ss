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

module mci_top 
    import mci_reg_pkg::*
    #(
    parameter MCU_SRAM_SIZE_KB = 1024 // FIXME - write assertion ensuring this size 
                                      // is compatible with the MCU SRAM IF parameters
    )
    (
    input logic clk,

    // MCI Resets
    input logic mci_rst_b,

    // MCI AXI Interface
    axi_if.w_sub s_axi_w_if,
    axi_if.r_sub s_axi_r_if,
    
    // MCU SRAM Interface
    mci_mcu_sram_if.request mci_mcu_sram_req_if 

    );

    localparam AXI_ADDR_WIDTH = s_axi_w_if.AW;
    localparam AXI_DATA_WIDTH = s_axi_w_if.DW;
    localparam AXI_USER_WIDTH = s_axi_w_if.UW;
    localparam AXI_ID_WIDTH   = s_axi_w_if.IW;
    
    mci_reg__out_t mci_reg_hwif_out;



// Caliptra internal fabric interface for MCU SRAM 
// Address width is set to AXI_ADDR_WIDTH and MCU SRAM
// will mask out upper bits that are "don't care"
cif_if #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH)
    ,.DATA_WIDTH(AXI_DATA_WIDTH)
    ,.ID_WIDTH(AXI_ID_WIDTH)
    ,.USER_WIDTH(AXI_USER_WIDTH)
) mcu_sram_req_if(
    .clk, 
    .rst_b(mci_rst_b));

// Caliptra internal fabric interface for MCI REG 
// Address width is set to AXI_ADDR_WIDTH and MCI REG
// will mask out upper bits that are "don't care"
cif_if #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH)
    ,.DATA_WIDTH(AXI_DATA_WIDTH)
    ,.ID_WIDTH(AXI_ID_WIDTH)
    ,.USER_WIDTH(AXI_USER_WIDTH)
) mci_reg_req_if(
    .clk, 
    .rst_b(mci_rst_b));

//AXI Interface
//This module contains the logic for interfacing with the SoC over the AXI Interface
//The SoC sends read and write requests using AXI Protocol
//This wrapper decodes that protocol, collapses the full-duplex protocol to
// simplex, and issues requests to the MIC decode block
mci_axi_sub_top #( // FIXME: Should SUB and MAIN be under same AXI_TOP module?
    .MCU_SRAM_SIZE_KB(MCU_SRAM_SIZE_KB),
    .MBOX0_SIZE_KB (4),     // FIXME
    .MBOX1_SIZE_KB  (4)     // FIXME
) i_mci_axi_sub_top (
    // MCI clk
    .clk  (clk     ),

    // MCI Resets
    .rst_b(mci_rst_b), // FIXME: Need to sync reset

    // AXI INF
    .s_axi_w_if(s_axi_w_if),
    .s_axi_r_if(s_axi_r_if),

    // MCI REG Interface
    .mci_reg_req_if( mci_reg_req_if.request ),

    // MCU SRAM Interface
    .mcu_sram_req_if( mcu_sram_req_if.request )
);


// MCU SRAM
// Translates requests from the AXI SUB and sends them to the MCU SRAM.
mci_mcu_sram_ctrl #(
    .MCU_SRAM_SIZE_KB(MCU_SRAM_SIZE_KB)
) i_mci_mcu_sram_ctrl (
    // MCI clk
    .clk    (clk),

    // MCI Resets
    .rst_b (mci_rst_b), // FIXME: Need to sync reset

    // Interface
    .fw_sram_exec_region_size('0), // FIXME

    // Caliptra internal fabric response interface
    .cif_resp_if (mcu_sram_req_if.response),

    // AXI users
    .strap_mcu_lsu_axi_user('0),   // FIXME
    .strap_mcu_ifu_axi_user('0),   // FIXME
    .strap_clp_axi_user('0),   // FIXME

    // Access lock interface
    .mcu_sram_fw_exec_region_lock('0),  // FIXME

    // ECC Status
    .sram_single_ecc_error(),   // FIXME
    .sram_double_ecc_error(),   // FIXME

    // Interface with SRAM
    .mci_mcu_sram_req_if(mci_mcu_sram_req_if)
);

// MCI Reg
// MCI CSR bank
mci_top i_mci_top (
    .clk    (clk),

    // MCI Resets
    .mci_rst_b      (mci_rst_b),// FIXME: Need to sync reset
    .mcu_rst_b      ('0),       // FIXME: is this really needed?
    .mci_pwrgood    ('0),       // FIXME: need to add

    // REG HWIF signals
    .mci_reg_hwif_out (mci_reg_hwif_out),
    
    // Caliptra internal fabric response interface
    .cif_resp_if (mci_reg_req_if.response),

);



endmodule
