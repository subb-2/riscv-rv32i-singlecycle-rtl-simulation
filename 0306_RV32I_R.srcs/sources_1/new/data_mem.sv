`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [ 2:0] i_funct3,
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] dmem[0:1023]; //1000word 선언  

    always_ff @(posedge clk) begin

        if (dwe) begin
            case (i_funct3)
                //SB
                3'b000: begin
                    dmem[daddr+0] <= dwdata[7:0];
                end
                //SH 
                3'b001: begin
                    dmem[daddr+0] <= dwdata[7:0];
                    dmem[daddr+1] <= dwdata[15:8];
                end
                //SW
                3'b010: begin
                    dmem[daddr+0] <= dwdata[7:0];
                    dmem[daddr+1] <= dwdata[15:8];
                    dmem[daddr+2] <= dwdata[23:16];
                    dmem[daddr+3] <= dwdata[31:24];
                end
            endcase
        end
    end

    always_comb begin
        drdata = 32'b0;
        if (!dwe) begin
            case (i_funct3)
                //LB
                3'b000: begin
                    drdata = {{24{dmem[daddr+0][7]}}, dmem[daddr+0]};
                end
                //LH
                3'b001: begin
                    drdata = {
                        {16{dmem[daddr+1][7]}}, dmem[daddr+1], dmem[daddr+0]
                    };
                end
                //LW
                3'b010: begin
                    drdata = {
                        dmem[daddr+3],
                        dmem[daddr+2],
                        dmem[daddr+1],
                        dmem[daddr+0]
                    };
                end
                //LBU
                3'b100: begin
                    drdata = {{24{1'b0}}, dmem[daddr+0]};
                end
                //LHU
                3'b101: begin 
                    drdata = {{16{1'b0}}, dmem[daddr+1], dmem[daddr+0]};
                end
            endcase
        end
    end

    // logic [31:0] dmem[0:31];  //word로 word address
    // always_ff @(posedge clk) begin
    //     if (dwe) begin
    //SW 전용 store 과정 
    //         if (i_funct3 == 3'b010) dmem[daddr[31:2]] <= dwdata;  //SW
    //     end
    // end

    //LW 전용 load 과정
    // assign drdata = dmem[daddr[31:2]]; //data가 byte로 오니까 밑에 2bit 짜르기 

endmodule
