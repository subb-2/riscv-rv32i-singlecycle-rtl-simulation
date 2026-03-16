`define SIMULATION 1 

//op code
`define R_TYPE 7'b011_0011
`define S_TYPE 7'b010_0011
`define I_TYPE 7'b001_0011
`define IL_TYPE 7'b000_0011
`define B_TYPE 7'b110_0011
`define LUI_TYPE 7'b011_0111
`define AUIPC_TYPE 7'b001_0111
`define J_TYPE 7'b110_1111 //jal
`define JL_TYPE 7'b110_0111 //jalr

// R-type instruction
`define ADD 4'b0_000   // ADD RD = RS1 + RS2
`define SUB 4'b1_000  // SUB RD = RS1 - RS2
`define SLL 4'b0_001  // SLL RD = RS1 << RS2 
`define SLT 4'b0_010  // SLT RD = (RS1 < RS2) ? 1 : 0
`define SLTU 4'b0_011  // SLTU RD = (RS1 < RS2) ? 1 : 0
`define XOR 4'b0_100  // XOR RD = RS1 ^ RS2
`define SRL 4'b0_101  // SRL
`define SRA 4'b1_101  // msb extention, arithmetic right shift
`define OR 4'b0_110  // OR RD = RS1 | RS2
`define AND 4'b0_111  // AND RD = RS1 & RS2

//B-type instruction
`define BEQ 4'b0_000
`define BNE 4'b0_001
`define BLT 4'b0_100
`define BGE 4'b0_101
`define BLTU 4'b0_110
`define BGEU 4'b0_111

//S-type instruction
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

//IL-type instruction
`define LB 3'b000
`define LH 3'b001
`define LW 3'b010
`define LBU 3'b100
`define LHU 3'b101

//J-type instruction
`define JALR 3'b000
