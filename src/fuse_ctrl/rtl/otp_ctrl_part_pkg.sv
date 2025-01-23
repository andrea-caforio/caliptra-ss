// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Package partition metadata.
//
package otp_ctrl_part_pkg;

  import caliptra_prim_util_pkg::vbits;
  import otp_ctrl_reg_pkg::*;
  import otp_ctrl_pkg::*;

  ////////////////////////////////////
  // Scrambling Constants and Types //
  ////////////////////////////////////

  parameter int NumScrmblKeys = 9;
  parameter int NumDigestSets = 1;

  parameter int ScrmblKeySelWidth = vbits(NumScrmblKeys);
  parameter int DigestSetSelWidth = vbits(NumDigestSets);
  parameter int ConstSelWidth = (ScrmblKeySelWidth > DigestSetSelWidth) ?
                                ScrmblKeySelWidth :
                                DigestSetSelWidth;

  typedef enum logic [ConstSelWidth-1:0] {
    StandardMode,
    ChainedMode
  } digest_mode_e;

  typedef logic [NumScrmblKeys-1:0][ScrmblKeyWidth-1:0] key_array_t;
  typedef logic [NumDigestSets-1:0][ScrmblKeyWidth-1:0] digest_const_array_t;
  typedef logic [NumDigestSets-1:0][ScrmblBlockWidth-1:0] digest_iv_array_t;

  typedef enum logic [ConstSelWidth-1:0] {
    SecretManufKey,
    SecretProdKey0,
    SecretProdKey1,
    SecretProdKey2,
    SecretProdKey3,
    SecretLifeCycleUnlockKey,
    SecretLifeCycleManufKey,
    SecretLifeCycleProdKey,
    SecretLifeCycleRMAKey
  } key_sel_e;

  typedef enum logic [ConstSelWidth-1:0] {
    CnstyDigest
  } digest_sel_e;

  // SEC_CM: SECRET.MEM.SCRAMBLE
  parameter key_array_t RndCnstKey = {
    128'h4A22D4B78FE0266FBEE3958332F2939B,
    128'h90C7F21F6224F027F98C48B1F9377284,
    128'hB7474D640F8A7F5D60822E1FAEC5C72,
    128'h277195FC471E4B26B6641214B61D1B43,
    128'h4D5A89AA9109294AE048B657396B4B83,
    128'hBEAD91D5FA4E09150E95F517CB98955B,
    128'h85A9E830BC059BA9286D6E2856A05CC3,
    128'hEFFA6D736C5EFF49AE7B70F9C46E5A62,
    128'h3BA121C5E097DDEB7768B4C666E9C3DA
  };

  // SEC_CM: PART.MEM.DIGEST
  // Note: digest set 0 is used for computing the partition digests. Constants at
  // higher indices are used to compute the scrambling keys.
  parameter digest_const_array_t RndCnstDigestConst = {
    128'hCF7A50A9A91EF7F7B3A5B4421F462370
  };

  parameter digest_iv_array_t RndCnstDigestIV = {
    64'h63B9485A3856C417
  };

  parameter digest_const_array_t RndCnstDigestConstDefault = {
    128'h4A22D4B78FE0266FBEE3958332F2939B,
    128'hD60822E1FAEC5C7290C7F21F6224F027,
    128'h277195FC471E4B26B6641214B61D1B43,
    128'hE95F517CB98955B4D5A89AA9109294A
  };

  parameter digest_iv_array_t RndCnstDigestIVDefault = {
    64'hF98C48B1F9377284,
    64'hB7474D640F8A7F5,
    64'hE048B657396B4B83,
    64'hBEAD91D5FA4E0915
  };

  /////////////////////////////////////
  // Typedefs for Partition Metadata //
  /////////////////////////////////////

  typedef enum logic [1:0] {
    Unbuffered,
    Buffered,
    LifeCycle
  } part_variant_e;

  typedef struct packed {
    part_variant_e variant;
    // Offset and size within the OTP array, in Bytes.
    logic [OtpByteAddrWidth-1:0] offset;
    logic [OtpByteAddrWidth-1:0] size;
    // Key index to use for scrambling.
    key_sel_e key_sel;
    // Attributes
    logic secret;           // Whether the partition is secret (and hence scrambled)
    logic sw_digest;        // Whether the partition has a software digest
    logic hw_digest;        // Whether the partition has a hardware digest
    logic write_lock;       // Whether the partition is write lockable (via digest)
    logic read_lock;        // Whether the partition is read lockable (via digest)
    logic integrity;        // Whether the partition is integrity protected
    logic iskeymgr_creator; // Whether the partition has any creator key material
    logic iskeymgr_owner;   // Whether the partition has any owner key material
  } part_info_t;

  parameter part_info_t PartInfoDefault = '{
      variant:          Unbuffered,
      offset:           '0,
      size:             OtpByteAddrWidth'('hFF),
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b0,
      hw_digest:        1'b0,
      write_lock:       1'b0,
      read_lock:        1'b0,
      integrity:        1'b0,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
  };

  ////////////////////////
  // Partition Metadata //
  ////////////////////////

  localparam part_info_t PartInfo [NumPart] = '{
    // SECRET_MANUF_PARTITION
    '{
      variant:          Buffered,
      offset:           11'd0,
      size:             72,
      key_sel:          SecretManufKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_PROD_PARTITION_0
    '{
      variant:          Buffered,
      offset:           11'd72,
      size:             16,
      key_sel:          SecretProdKey0,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_PROD_PARTITION_1
    '{
      variant:          Buffered,
      offset:           11'd88,
      size:             16,
      key_sel:          SecretProdKey1,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_PROD_PARTITION_2
    '{
      variant:          Buffered,
      offset:           11'd104,
      size:             16,
      key_sel:          SecretProdKey2,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_PROD_PARTITION_3
    '{
      variant:          Buffered,
      offset:           11'd120,
      size:             16,
      key_sel:          SecretProdKey3,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SW_MANUF_PARTITION
    '{
      variant:          Unbuffered,
      offset:           11'd136,
      size:             1120,
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b1,
      hw_digest:        1'b0,
      write_lock:       1'b1,
      read_lock:        1'b0,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SW_PROD_PARTITION
    '{
      variant:          Unbuffered,
      offset:           11'd1256,
      size:             408,
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b1,
      hw_digest:        1'b0,
      write_lock:       1'b1,
      read_lock:        1'b0,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_LC_UNLOCK_PARTITION
    '{
      variant:          Buffered,
      offset:           11'd1664,
      size:             136,
      key_sel:          SecretLifeCycleUnlockKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_LC_MANUF_PARTITION
    '{
      variant:          Buffered,
      offset:           11'd1800,
      size:             24,
      key_sel:          SecretLifeCycleManufKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_LC_PROD_PARTITION
    '{
      variant:          Buffered,
      offset:           11'd1824,
      size:             24,
      key_sel:          SecretLifeCycleProdKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_LC_RMA_PARTITION
    '{
      variant:          Buffered,
      offset:           11'd1848,
      size:             24,
      key_sel:          SecretLifeCycleRMAKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SVN_PARTITION
    '{
      variant:          Unbuffered,
      offset:           11'd1872,
      size:             24,
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b0,
      hw_digest:        1'b0,
      write_lock:       1'b0,
      read_lock:        1'b0,
      integrity:        1'b0,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // VENDOR_TEST_PARTITION
    '{
      variant:          Unbuffered,
      offset:           11'd1896,
      size:             64,
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b1,
      hw_digest:        1'b0,
      write_lock:       1'b1,
      read_lock:        1'b0,
      integrity:        1'b0,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // LIFE_CYCLE
    '{
      variant:          LifeCycle,
      offset:           11'd1960,
      size:             88,
      key_sel:          key_sel_e'('0),
      secret:           1'b0,
      sw_digest:        1'b0,
      hw_digest:        1'b0,
      write_lock:       1'b0,
      read_lock:        1'b0,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    }
  };

  typedef enum {
    SecretManufPartitionIdx,
    SecretProdPartition0Idx,
    SecretProdPartition1Idx,
    SecretProdPartition2Idx,
    SecretProdPartition3Idx,
    SwManufPartitionIdx,
    SwProdPartitionIdx,
    SecretLcUnlockPartitionIdx,
    SecretLcManufPartitionIdx,
    SecretLcProdPartitionIdx,
    SecretLcRmaPartitionIdx,
    SvnPartitionIdx,
    VendorTestPartitionIdx,
    LifeCycleIdx,
    // These are not "real partitions", but in terms of implementation it is convenient to
    // add these at the end of certain arrays.
    DaiIdx,
    LciIdx,
    // Number of agents is the last idx+1.
    NumAgentsIdx
  } part_idx_e;

  parameter int NumAgents = int'(NumAgentsIdx);

  // Breakout types for easier access of individual items.
  typedef struct packed {
    logic [63:0] secret_manuf_partition_digest;
    logic [511:0] uds_seed;
  } otp_secret_manuf_partition_data_t;

  // default value used for intermodule
  parameter otp_secret_manuf_partition_data_t OTP_SECRET_MANUF_PARTITION_DATA_DEFAULT = '{
    secret_manuf_partition_digest: 64'hF87BED95CFBA3727,
    uds_seed: 512'hFFF698183664DC7EDF3888886BD10DC67ABB319BDA0529AE40119A3C6E63CDF358840E458E4029A6B5AC1F53D00A08C3B28B5C0FEE5F4C02711D135F59A50322
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_0_digest;
    logic [63:0] field_entropy_0;
  } otp_secret_prod_partition_0_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_0_data_t OTP_SECRET_PROD_PARTITION_0_DATA_DEFAULT = '{
    secret_prod_partition_0_digest: 64'hBBF4A76885E754F2,
    field_entropy_0: 64'hB6711DB6F5D40A37
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_1_digest;
    logic [63:0] field_entropy_1;
  } otp_secret_prod_partition_1_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_1_data_t OTP_SECRET_PROD_PARTITION_1_DATA_DEFAULT = '{
    secret_prod_partition_1_digest: 64'hBE193854E9CA60A0,
    field_entropy_1: 64'hDBC827839FE2DCC2
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_2_digest;
    logic [63:0] field_entropy_2;
  } otp_secret_prod_partition_2_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_2_data_t OTP_SECRET_PROD_PARTITION_2_DATA_DEFAULT = '{
    secret_prod_partition_2_digest: 64'hC469C593E5DC0DA8,
    field_entropy_2: 64'h7E17D06B5D4E0DDD
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_3_digest;
    logic [63:0] field_entropy_3;
  } otp_secret_prod_partition_3_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_3_data_t OTP_SECRET_PROD_PARTITION_3_DATA_DEFAULT = '{
    secret_prod_partition_3_digest: 64'h8CBBAD02BB4CA928,
    field_entropy_3: 64'hDBB9844327F20FB5
  };
  typedef struct packed {
    // This reuses the same encoding as the life cycle signals for indicating valid status.
    lc_ctrl_pkg::lc_tx_t valid;
    otp_secret_prod_partition_3_data_t secret_prod_partition_3_data;
    otp_secret_prod_partition_2_data_t secret_prod_partition_2_data;
    otp_secret_prod_partition_1_data_t secret_prod_partition_1_data;
    otp_secret_prod_partition_0_data_t secret_prod_partition_0_data;
    otp_secret_manuf_partition_data_t secret_manuf_partition_data;
  } otp_broadcast_t;

  // default value for intermodule
  parameter otp_broadcast_t OTP_BROADCAST_DEFAULT = '{
    valid: lc_ctrl_pkg::Off,
    secret_prod_partition_3_data: OTP_SECRET_PROD_PARTITION_3_DATA_DEFAULT,
    secret_prod_partition_2_data: OTP_SECRET_PROD_PARTITION_2_DATA_DEFAULT,
    secret_prod_partition_1_data: OTP_SECRET_PROD_PARTITION_1_DATA_DEFAULT,
    secret_prod_partition_0_data: OTP_SECRET_PROD_PARTITION_0_DATA_DEFAULT,
    secret_manuf_partition_data: OTP_SECRET_MANUF_PARTITION_DATA_DEFAULT
  };


  // OTP invalid partition default for buffered partitions.
  parameter logic [16383:0] PartInvDefault = 16384'({
    704'({
      320'h4947DD361344767A0340A5B93BB19342E29749216775E8A515F164D7930C9D1920440F25BB053FB5,
      384'h851B80674A2B6FBE93B61DE417B9FB339605F051E74379CBCC6596C7174EBA643E725E464F593C87A445C3C29F71A256
    }),
    512'({
      64'h60BAE4A876D70627,
      192'h0, // unallocated space
      256'h0
    }),
    192'({
      32'h0, // unallocated space
      128'h0,
      32'h0
    }),
    192'({
      64'h2DCDD92FA5B24BF3,
      128'hE817E760B27AE937BFCDF15A3429452A
    }),
    192'({
      64'h3BF7D79A9FF747F6,
      128'h1E46311FD36D95401136C663A36C3E3
    }),
    192'({
      64'h41837480464544A1,
      128'h315FD2B871D88819A0D1E90E8C9FDDFA
    }),
    1088'({
      64'h6FDFE93D3146B0F,
      128'h688098A43C33459F0279FC51CC7C626E,
      128'hD3D58610F4851667D68C96F0B3D1FEED,
      128'h2C0DBDDEDF7A854D5E58D0AA97A0F8F6,
      128'h2A4D8B51F5D41C8AD0BAC511D08ECE0E,
      128'h1C752824C7DDC89694CD3DED94B57819,
      128'h426D99D374E699CAE00E9680BD9B7029,
      128'h234729143F97B62A55D0320379A0D260,
      128'hD396D1CE085BDC31105733EAA3880C5A
    }),
    3264'({
      64'h67BBE3B4555DF35C,
      2736'h0, // unallocated space
      8'h0,
      32'h0,
      32'h0,
      384'h0,
      8'h0
    }),
    8960'({
      64'hAA3F4C71234F097C,
      2728'h0, // unallocated space
      256'h0,
      384'h0,
      4096'h0,
      128'h0,
      16'h0,
      128'h0,
      768'h0,
      8'h0,
      384'h0
    }),
    128'({
      64'h8CBBAD02BB4CA928,
      64'hDBB9844327F20FB5
    }),
    128'({
      64'hC469C593E5DC0DA8,
      64'h7E17D06B5D4E0DDD
    }),
    128'({
      64'hBE193854E9CA60A0,
      64'hDBC827839FE2DCC2
    }),
    128'({
      64'hBBF4A76885E754F2,
      64'hB6711DB6F5D40A37
    }),
    576'({
      64'hF87BED95CFBA3727,
      512'hFFF698183664DC7EDF3888886BD10DC67ABB319BDA0529AE40119A3C6E63CDF358840E458E4029A6B5AC1F53D00A08C3B28B5C0FEE5F4C02711D135F59A50322
    })});

  ///////////////////////////////////////////////
  // Parameterized Assignment Helper Functions //
  ///////////////////////////////////////////////

  function automatic otp_ctrl_core_hw2reg_t named_reg_assign(
      logic [NumPart-1:0][ScrmblBlockWidth-1:0] part_digest);
    otp_ctrl_core_hw2reg_t hw2reg;
    logic unused_sigs;
    unused_sigs = ^part_digest;
    hw2reg = '0;
    hw2reg.secret_manuf_partition_digest = part_digest[SecretManufPartitionIdx];
    hw2reg.secret_prod_partition_0_digest = part_digest[SecretProdPartition0Idx];
    hw2reg.secret_prod_partition_1_digest = part_digest[SecretProdPartition1Idx];
    hw2reg.secret_prod_partition_2_digest = part_digest[SecretProdPartition2Idx];
    hw2reg.secret_prod_partition_3_digest = part_digest[SecretProdPartition3Idx];
    hw2reg.sw_manuf_partition_digest = part_digest[SwManufPartitionIdx];
    hw2reg.sw_prod_partition_digest = part_digest[SwProdPartitionIdx];
    hw2reg.secret_lc_unlock_partition_digest = part_digest[SecretLcUnlockPartitionIdx];
    hw2reg.secret_lc_manuf_partition_digest = part_digest[SecretLcManufPartitionIdx];
    hw2reg.secret_lc_prod_partition_digest = part_digest[SecretLcProdPartitionIdx];
    hw2reg.secret_lc_rma_partition_digest = part_digest[SecretLcRmaPartitionIdx];
    hw2reg.vendor_test_partition_digest = part_digest[VendorTestPartitionIdx];
    return hw2reg;
  endfunction : named_reg_assign

  function automatic part_access_t [NumPart-1:0] named_part_access_pre(
      otp_ctrl_core_reg2hw_t reg2hw);
    part_access_t [NumPart-1:0] part_access_pre;
    logic unused_sigs;
    unused_sigs = ^reg2hw;
    // Default (this will be overridden by partition-internal settings).
    part_access_pre = {{32'(2*NumPart)}{caliptra_prim_mubi_pkg::MuBi8False}};
    // Note: these could be made a MuBi CSRs in the future.
    // The main thing that is missing right now is proper support for W0C.
    // SW_MANUF_PARTITION
    if (!reg2hw.sw_manuf_partition_read_lock) begin
      part_access_pre[SwManufPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // SW_PROD_PARTITION
    if (!reg2hw.sw_prod_partition_read_lock) begin
      part_access_pre[SwProdPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // SVN_PARTITION
    if (!reg2hw.svn_partition_read_lock) begin
      part_access_pre[SvnPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // VENDOR_TEST_PARTITION
    if (!reg2hw.vendor_test_partition_read_lock) begin
      part_access_pre[VendorTestPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    return part_access_pre;
  endfunction : named_part_access_pre

  function automatic otp_broadcast_t named_broadcast_assign(
      logic [NumPart-1:0] part_init_done,
      logic [$bits(PartInvDefault)/8-1:0][7:0] part_buf_data);
    otp_broadcast_t otp_broadcast;
    logic valid, unused;
    unused = 1'b0;
    valid = 1'b1;
    // SECRET_MANUF_PARTITION
    valid &= part_init_done[SecretManufPartitionIdx];
    otp_broadcast.secret_manuf_partition_data = otp_secret_manuf_partition_data_t'(part_buf_data[SecretManufPartitionOffset +: SecretManufPartitionSize]);
    // SECRET_PROD_PARTITION_0
    valid &= part_init_done[SecretProdPartition0Idx];
    otp_broadcast.secret_prod_partition_0_data = otp_secret_prod_partition_0_data_t'(part_buf_data[SecretProdPartition0Offset +: SecretProdPartition0Size]);
    // SECRET_PROD_PARTITION_1
    valid &= part_init_done[SecretProdPartition1Idx];
    otp_broadcast.secret_prod_partition_1_data = otp_secret_prod_partition_1_data_t'(part_buf_data[SecretProdPartition1Offset +: SecretProdPartition1Size]);
    // SECRET_PROD_PARTITION_2
    valid &= part_init_done[SecretProdPartition2Idx];
    otp_broadcast.secret_prod_partition_2_data = otp_secret_prod_partition_2_data_t'(part_buf_data[SecretProdPartition2Offset +: SecretProdPartition2Size]);
    // SECRET_PROD_PARTITION_3
    valid &= part_init_done[SecretProdPartition3Idx];
    otp_broadcast.secret_prod_partition_3_data = otp_secret_prod_partition_3_data_t'(part_buf_data[SecretProdPartition3Offset +: SecretProdPartition3Size]);
    // SW_MANUF_PARTITION
    unused ^= ^{part_init_done[SwManufPartitionIdx],
                part_buf_data[SwManufPartitionOffset +: SwManufPartitionSize]};
    // SW_PROD_PARTITION
    unused ^= ^{part_init_done[SwProdPartitionIdx],
                part_buf_data[SwProdPartitionOffset +: SwProdPartitionSize]};
    // SECRET_LC_UNLOCK_PARTITION
    unused ^= ^{part_init_done[SecretLcUnlockPartitionIdx],
                part_buf_data[SecretLcUnlockPartitionOffset +: SecretLcUnlockPartitionSize]};
    // SECRET_LC_MANUF_PARTITION
    unused ^= ^{part_init_done[SecretLcManufPartitionIdx],
                part_buf_data[SecretLcManufPartitionOffset +: SecretLcManufPartitionSize]};
    // SECRET_LC_PROD_PARTITION
    unused ^= ^{part_init_done[SecretLcProdPartitionIdx],
                part_buf_data[SecretLcProdPartitionOffset +: SecretLcProdPartitionSize]};
    // SECRET_LC_RMA_PARTITION
    unused ^= ^{part_init_done[SecretLcRmaPartitionIdx],
                part_buf_data[SecretLcRmaPartitionOffset +: SecretLcRmaPartitionSize]};
    // SVN_PARTITION
    unused ^= ^{part_init_done[SvnPartitionIdx],
                part_buf_data[SvnPartitionOffset +: SvnPartitionSize]};
    // VENDOR_TEST_PARTITION
    unused ^= ^{part_init_done[VendorTestPartitionIdx],
                part_buf_data[VendorTestPartitionOffset +: VendorTestPartitionSize]};
    // LIFE_CYCLE
    unused ^= ^{part_init_done[LifeCycleIdx],
                part_buf_data[LifeCycleOffset +: LifeCycleSize]};
    otp_broadcast.valid = lc_ctrl_pkg::lc_tx_bool_to_lc_tx(valid);
    return otp_broadcast;
  endfunction : named_broadcast_assign

  function automatic otp_keymgr_key_t named_keymgr_key_assign(
      logic [NumPart-1:0][ScrmblBlockWidth-1:0] part_digest,
      logic [$bits(PartInvDefault)/8-1:0][7:0] part_buf_data,
      lc_ctrl_pkg::lc_tx_t lc_seed_hw_rd_en);
    otp_keymgr_key_t otp_keymgr_key;
    logic valid, unused;
    unused = 1'b0;
    // For now we use a fixed struct type here so that the
    // interface to the keymgr remains stable. The type contains
    // a superset of all options, so we have to initialize it to '0 here.
    otp_keymgr_key = '0;
    // SECRET_MANUF_PARTITION
    unused ^= ^{part_digest[SecretManufPartitionIdx],
                part_buf_data[SecretManufPartitionOffset +: SecretManufPartitionSize]};
    // SECRET_PROD_PARTITION_0
    unused ^= ^{part_digest[SecretProdPartition0Idx],
                part_buf_data[SecretProdPartition0Offset +: SecretProdPartition0Size]};
    // SECRET_PROD_PARTITION_1
    unused ^= ^{part_digest[SecretProdPartition1Idx],
                part_buf_data[SecretProdPartition1Offset +: SecretProdPartition1Size]};
    // SECRET_PROD_PARTITION_2
    unused ^= ^{part_digest[SecretProdPartition2Idx],
                part_buf_data[SecretProdPartition2Offset +: SecretProdPartition2Size]};
    // SECRET_PROD_PARTITION_3
    unused ^= ^{part_digest[SecretProdPartition3Idx],
                part_buf_data[SecretProdPartition3Offset +: SecretProdPartition3Size]};
    // SW_MANUF_PARTITION
    unused ^= ^{part_digest[SwManufPartitionIdx],
                part_buf_data[SwManufPartitionOffset +: SwManufPartitionSize]};
    // SW_PROD_PARTITION
    unused ^= ^{part_digest[SwProdPartitionIdx],
                part_buf_data[SwProdPartitionOffset +: SwProdPartitionSize]};
    // SECRET_LC_UNLOCK_PARTITION
    unused ^= ^{part_digest[SecretLcUnlockPartitionIdx],
                part_buf_data[SecretLcUnlockPartitionOffset +: SecretLcUnlockPartitionSize]};
    // SECRET_LC_MANUF_PARTITION
    unused ^= ^{part_digest[SecretLcManufPartitionIdx],
                part_buf_data[SecretLcManufPartitionOffset +: SecretLcManufPartitionSize]};
    // SECRET_LC_PROD_PARTITION
    unused ^= ^{part_digest[SecretLcProdPartitionIdx],
                part_buf_data[SecretLcProdPartitionOffset +: SecretLcProdPartitionSize]};
    // SECRET_LC_RMA_PARTITION
    unused ^= ^{part_digest[SecretLcRmaPartitionIdx],
                part_buf_data[SecretLcRmaPartitionOffset +: SecretLcRmaPartitionSize]};
    // SVN_PARTITION
    unused ^= ^{part_digest[SvnPartitionIdx],
                part_buf_data[SvnPartitionOffset +: SvnPartitionSize]};
    // VENDOR_TEST_PARTITION
    unused ^= ^{part_digest[VendorTestPartitionIdx],
                part_buf_data[VendorTestPartitionOffset +: VendorTestPartitionSize]};
    // LIFE_CYCLE
    unused ^= ^{part_digest[LifeCycleIdx],
                part_buf_data[LifeCycleOffset +: LifeCycleSize]};
    unused ^= valid;
    return otp_keymgr_key;
  endfunction : named_keymgr_key_assign

endpackage : otp_ctrl_part_pkg
