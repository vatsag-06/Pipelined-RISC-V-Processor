`timescale 1ns / 1ps

module IF_pipe_stage (
    input clk , reset ,
    input en ,
    input [9:0] branch_address ,
    input [9:0] jump_address ,
    input branch_taken ,
    input jump ,
    output [9:0] pc_plus4 ,
    output [31:0] instr
);

    reg [9:0] PC;

    wire [9:0] pc_next_plus4 = PC + 10'd4;
    wire [9:0] pc_after_branch = branch_taken ? branch_address : pc_next_plus4;
    wire [9:0] pc_next         = jump         ? jump_address   : pc_after_branch;
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 10'd0;
        else if (en)
            PC <= pc_next;
    end

    assign pc_plus4 = pc_next_plus4;
    instruction_mem IMEM (
        .read_addr(PC),
        .data(instr)
    );

endmodule