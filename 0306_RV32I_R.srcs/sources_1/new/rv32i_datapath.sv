`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         alu_src,
    input         rfwd_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    input         branch,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data, rfwb_data;
    logic b_taken;
    
    assign daddr  = alu_result;
    assign dwdata = rd2;

    program_counter U_PC (
        .clk(clk),
        .rst(rst),
        .imm_data(imm_data),
        .b_taken(b_taken), //from alu comparator
        .branch(branch), //froma control unit for B-type
        .program_counter(instr_addr)
    );

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .RA1  (instr_data[19:15]),
        .RA2  (instr_data[24:20]),
        .WA   (instr_data[11:7]),
        .wdata(rfwb_data),
        .rf_we(rf_we),
        .RD1  (rd1),
        .RD2  (rd2)
    );

    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data[31:0]),
        .imm_data  (imm_data)
    );

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0    (rd2),         //sel 0
        .in1    (imm_data),    //sel 1
        .mux_sel(alu_src),
        .out_mux(alurs2_data)
    );

    alu U_ALU (
        .rd1        (rd1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result),
        .b_taken    (b_taken)
    );

    //to register file
    mux_2x1 U_WB_MUX (
        .in0    (alu_result),  //sel 0
        .in1    (drdata),      //sel 1
        .mux_sel(rfwd_src),
        .out_mux(rfwb_data)
    );


endmodule

module mux_2x1 (
    input        [31:0] in0,      //sel 0
    input        [31:0] in1,      //sel 1
    input               mux_sel,
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;

endmodule

module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])  //opcode
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `I_TYPE, `IL_TYPE: begin  //load 
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `B_TYPE: begin  //Branch
                imm_data = {
                    {19{instr_data[31]}},
                    instr_data[31],
                    instr_data[7], // imm bit 11
                    instr_data[30:25], // imm bit 10:5
                    instr_data[11:8], //imm bit 4:1
                    1'b0
                };
            end
        endcase
    end

endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] RA1,    //instruction code RS1
    input  [ 4:0] RA2,    //instruction code RS2 
    input  [ 4:0] WA,     //instruction code RD
    input         rf_we,  //instruction RD write data 
    input  [31:0] wdata,  //Register File write Enable 
    output [31:0] RD1,    //Register File RS1 output 
    output [31:0] RD2     //Register File RS2 output 
);

    logic [31:0] register_file[1:31];  // x0 must have zero value 

    //simulation 할 때만 들어감 
`ifdef SIMULATION
    initial begin
        for (int i = 1; i < 32; i++) begin
            register_file[i] = i;
        end
        //register_file[12] = 32'h3;
        //register_file[13] = 32'h3;
        //register_file[14] = 32'h33;
        //register_file[14] = 32'h33;
        //register_file[14] = 32'h33;
        //register_file[14] = 32'h33;
        //register_file[14] = 32'h33; 
        //register_file[14] = 32'h33;
    end
`endif

    //0번지 hard wire -> 0번지 assess되면 항상 0 나가도록 메모리 뭐 하라고?
    //assign if 
    //칩 설계시에는 다르겠지만, 지금은 차이 없음 

    always_ff @(posedge clk) begin
        if (!rst & rf_we) begin
            register_file[WA] <= wdata;
        end
    end

    //output CL 
    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;

endmodule

module alu (
    input        [31:0] rd1,          //RS1
    input        [31:0] rd2,          //RS2
    input        [ 3:0] alu_control,  //function7[5], funct3 : 4bit 
    output logic [31:0] alu_result,
    output logic        b_taken
);

    always_comb begin
        alu_result = 0;
        case (alu_control)
            `ADD:  alu_result = rd1 + rd2;  // ADD RD = RS1 + RS2
            `SUB:  alu_result = rd1 - rd2;  // SUB RD = RS1 - RS2
            `SLL:  alu_result = rd1 << rd2[4:0];  // SLL RD = RS1 << RS2 
            `SLT:  alu_result = ($signed(rd1) < $signed(rd2)) ? 1 : 0;
            // SLT RD = (RS1 < RS2) ? 1 : 0
            `SLTU: alu_result = (rd1 < rd2) ? 1 : 0;
            // SLTU RD = (RS1 < RS2) ? 1 : 0
            `XOR:  alu_result = rd1 ^ rd2;  // XOR RD = RS1 ^ RS2
            `SRL:  alu_result = rd1 >> rd2[4:0];  // SRL
            `SRA:  alu_result = $signed(rd1) >>> rd2[4:0];
            // msb extention, arithmetic right shift
            `OR:   alu_result = rd1 | rd2;  // OR RD = RS1 | RS2
            `AND:  alu_result = rd1 & rd2;  // AND RD = RS1 & RS2
        endcase
    end

    always_comb begin
        b_taken = 0;
        case (alu_control)
            //B-type comparator
            `BEQ: begin
                if (rd1 == rd2) b_taken = 1;
                else b_taken = 0;
            end
            `BNE: begin
                if (rd1 != rd2) b_taken = 1;
                else b_taken = 0;
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2)) b_taken = 1;
                else b_taken = 0;
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2)) b_taken = 1;
                else b_taken = 0;
            end
            `BLTU: begin
                if (rd1 < rd2) b_taken = 1;
                else b_taken = 0;
            end
            `BGEU: begin
                if (rd1 >= rd2) b_taken = 1;
                else b_taken = 0;
            end
        endcase
    end

endmodule

module program_counter (
    input         clk,
    input         rst,
    input  [31:0] imm_data,
    input         b_taken,
    input         branch,
    output [31:0] program_counter
);

    logic [31:0] pc_alu_out, pc_alu_4, pc_alu_imm;

    pc_alu U_PC_4 (
        .a(32'd4),
        .b(program_counter),
        .pc_alu_out(pc_alu_4)
    );

    pc_alu U_PC_IMM (
        .a(imm_data),
        .b(program_counter),
        .pc_alu_out(pc_alu_imm)
    );

    mux_2x1 U_PC_NEXT_MUX (
        .in0    (pc_alu_4),     //sel 0
        .in1    (pc_alu_imm),   //sel 1
        .mux_sel(b_taken & branch),
        .out_mux(pc_alu_out)
    );

    register U_PC_REG (
        .clk(clk),
        .rst(rst),
        .data_in(pc_alu_out),
        .data_out(program_counter)
    );

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);

    assign pc_alu_out = a + b;

endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);

    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;

endmodule
