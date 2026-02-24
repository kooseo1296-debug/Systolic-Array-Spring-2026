// ISA (v1)
// OPVALID(1) / OPCODE(3) / SEL(4)+ADDR(16) or PARAM(20) / DATA(8): total(32)

`define PE_ROW  8
`define PE_COL  8

`define BIT_ROW_ID  4

`define OPVALID 1'b1

`define BIT_OPCODE  3
`define OPCODE_NOP      `BIT_OPCODE'd0
`define OPCODE_PARAM    `BIT_OPCODE'd1
`define OPCODE_LDSRAM   `BIT_OPCODE'd2
`define OPCODE_STSRAM   `BIT_OPCODE'd3
`define OPCODE_EX       `BIT_OPCODE'd4
`define OPCODE_WBPSRAM   `BIT_OPCODE'd5
`define OPCODE_WBPARAM   `BIT_OPCODE'd6

// param (OP code)
`define BIT_PARAM     20
`define BIT_SEL     4
`define BIT_ADDR     16
`define BIT_VALID     1

// FIXED: Standard single quotes used below
`define PARAM_BASE_WSRAM    `BIT_PARAM'd0
`define PARAM_S             `BIT_PARAM'd1
`define PARAM_OC            `BIT_PARAM'd2
`define PARAM_IC            `BIT_PARAM'd3
`define PARAM_TRG           `BIT_PARAM'd4
`define PARAM_IC_WH         `BIT_PARAM'd5
`define PARAM_BASE_WSRAM_WH  `BIT_PARAM'd6

// data
`define BIT_DATA    8
`define BIT_PSUM    32
`define TRG_ISRAM   `BIT_DATA'd0
`define TRG_WSRAM   `BIT_DATA'd1
`define TRG_PSRAM   `BIT_DATA'd2

`define BIT_INSTR   32 //(1+`BIT_OPCODE+`BIT_PARAM+`BIT_DATA)

// SRAM Address widths
`define BIT_SPSRAM 12
`define BIT_DPSRAM 10