`timescale 1ns / 1ps

module RV32I_cpu (
    input        clk,
    input        rst,
    input [31:0] instr_addr,
    input [31:0] instr_data
);

    logic rf_we;
    logic [31:0] rd1, rd2, alu_result;

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .alu_control()
    );

    register_file U_REG_FILE (
        .clk(clk),
        .rst(rst),
        .RA1(instr_data[19:15]),
        .RA2(instr_data[24:20]),
        .WA(instr_data[11:7]),
        .rf_we(rf_we),
        .wdata(alu_result),
        .RD1(rd1),
        .RD2(rd2)
    );

    alu U_ALU (
        .rd1(rd1),
        .rd2(rd2),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );

endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,
    input  [ 4:0] RA2,
    input  [ 4:0] WA,
    input         rf_we,
    input  [31:0] wdata,
    output [31:0] RD1,
    output [31:0] RD2
);

endmodule

module control_unit (
    input        clk,
    input        rst,
    input  [6:0] funct7,
    input  [2:0] funct3,
    input  [6:0] opcode,
    output       rf_we,
    output [2:0] alu_control
);

endmodule

module alu (
    input  [31:0] rd1,
    input  [31:0] rd2,
    input  [ 2:0] alu_control,
    output [31:0] alu_result
);

endmodule
