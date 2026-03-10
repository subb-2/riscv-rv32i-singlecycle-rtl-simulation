`timescale 1ns / 1ps

module data_mem (
    input         clk,
    input         rst,
    input         dwe,
    input  [31:0] daddr,
    input  [31:0] dwdata,
    output [31:0] drdata
);

//    logic [7:0] dmem[0:31];
//
//    always_ff @(posedge clk) begin
//
//        if (dwe) begin
//            //store word 일 때만, 이렇게? 
//            dmem[daddr+0] <= dwdata[7:0];
//            dmem[daddr+1] <= dwdata[15:8];
//            dmem[daddr+2] <= dwdata[23:16];
//            dmem[daddr+3] <= dwdata[31:24];
//        end
//    end
//
//    assign drdata = {
//        dmem[daddr], dmem[daddr+1], dmem[daddr+2], dmem[daddr+3]
//    };

    logic [31:0] dmem[0:31]; //word로 word address
    always_ff @( posedge clk ) begin
        if (dwe) begin
            dmem[daddr[31:2]] <= dwdata; 
        end
    end

    assign drdata = dmem[daddr[31:2]]; //data가 byte로 오니까 밑에 2bit 짜르기 

endmodule
