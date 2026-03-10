`timescale 1ns / 1ps

module instruction_mem (
    //rom은 조합 출력
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom [0:31];

    initial begin
        rom[0] = 32'h004182b3; //ADD X5, X3, X4 
        rom[1] = 32'h00810123; //sw x2, 2(x8), sw x2, x8, 2 
        //rom[1] = 32'h005201b3;
    end
    //나머지는 초기화 안했으니 X로 채워짐

    //read addr 를 word addr로 변경 
    assign instr_data = rom [instr_addr[31:2]]; //우 shift 2 

endmodule
