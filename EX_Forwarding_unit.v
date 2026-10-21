`timescale 1ns / 1ps

module EX_Forwarding_unit(
    input ex_mem_reg_write,
    input [4:0] ex_mem_write_reg_addr,
    input [4:0] id_ex_instr_rs,
    input [4:0] id_ex_instr_rt,
    input mem_wb_reg_write,
    input [4:0] mem_wb_write_reg_addr,
    output reg [1:0] Forward_A,
    output reg [1:0] Forward_B
);

always @(*) begin
    Forward_A = 2'b00;
    Forward_B = 2'b00;
    if (ex_mem_reg_write &&
        (ex_mem_write_reg_addr != 5'd0) &&
        (ex_mem_write_reg_addr == id_ex_instr_rs))
        Forward_A = 2'b10;

    if (ex_mem_reg_write &&
        (ex_mem_write_reg_addr != 5'd0) &&
        (ex_mem_write_reg_addr == id_ex_instr_rt))
        Forward_B = 2'b10;

    if (mem_wb_reg_write &&
        (mem_wb_write_reg_addr != 5'd0) &&
        !(ex_mem_reg_write && (ex_mem_write_reg_addr != 5'd0) && (ex_mem_write_reg_addr == id_ex_instr_rs)) &&
        (mem_wb_write_reg_addr == id_ex_instr_rs))
        Forward_A = 2'b01;

    if (mem_wb_reg_write &&
        (mem_wb_write_reg_addr != 5'd0) &&
        !(ex_mem_reg_write && (ex_mem_write_reg_addr != 5'd0) && (ex_mem_write_reg_addr == id_ex_instr_rt)) &&
        (mem_wb_write_reg_addr == id_ex_instr_rt))
        Forward_B = 2'b01;
end

endmodule