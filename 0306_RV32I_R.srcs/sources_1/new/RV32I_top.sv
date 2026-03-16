`timescale 1ns / 1ps

module RV32I_top (
    input clk,
    input rst,
    output [4:0] led
);
    logic       dwe;
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, daddr, dwdata, drdata;

    instruction_mem U_INSTRUCTION_MEM (.*);

    RV32I_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );

    data_mem U_DATA_MEM (
        .*,
        .i_funct3(o_funct3) 
    );

assign led = instr_addr[4:0];

endmodule
