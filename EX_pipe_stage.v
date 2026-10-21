`timescale 1ns / 1ps

module EX_pipe_stage (
    input [31:0] id_ex_instr ,
    input [31:0] reg1 , reg2 ,
    input [31:0] id_ex_imm_value ,
    input [31:0] ex_mem_alu_result ,
    input [31:0] mem_wb_write_back_result ,
    input id_ex_alu_src ,
    input [1:0] id_ex_alu_op ,
    input [1:0] Forward_A , Forward_B ,
    output [31:0] alu_in2_out ,
    output [31:0] alu_result
);

    wire [31:0] fwdA, fwdB;

    mux4 #(32) FWD_A_MUX (
        .a(reg1),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(reg1),                  
        .sel(Forward_A),
        .y(fwdA)
    );

    mux4 #(32) FWD_B_MUX (
        .a(reg2),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(reg2),                  
        .sel(Forward_B),
        .y(fwdB)
    );

    assign alu_in2_out = fwdB;
    wire [31:0] alu_b;

    mux2 #(32) ALU_SRC_MUX (
        .a(fwdB),
        .b(id_ex_imm_value),
        .sel(id_ex_alu_src),
        .y(alu_b)
    );

    wire [3:0] alu_ctl;

    ALUControl ALUCTL (
        .ALUOp(id_ex_alu_op),
        .Function(id_ex_instr[5:0]),
        .ALU_Control(alu_ctl)
    );

    wire zero_unused;
    ALU ALU0 (
        .a(fwdA),
        .b(alu_b),
        .alu_control(alu_ctl),
        .zero(zero_unused),
        .alu_result(alu_result)
    );

endmodule


