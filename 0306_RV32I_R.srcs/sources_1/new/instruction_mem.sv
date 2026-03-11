`timescale 1ns / 1ps

module instruction_mem (
    //rom은 조합 출력
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom [0:31];

    initial begin
        //rom[0] = 32'h004182b3; //ADD X5, X3, X4  
        //rom[1] = 32'h402302b3; //sw x2, 2(x8), sw x2, x8, 2 
        //rom[2] = 32'h008193b3; //LW x7, x2, 2
        //rom[3] = 32'h0081a2b3; //ADDi x8, x7, 4 
//
        //rom[4] = 32'h0081b2b3; //SB x4, x13, 3
        //rom[5] = 32'h00954433; //LB x8, x4, 3
        //rom[6] = 32'h0081d3b3; //SH x5, x14, 5 
        //rom[7] = 32'h4042d333; //LH x9, x5, 5 
        //rom[8] = 32'h004161b3; //LBU x8, x7, 4 
        //rom[9] = 32'h005273b3; //LHU x8, x7, 4

        rom[0] = 32'h004182b3; //ADD X5, X3, X4  
        rom[1] = 32'h00812123; //sw x2, 2(x8), sw x2, x8, 2 
        rom[2] = 32'h00212383; //LW x7, x2, 2
        rom[3] = 32'h00438413; //ADDi x8, x7, 4 
        //rom[4] = 32'h00838463; //BEQ x7, x8, 8
        rom[4] = 32'h00840463; //BEQ x8, x8, 8
        rom[5] = 32'h004182b3; //ADD X5, X3, X4  
        rom[6] = 32'h00812123; //sw x2, 2(x8), sw x2, x8, 2 

        //rom[4] = 32'h00d201a3; //SB x4, x13, 3
        //rom[5] = 32'h00320403; //LB x8, x4, 3
        //rom[6] = 32'h00e292a3; //SH x5, x14, 5 
        //rom[7] = 32'h00529483; //LH x9, x5, 5 
        //rom[8] = 32'h00324783; //LBU x8, x7, 4 
        //rom[9] = 32'h0052d883; //LHU x8, x7, 4


        
        //rom[1] = 32'h005201b3;
    end
    //나머지는 초기화 안했으니 X로 채워짐

    //read addr 를 word addr로 변경 
    assign instr_data = rom [instr_addr[31:2]]; //우 shift 2 

endmodule
