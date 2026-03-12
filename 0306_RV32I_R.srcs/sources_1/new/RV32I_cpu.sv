`timescale 1ns / 1ps
`include "define.vh"

module RV32I_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    output [31:0] instr_addr,
    output        dwe,
    output [ 2:0] o_funct3,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic rf_we, alu_src, branch, jal, jalr;
    logic [2:0] rfwd_src;
    logic [31:0] alu_result, alu_pc_out;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .rf_we      (rf_we),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .rfwd_src   (rfwd_src),
        .o_funct3   (o_funct3),
        .branch     (branch),
        .jal        (jal),
        .jalr       (jalr),
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
    output logic [2:0] rfwd_src,
    output logic [2:0] o_funct3,
    output logic       branch,
    output logic       jal,
    output logic       jalr,
    output logic       dwe
);

    always_comb begin
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rfwd_src    = 3'd0;
        o_funct3    = 3'b000;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        dwe         = 1'b0;
        case (opcode)
            `R_TYPE: begin // R-type, to write register file, alu_control == {funct7[5], funct3}
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = {funct7[5], funct3};
                rfwd_src    = 3'd0;
                o_funct3    = 3'b000;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `B_TYPE: begin // R-type, to write register file, alu_control == {funct7[5], funct3}
                rf_we       = 1'b0;
                alu_src     = 1'b0;
                alu_control = {1'b0, funct3};
                rfwd_src    = 3'd0;
                o_funct3    = 3'b000;
                branch      = 1'b1;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'd0;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'd1;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `I_TYPE: begin
                rf_we   = 1'b1;
                alu_src = 1'b1;
                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end
                rfwd_src = 3'd0;
                o_funct3 = funct3;
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                dwe      = 1'b0;
            end
            `LUI_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'd2;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `AUIPC_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'd3;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `JAL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'd4;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b1;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `JALR_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'd4;
                o_funct3    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b1;
                dwe         = 1'b0;
            end
        endcase
    end

endmodule



