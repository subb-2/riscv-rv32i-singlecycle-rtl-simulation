`timescale 1ns / 1ps

module RV32I_top (
    input clk,
    input rst
);
    logic dwe;
    logic [31:0] instr_addr, instr_data, daddr, dwdata, drdata;

    instruction_mem U_INSTRUCTION_MEM (.*);

    RV32I_cpu U_RV32I (.*);

    data_mem U_DATA_MEM (.*);


endmodule
