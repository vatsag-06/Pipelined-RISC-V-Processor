`timescale 1ns / 1ps

module ID_pipe_stage(
    input  clk, reset,
    input  [9:0] pc_plus4,
    input  [31:0] instr,
    input  mem_wb_reg_write,
    input  [4:0] mem_wb_write_reg_addr,
    input  [31:0] mem_wb_write_back_data,
    input  Data_Hazard,
    input  Control_Hazard,
    output [31:0] reg1, reg2,
    output [31:0] imm_value,
    output [9:0] branch_address,
    output [9:0] jump_address,
    output branch_taken,
    output [4:0] destination_reg,
    output mem_to_reg,
    output [1:0] alu_op,
    output mem_read,
    output mem_write,
    output alu_src,
    output reg_write,
    output jump
    );

wire c_regdst, c_branch;
wire c_m2r, c_mrd, c_mwr, c_asrc, c_rwe;
wire [1:0] c_aluop;

wire [31:0] rf_r1, rf_r2;
wire [31:0] se_imm;

wire kill_ctrl;

assign reg1      = rf_r1;
assign reg2      = rf_r2;
assign imm_value = se_imm;

assign jump_address   = instr[25:0] << 2;
assign branch_address = (se_imm << 2) + pc_plus4;
assign branch_taken   = (c_branch & ((reg1 ^ reg2) == 32'd0)) ? 1'b1 : 1'b0;

assign kill_ctrl = ~(Data_Hazard) | Control_Hazard;

register_file rf(
    .clk(clk),
    .reset(reset),
    .reg_write_en(mem_wb_reg_write),
    .reg_write_dest(mem_wb_write_reg_addr),
    .reg_write_data(mem_wb_write_back_data),
    .reg_read_addr_1(instr[25:21]),
    .reg_read_addr_2(instr[20:16]),
    .reg_read_data_1(rf_r1),
    .reg_read_data_2(rf_r2)
);

control controller(
    .reset(reset),
    .opcode(instr[31:26]),
    .reg_dst(c_regdst),
    .mem_to_reg(c_m2r),
    .alu_op(c_aluop),
    .mem_read(c_mrd),
    .mem_write(c_mwr),
    .alu_src(c_asrc),
    .reg_write(c_rwe),
    .branch(c_branch),
    .jump(jump)
);

sign_extend s1(
    .sign_ex_in(instr[15:0]),
    .sign_ex_out(se_imm)
);

mux2 #(.mux_width(5)) m1(
    .a(instr[20:16]),
    .b(instr[15:11]),
    .sel(c_regdst),
    .y(destination_reg)
);

mux2 #(.mux_width(1)) m7(
    .a(c_rwe),
    .b(1'b0),
    .sel(kill_ctrl),
    .y(reg_write)
);

mux2 #(.mux_width(1)) m6(
    .a(c_asrc),
    .b(1'b0),
    .sel(kill_ctrl),
    .y(alu_src)
);

mux2 #(.mux_width(1)) m5(
    .a(c_mwr),
    .b(1'b0),
    .sel(kill_ctrl),
    .y(mem_write)
);

mux2 #(.mux_width(1)) m4(
    .a(c_mrd),
    .b(1'b0),
    .sel(kill_ctrl),
    .y(mem_read)
);

mux2 #(.mux_width(2)) m3(
    .a(c_aluop),
    .b(2'b0),
    .sel(kill_ctrl),
    .y(alu_op)
);

mux2 #(.mux_width(1)) m2(
    .a(c_m2r),
    .b(1'b0),
    .sel(kill_ctrl),
    .y(mem_to_reg)
);

endmodule
