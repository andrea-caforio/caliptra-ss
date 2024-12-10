/*
 * |-----------------------------------------------------------------------|
 * |                                                                       |
 * |   Copyright Avery Design Systems, Inc. 2017.			   |
 * |     All Rights Reserved.       Licensed Software.		           |
 * |                                                                       |
 * |                                                                       |
 * | THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF AVERY DESIGN SYSTEMS   |
 * | The copyright notice above does not evidence any actual or intended   |
 * | publication of such source code.				           |
 * |                                                                       |
 * |-----------------------------------------------------------------------|
 */

`ifndef ai3c_intf_sv
`define ai3c_intf_sv

interface ai3c_intf #(
    parameter int LANE_NUM = 1
    ) (inout wire [LANE_NUM - 1: 0] sda_and, inout wire scl_and);

    logic [LANE_NUM - 1: 0] sda;
    logic                   scl;
    logic                   sda_en;
    wire [LANE_NUM - 1: 0]  sda_out;
    logic                   is_od_mode; // open drain mode
   
    assign sda_and      = sda_out;
    assign scl_and      = scl;
`ifdef AI3C_SDA_EN
    assign sda_out      = sda_en ? (is_od_mode ? (sda[0] ? 1'bz : 0) : sda) : 1'bz;  
`else
    assign sda_out      = sda;  
`endif

    // // give default high
    // initial begin
    //     sda        = '1;
	// scl        = 1;
	// sda_en     = 0;
	// is_od_mode = 0;
    // end

    // -- internal debug -- //
    logic [ 7:0] sdr_tx_dw;    // VAR: Use for debugging SDR mode sending data
    logic [ 7:0] sdr_rx_dw;    // VAR: Use for debugging SDR mode receiving data
    logic [ 1:0] hdr_ddr_stat; // VAR: Use for debugging DDR mode transfer status on waveform
    logic [ 1:0] hdr_tri_stat; // VAR: Use for debugging TSP mode transfer status on waveform
    logic [15:0] hdr_tx_dw;    // VAR: Use for debugging DDR mode sending data
    logic [15:0] hdr_rx_dw;    // VAR: Use for debugging DDR mode receiving data
    logic [ 1:0] bt_blk_stat;  // VAR: Use for debugging BT mode transfer status on waveform  
    logic [ 7:0] bt_tx_byte;   // VAR: Use for debugging BT mode sending data   
    logic [ 7:0] bt_rx_byte;   // VAR: Use for debugging BT mode receiving data 

endinterface

// Use for I3CHCI 
interface ai3c_hci_intf();
    logic intr;
endinterface

`endif   
