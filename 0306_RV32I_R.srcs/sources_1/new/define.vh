`define SIMULATION 1 

//op code
`define R_TYPE 7'b011_0011
`define S_TYPE 7'b010_0011
`define I_TYPE 7'b001_0011
`define IL_TYPE 7'b000_0011

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
