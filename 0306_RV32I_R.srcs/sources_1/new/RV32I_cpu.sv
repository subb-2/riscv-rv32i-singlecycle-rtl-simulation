`timescale 1ns / 1ps
`include "define.vh"

module RV32I_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    output [31:0] instr_addr,
    output        dwe,
    output [31:0] dwaddr,
    output [31:0] dwdata
);

    logic rf_we, alu_src;
    logic [31:0] alu_result, alu_pc_out;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .rf_we      (rf_we),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .dwe        (dwe)
    );

    rv32i_datapath U_DATAPATH (.*);


endmodule



module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       alu_src,
    output logic [3:0] alu_control,
    output logic       dwe
);

    always_comb begin
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        dwe         = 1'b0;
        case (opcode)
            `R_TYPE: begin // R-type, to write register file, alu_control == {funct7[5], funct3}
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = {funct7[5], funct3};
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                dwe         = 1'b1;
            end
        endcase
    end

endmodule



