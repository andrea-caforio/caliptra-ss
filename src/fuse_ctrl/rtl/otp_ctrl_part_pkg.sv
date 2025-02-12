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

  parameter int NumScrmblKeys = 8;
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
    SecretTestUnlockKey,
    SecretManufKey,
    SecretProdKey0,
    SecretProdKey1,
    SecretProdKey2,
    SecretProdKey3,
    VendorSecretProdKey,
    SecretLifeCycleTransitionKey
  } key_sel_e;

  typedef enum logic [ConstSelWidth-1:0] {
    CnstyDigest
  } digest_sel_e;

  // SEC_CM: SECRET.MEM.SCRAMBLE
  parameter key_array_t RndCnstKey = {
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
    128'hBEE3958332F2939B63B9485A3856C417
  };

  parameter digest_iv_array_t RndCnstDigestIV = {
    64'h4A22D4B78FE0266F
  };

  parameter digest_const_array_t RndCnstDigestConstDefault = {
    128'hBEE3958332F2939B63B9485A3856C417
  };

  parameter digest_iv_array_t RndCnstDigestIVDefault = {
    64'h4A22D4B78FE0266F
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
    // SECRET_TEST_UNLOCK_PARTITION
    '{
      variant:          Buffered,
      offset:           12'd0,
      size:             24,
      key_sel:          SecretTestUnlockKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // SECRET_MANUF_PARTITION
    '{
      variant:          Buffered,
      offset:           12'd24,
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
      offset:           12'd96,
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
      offset:           12'd112,
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
      offset:           12'd128,
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
      offset:           12'd144,
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
      offset:           12'd160,
      size:             1104,
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
    // SECRET_LC_TRANSITION_PARTITION
    '{
      variant:          Buffered,
      offset:           12'd1264,
      size:             184,
      key_sel:          SecretLifeCycleTransitionKey,
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
      offset:           12'd1448,
      size:             40,
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
      offset:           12'd1488,
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
    // VENDOR_KEYS_MANUF_PARTITION
    '{
      variant:          Unbuffered,
      offset:           12'd1552,
      size:             56,
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
    // VENDOR_KEYS_PROD_PARTITION
    '{
      variant:          Unbuffered,
      offset:           12'd1608,
      size:             896,
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
    // VENDOR_SECRET_PROD_PARTITION
    '{
      variant:          Buffered,
      offset:           12'd2504,
      size:             520,
      key_sel:          VendorSecretProdKey,
      secret:           1'b1,
      sw_digest:        1'b0,
      hw_digest:        1'b1,
      write_lock:       1'b1,
      read_lock:        1'b1,
      integrity:        1'b1,
      iskeymgr_creator: 1'b0,
      iskeymgr_owner:   1'b0
    },
    // VENDOR_NON_SECRET_PROD_PARTITION
    '{
      variant:          Unbuffered,
      offset:           12'd3024,
      size:             984,
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
    // LIFE_CYCLE
    '{
      variant:          LifeCycle,
      offset:           12'd4008,
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
    SecretTestUnlockPartitionIdx,
    SecretManufPartitionIdx,
    SecretProdPartition0Idx,
    SecretProdPartition1Idx,
    SecretProdPartition2Idx,
    SecretProdPartition3Idx,
    SwManufPartitionIdx,
    SecretLcTransitionPartitionIdx,
    SvnPartitionIdx,
    VendorTestPartitionIdx,
    VendorKeysManufPartitionIdx,
    VendorKeysProdPartitionIdx,
    VendorSecretProdPartitionIdx,
    VendorNonSecretProdPartitionIdx,
    LifeCycleIdx,
    // These are not "real partitions", but in terms of implementation it is convenient to
    // add these at the end of certain arrays.
    DaiIdx,
    LciIdx,
    //KdiIdx,
    // Number of agents is the last idx+1.
    NumAgentsIdx
  } part_idx_e;

  parameter int NumAgents = int'(NumAgentsIdx);

  // Breakout types for easier access of individual items.
  typedef struct packed {
    logic [63:0] secret_test_unlock_partition_digest;
    logic [127:0] cptra_core_manuf_debug_unlock_token;
  } otp_secret_test_unlock_partition_data_t;

  // default value used for intermodule
  parameter otp_secret_test_unlock_partition_data_t OTP_SECRET_TEST_UNLOCK_PARTITION_DATA_DEFAULT = '{
    secret_test_unlock_partition_digest: 64'hD61AA54CC696D54,
    cptra_core_manuf_debug_unlock_token: 128'h0
  };
  typedef struct packed {
    logic [63:0] secret_manuf_partition_digest;
    logic [511:0] cptra_core_uds_seed;
  } otp_secret_manuf_partition_data_t;

  // default value used for intermodule
  parameter otp_secret_manuf_partition_data_t OTP_SECRET_MANUF_PARTITION_DATA_DEFAULT = '{
    secret_manuf_partition_digest: 64'h16AF2545001DC3DB,
    cptra_core_uds_seed: 512'hCF7A50A9A91EF7F7B3A5B4421F462370FFF698183664DC7EDF3888886BD10DC67ABB319BDA0529AE40119A3C6E63CDF358840E458E4029A6B5AC1F53D00A08C3
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_0_digest;
    logic [63:0] cptra_core_field_entropy_0;
  } otp_secret_prod_partition_0_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_0_data_t OTP_SECRET_PROD_PARTITION_0_DATA_DEFAULT = '{
    secret_prod_partition_0_digest: 64'hCA07B204875B3A8B,
    cptra_core_field_entropy_0: 64'hB28B5C0FEE5F4C02
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_1_digest;
    logic [63:0] cptra_core_field_entropy_1;
  } otp_secret_prod_partition_1_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_1_data_t OTP_SECRET_PROD_PARTITION_1_DATA_DEFAULT = '{
    secret_prod_partition_1_digest: 64'hE8207D2509C0D925,
    cptra_core_field_entropy_1: 64'h711D135F59A50322
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_2_digest;
    logic [63:0] cptra_core_field_entropy_2;
  } otp_secret_prod_partition_2_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_2_data_t OTP_SECRET_PROD_PARTITION_2_DATA_DEFAULT = '{
    secret_prod_partition_2_digest: 64'h7ADDC105A37BE10E,
    cptra_core_field_entropy_2: 64'hB6711DB6F5D40A37
  };
  typedef struct packed {
    logic [63:0] secret_prod_partition_3_digest;
    logic [63:0] cptra_core_field_entropy_3;
  } otp_secret_prod_partition_3_data_t;

  // default value used for intermodule
  parameter otp_secret_prod_partition_3_data_t OTP_SECRET_PROD_PARTITION_3_DATA_DEFAULT = '{
    secret_prod_partition_3_digest: 64'h82F69C5D067AC23A,
    cptra_core_field_entropy_3: 64'hDBC827839FE2DCC2
  };
  typedef struct packed {
    logic [63:0] vendor_secret_prod_partition_digest;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_15;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_14;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_13;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_12;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_11;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_10;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_9;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_8;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_7;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_6;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_5;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_4;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_3;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_2;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_1;
    logic [255:0] cptra_ss_vendor_specific_secret_fuse_0;
  } otp_vendor_secret_prod_partition_data_t;

  // default value used for intermodule
  parameter otp_vendor_secret_prod_partition_data_t OTP_VENDOR_SECRET_PROD_PARTITION_DATA_DEFAULT = '{
    vendor_secret_prod_partition_digest: 64'h8633C897599F66A1,
    cptra_ss_vendor_specific_secret_fuse_15: 256'hAF0ADBBE93A5F9BAB97F2A9139A0FFA956AEADB13BAAA10D2336E399E5F1AEB,
    cptra_ss_vendor_specific_secret_fuse_14: 256'h9B0E9C2F06F0694CEDAB6BE2563D7C0C31CB754A523EAFE90D67C2C55F3D8CE4,
    cptra_ss_vendor_specific_secret_fuse_13: 256'h207A34ABD439B462F7FDB8FC20E2960FA1C637588C08C38374903B58BC3484DF,
    cptra_ss_vendor_specific_secret_fuse_12: 256'hF9CBEDBC3D512527FE67E8B2E07D55510F7DF200E9385195DE4F2FB208A71E82,
    cptra_ss_vendor_specific_secret_fuse_11: 256'h7E2D8D259F101A8BF1E2B746BE84F30380655EE26D62DEE6AE95AAFB7A44E26D,
    cptra_ss_vendor_specific_secret_fuse_10: 256'hDFEBB9B7267FEF2CEF1772418F8629C29C75ABA36D93FFE068F655FA7990D589,
    cptra_ss_vendor_specific_secret_fuse_9: 256'hDD3C869E21D220A3543A0130B3BCFEC376D4BAC76AC7F32652FF80CC92DAEF2D,
    cptra_ss_vendor_specific_secret_fuse_8: 256'hB8138A3BBDAAE552050DE28C64D4C187725A4C748BE1317E3E01C22789430178,
    cptra_ss_vendor_specific_secret_fuse_7: 256'h563C0C2920F637247508BAB4DC752164D104B5B0B3D8FDDB7A0C53617A6A31C,
    cptra_ss_vendor_specific_secret_fuse_6: 256'h60BAE4A876D70627B8DE43EDFF17AA86BF1F41B783B6DB8C644C4723CF740F6A,
    cptra_ss_vendor_specific_secret_fuse_5: 256'h6FDFE93D3146B0F41837480464544A13BF7D79A9FF747F62DCDD92FA5B24BF3,
    cptra_ss_vendor_specific_secret_fuse_4: 256'hC469C593E5DC0DA88CBBAD02BB4CA928AA3F4C71234F097C67BBE3B4555DF35C,
    cptra_ss_vendor_specific_secret_fuse_3: 256'h20440F25BB053FB5F87BED95CFBA3727BBF4A76885E754F2BE193854E9CA60A0,
    cptra_ss_vendor_specific_secret_fuse_2: 256'h4947DD361344767A0340A5B93BB19342E29749216775E8A515F164D7930C9D19,
    cptra_ss_vendor_specific_secret_fuse_1: 256'h9605F051E74379CBCC6596C7174EBA643E725E464F593C87A445C3C29F71A256,
    cptra_ss_vendor_specific_secret_fuse_0: 256'hE817E760B27AE937BFCDF15A3429452A851B80674A2B6FBE93B61DE417B9FB33
  };
  typedef struct packed {
    // This reuses the same encoding as the life cycle signals for indicating valid status.
    lc_ctrl_pkg::lc_tx_t valid;
    otp_vendor_secret_prod_partition_data_t vendor_secret_prod_partition_data;
    otp_secret_prod_partition_3_data_t secret_prod_partition_3_data;
    otp_secret_prod_partition_2_data_t secret_prod_partition_2_data;
    otp_secret_prod_partition_1_data_t secret_prod_partition_1_data;
    otp_secret_prod_partition_0_data_t secret_prod_partition_0_data;
    otp_secret_manuf_partition_data_t secret_manuf_partition_data;
    otp_secret_test_unlock_partition_data_t secret_test_unlock_partition_data;
  } otp_broadcast_t;

  // default value for intermodule
  parameter otp_broadcast_t OTP_BROADCAST_DEFAULT = '{
    valid: lc_ctrl_pkg::Off,
    vendor_secret_prod_partition_data: OTP_VENDOR_SECRET_PROD_PARTITION_DATA_DEFAULT,
    secret_prod_partition_3_data: OTP_SECRET_PROD_PARTITION_3_DATA_DEFAULT,
    secret_prod_partition_2_data: OTP_SECRET_PROD_PARTITION_2_DATA_DEFAULT,
    secret_prod_partition_1_data: OTP_SECRET_PROD_PARTITION_1_DATA_DEFAULT,
    secret_prod_partition_0_data: OTP_SECRET_PROD_PARTITION_0_DATA_DEFAULT,
    secret_manuf_partition_data: OTP_SECRET_MANUF_PARTITION_DATA_DEFAULT,
    secret_test_unlock_partition_data: OTP_SECRET_TEST_UNLOCK_PARTITION_DATA_DEFAULT
  };


  // OTP invalid partition default for buffered partitions.
  parameter logic [32767:0] PartInvDefault = 32768'({
    704'({
      320'h9E02C05185213FCF029CB3E62CE6FDDCBA7F6C9D2519EA1AACC8E1922AF7B82D7479CD41D20282EB,
      384'h58C2A1BA65D13A0FE39B01C95A626001CC969493D06CDB450C26A87F7BF58DDA1149EFDC5F023299DFB44D70A9F90685
    }),
    7872'({
      64'h71400F1A2858655B,
      3712'h0, // unallocated space
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0,
      256'h0
    }),
    4160'({
      64'h8633C897599F66A1,
      256'hAF0ADBBE93A5F9BAB97F2A9139A0FFA956AEADB13BAAA10D2336E399E5F1AEB,
      256'h9B0E9C2F06F0694CEDAB6BE2563D7C0C31CB754A523EAFE90D67C2C55F3D8CE4,
      256'h207A34ABD439B462F7FDB8FC20E2960FA1C637588C08C38374903B58BC3484DF,
      256'hF9CBEDBC3D512527FE67E8B2E07D55510F7DF200E9385195DE4F2FB208A71E82,
      256'h7E2D8D259F101A8BF1E2B746BE84F30380655EE26D62DEE6AE95AAFB7A44E26D,
      256'hDFEBB9B7267FEF2CEF1772418F8629C29C75ABA36D93FFE068F655FA7990D589,
      256'hDD3C869E21D220A3543A0130B3BCFEC376D4BAC76AC7F32652FF80CC92DAEF2D,
      256'hB8138A3BBDAAE552050DE28C64D4C187725A4C748BE1317E3E01C22789430178,
      256'h563C0C2920F637247508BAB4DC752164D104B5B0B3D8FDDB7A0C53617A6A31C,
      256'h60BAE4A876D70627B8DE43EDFF17AA86BF1F41B783B6DB8C644C4723CF740F6A,
      256'h6FDFE93D3146B0F41837480464544A13BF7D79A9FF747F62DCDD92FA5B24BF3,
      256'hC469C593E5DC0DA88CBBAD02BB4CA928AA3F4C71234F097C67BBE3B4555DF35C,
      256'h20440F25BB053FB5F87BED95CFBA3727BBF4A76885E754F2BE193854E9CA60A0,
      256'h4947DD361344767A0340A5B93BB19342E29749216775E8A515F164D7930C9D19,
      256'h9605F051E74379CBCC6596C7174EBA643E725E464F593C87A445C3C29F71A256,
      256'hE817E760B27AE937BFCDF15A3429452A851B80674A2B6FBE93B61DE417B9FB33
    }),
    7168'({
      64'hF7024F5AD97A0F9E,
      48'h0, // unallocated space
      16'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0,
      384'h0,
      8'h0,
      32'h0,
      32'h0,
      8'h0
    }),
    448'({
      64'h769D73F614F297C5,
      384'h0
    }),
    512'({
      64'hFEEC587DCB2A9253,
      192'h0, // unallocated space
      256'h0
    }),
    320'({
      24'h0, // unallocated space
      8'h0,
      128'h0,
      128'h0,
      32'h0
    }),
    1472'({
      64'hF545B7FC56675745,
      128'h1E46311FD36D95401136C663A36C3E3,
      128'h315FD2B871D88819A0D1E90E8C9FDDFA,
      128'h688098A43C33459F0279FC51CC7C626E,
      128'hD3D58610F4851667D68C96F0B3D1FEED,
      128'h2C0DBDDEDF7A854D5E58D0AA97A0F8F6,
      128'h2A4D8B51F5D41C8AD0BAC511D08ECE0E,
      128'h1C752824C7DDC89694CD3DED94B57819,
      128'h426D99D374E699CAE00E9680BD9B7029,
      128'h234729143F97B62A55D0320379A0D260,
      128'hD396D1CE085BDC31105733EAA3880C5A,
      128'h7E17D06B5D4E0DDDDBB9844327F20FB5
    }),
    8832'({
      64'h86224F25DAB6226B,
      3752'h0, // unallocated space
      4096'h0,
      16'h0,
      128'h0,
      768'h0,
      8'h0
    }),
    128'({
      64'h82F69C5D067AC23A,
      64'hDBC827839FE2DCC2
    }),
    128'({
      64'h7ADDC105A37BE10E,
      64'hB6711DB6F5D40A37
    }),
    128'({
      64'hE8207D2509C0D925,
      64'h711D135F59A50322
    }),
    128'({
      64'hCA07B204875B3A8B,
      64'hB28B5C0FEE5F4C02
    }),
    576'({
      64'h16AF2545001DC3DB,
      512'hCF7A50A9A91EF7F7B3A5B4421F462370FFF698183664DC7EDF3888886BD10DC67ABB319BDA0529AE40119A3C6E63CDF358840E458E4029A6B5AC1F53D00A08C3
    }),
    192'({
      64'hD61AA54CC696D54,
      128'h0
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
    hw2reg.secret_test_unlock_partition_digest = part_digest[SecretTestUnlockPartitionIdx];
    hw2reg.secret_manuf_partition_digest = part_digest[SecretManufPartitionIdx];
    hw2reg.secret_prod_partition_0_digest = part_digest[SecretProdPartition0Idx];
    hw2reg.secret_prod_partition_1_digest = part_digest[SecretProdPartition1Idx];
    hw2reg.secret_prod_partition_2_digest = part_digest[SecretProdPartition2Idx];
    hw2reg.secret_prod_partition_3_digest = part_digest[SecretProdPartition3Idx];
    hw2reg.sw_manuf_partition_digest = part_digest[SwManufPartitionIdx];
    hw2reg.secret_lc_transition_partition_digest = part_digest[SecretLcTransitionPartitionIdx];
    hw2reg.vendor_test_partition_digest = part_digest[VendorTestPartitionIdx];
    hw2reg.vendor_keys_manuf_partition_digest = part_digest[VendorKeysManufPartitionIdx];
    hw2reg.vendor_keys_prod_partition_digest = part_digest[VendorKeysProdPartitionIdx];
    hw2reg.vendor_secret_prod_partition_digest = part_digest[VendorSecretProdPartitionIdx];
    hw2reg.vendor_non_secret_prod_partition_digest = part_digest[VendorNonSecretProdPartitionIdx];
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
    // SVN_PARTITION
    if (!reg2hw.svn_partition_read_lock) begin
      part_access_pre[SvnPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // VENDOR_TEST_PARTITION
    if (!reg2hw.vendor_test_partition_read_lock) begin
      part_access_pre[VendorTestPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // VENDOR_KEYS_MANUF_PARTITION
    if (!reg2hw.vendor_keys_manuf_partition_read_lock) begin
      part_access_pre[VendorKeysManufPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // VENDOR_KEYS_PROD_PARTITION
    if (!reg2hw.vendor_keys_prod_partition_read_lock) begin
      part_access_pre[VendorKeysProdPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
    end
    // VENDOR_NON_SECRET_PROD_PARTITION
    if (!reg2hw.vendor_non_secret_prod_partition_read_lock) begin
      part_access_pre[VendorNonSecretProdPartitionIdx].read_lock = caliptra_prim_mubi_pkg::MuBi8True;
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
    // SECRET_TEST_UNLOCK_PARTITION
    valid &= part_init_done[SecretTestUnlockPartitionIdx];
    otp_broadcast.secret_test_unlock_partition_data = otp_secret_test_unlock_partition_data_t'(part_buf_data[SecretTestUnlockPartitionOffset +: SecretTestUnlockPartitionSize]);
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
    // SECRET_LC_TRANSITION_PARTITION
    unused ^= ^{part_init_done[SecretLcTransitionPartitionIdx],
                part_buf_data[SecretLcTransitionPartitionOffset +: SecretLcTransitionPartitionSize]};
    // SVN_PARTITION
    unused ^= ^{part_init_done[SvnPartitionIdx],
                part_buf_data[SvnPartitionOffset +: SvnPartitionSize]};
    // VENDOR_TEST_PARTITION
    unused ^= ^{part_init_done[VendorTestPartitionIdx],
                part_buf_data[VendorTestPartitionOffset +: VendorTestPartitionSize]};
    // VENDOR_KEYS_MANUF_PARTITION
    unused ^= ^{part_init_done[VendorKeysManufPartitionIdx],
                part_buf_data[VendorKeysManufPartitionOffset +: VendorKeysManufPartitionSize]};
    // VENDOR_KEYS_PROD_PARTITION
    unused ^= ^{part_init_done[VendorKeysProdPartitionIdx],
                part_buf_data[VendorKeysProdPartitionOffset +: VendorKeysProdPartitionSize]};
    // VENDOR_SECRET_PROD_PARTITION
    valid &= part_init_done[VendorSecretProdPartitionIdx];
    otp_broadcast.vendor_secret_prod_partition_data = otp_vendor_secret_prod_partition_data_t'(part_buf_data[VendorSecretProdPartitionOffset +: VendorSecretProdPartitionSize]);
    // VENDOR_NON_SECRET_PROD_PARTITION
    unused ^= ^{part_init_done[VendorNonSecretProdPartitionIdx],
                part_buf_data[VendorNonSecretProdPartitionOffset +: VendorNonSecretProdPartitionSize]};
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
    // SECRET_TEST_UNLOCK_PARTITION
    unused ^= ^{part_digest[SecretTestUnlockPartitionIdx],
                part_buf_data[SecretTestUnlockPartitionOffset +: SecretTestUnlockPartitionSize]};
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
    // SECRET_LC_TRANSITION_PARTITION
    unused ^= ^{part_digest[SecretLcTransitionPartitionIdx],
                part_buf_data[SecretLcTransitionPartitionOffset +: SecretLcTransitionPartitionSize]};
    // SVN_PARTITION
    unused ^= ^{part_digest[SvnPartitionIdx],
                part_buf_data[SvnPartitionOffset +: SvnPartitionSize]};
    // VENDOR_TEST_PARTITION
    unused ^= ^{part_digest[VendorTestPartitionIdx],
                part_buf_data[VendorTestPartitionOffset +: VendorTestPartitionSize]};
    // VENDOR_KEYS_MANUF_PARTITION
    unused ^= ^{part_digest[VendorKeysManufPartitionIdx],
                part_buf_data[VendorKeysManufPartitionOffset +: VendorKeysManufPartitionSize]};
    // VENDOR_KEYS_PROD_PARTITION
    unused ^= ^{part_digest[VendorKeysProdPartitionIdx],
                part_buf_data[VendorKeysProdPartitionOffset +: VendorKeysProdPartitionSize]};
    // VENDOR_SECRET_PROD_PARTITION
    unused ^= ^{part_digest[VendorSecretProdPartitionIdx],
                part_buf_data[VendorSecretProdPartitionOffset +: VendorSecretProdPartitionSize]};
    // VENDOR_NON_SECRET_PROD_PARTITION
    unused ^= ^{part_digest[VendorNonSecretProdPartitionIdx],
                part_buf_data[VendorNonSecretProdPartitionOffset +: VendorNonSecretProdPartitionSize]};
    // LIFE_CYCLE
    unused ^= ^{part_digest[LifeCycleIdx],
                part_buf_data[LifeCycleOffset +: LifeCycleSize]};
    unused ^= valid;
    return otp_keymgr_key;
  endfunction : named_keymgr_key_assign

endpackage : otp_ctrl_part_pkg
