`timescale 1ns / 1ps

module RV32I_cpu (
    input        clk,
    input        rst,
    input [31:0] instr_addr,
    input [31:0] instr_data
);

    logic rf_we;
    logic [31:0] rd1, rd2, alu_result, alu_pc_out;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        //.clk(clk),
        //.rst(rst),
        .funct7(instr_data[31:25]),
        .funct3(instr_data[14:12]),
        .opcode(instr_data[6:0]),
        .rf_we(rf_we),
        .alu_control(alu_control)
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

    pc U_PC (
        .clk(clk),
        .rst(rst),
        .alu_pc_out(alu_pc_out),
        .instr_addr(instr_addr)
    );

    alu_pc U_ALU_PC (
        .a(4),
        .b(instr_addr),
        .alu_pc_out(alu_pc_out)
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

    logic [31:0] wdata_arry[0:31];
    assign RD1 = wdata_arry[RA1];
    assign RD2 = wdata_arry[RA2];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i = i + 1) begin
                wdata_arry[i] <= 0;
            end
        end else begin
            if (rf_we) begin
                if (WA != 0) begin
                    wdata_arry[WA] <= wdata;
                end
            end
        end
    end

endmodule

module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output             rf_we,
    output logic [3:0] alu_control
);

    assign rf_we = (opcode == 7'b0110011) ? 1 : 0;

    always_comb begin
        alu_control = 4'b1111;

        if (opcode == 7'b0110011) begin
            case (funct3)
                3'b000: begin
                    if (funct7[5] == 1) begin
                        alu_control = 4'b0001;
                    end else alu_control = 4'b0000;
                end
                3'b001: begin
                    alu_control = 4'b0010;
                end
                3'b010: begin
                    alu_control = 4'b0011;
                end
                3'b011: begin
                    alu_control = 4'b0100;
                end
                3'b100: begin
                    alu_control = 4'b0101;
                end
                3'b101: begin
                    if (funct7[5] == 1) begin
                        alu_control = 4'b0111;
                    end else alu_control = 4'b0110;
                end
                3'b110: begin
                    alu_control = 4'b1000;
                end
                3'b111: begin
                    alu_control = 4'b1001;
                end
            endcase
        end
    end


endmodule

module alu (
    input        [31:0] rd1,
    input        [31:0] rd2,
    input        [ 3:0] alu_control,
    output logic [31:0] alu_result
);

    always_comb begin
        case (alu_control)
            4'b0000: alu_result = rd1 + rd2;  // ADD
            4'b0001: alu_result = rd1 - rd2;  // SUB
            4'b0010: alu_result = rd1 << rd2;  // SLL
            4'b0011: alu_result = (rd1 < rd2) ? 1 : 0;  // SLT
            4'b0100: alu_result = (rd1 < rd2) ? 1 : 0;  // SLTU
            4'b0101: alu_result = rd1 ^ rd2;  // XOR
            4'b0110: alu_result = rd1 >> rd2;  // SRL
            4'b0111: alu_result = rd1 >>> rd2;  // SRA
            4'b1000: alu_result = rd1 | rd2;  // OR
            4'b1001: alu_result = rd1 & rd2;  // AND
            default: alu_result = 32'b0;
        endcase
    end

endmodule

module pc (
    input               clk,
    input               rst,
    input        [31:0] alu_pc_out,
    output logic [31:0] instr_addr
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            instr_addr <= 0;
        end else begin
            instr_addr <= alu_pc_out;
        end
    end
endmodule

module alu_pc (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] alu_pc_out
);

    assign alu_pc_out = a + b;

endmodule
