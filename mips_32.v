`timescale 1ns / 1ps
module mips_32(
    input clk, reset,
    output [31:0] result
    );

wire [9:0] if_branch_addr;
wire [9:0] if_jump_addr;
wire if_branch_taken;
wire if_jump_sig;
wire [9:0] if_pc4;
wire [31:0] if_instr;

wire [9:0] id_pc4_reg;
wire [31:0] id_instr_reg;

wire stall_sig;

wire [31:0] id_rs_data;
wire [31:0] id_rt_data;
wire [31:0] id_imm_ext;
wire [4:0]  id_dst;
wire id_m2r;
wire [1:0] id_alu_ctrl;
wire id_mem_r;
wire id_mem_w;
wire id_src_sel;
wire id_wr_en;

wire [31:0] ex_instr_reg;
wire [31:0] ex_rs_data;
wire [31:0] ex_rt_data;
wire [31:0] ex_imm_ext;
wire [4:0]  ex_dst;
wire ex_m2r;
wire [1:0] ex_alu_ctrl;
wire ex_mem_r;
wire ex_mem_w;
wire ex_src_sel;
wire ex_wr_en;

wire [1:0] fwdA;
wire [1:0] fwdB;
wire [31:0] ex_alu_inB;
wire [31:0] ex_alu_out;

wire [31:0] mem_instr_reg;
wire [31:0] mem_alu_out;
wire [31:0] mem_wdata;
wire [4:0]  mem_dst;
wire mem_m2r;
wire mem_rd;
wire mem_wr;
wire mem_reg_wr;

wire [31:0] mem_rdata;

wire [31:0] wb_alu_out;
wire [31:0] wb_mem_out;
wire wb_m2r;
wire wb_reg_wr;
wire [4:0] wb_dst;

wire [31:0] wb_data;

assign result = wb_data;

IF_pipe_stage IF_unit(
    .clk(clk),
    .reset(reset),
    .en(stall_sig),
    .branch_address(if_branch_addr),
    .jump_address(if_jump_addr),
    .branch_taken(if_branch_taken),
    .jump(if_jump_sig),
    .pc_plus4(if_pc4),
    .instr(if_instr)
);

pipe_reg_en #(32) IF_ID_2(
    .clk(clk),
    .reset(reset),
    .en(stall_sig),
    .flush(IF_FLUSH),
    .d(if_instr),
    .q(id_instr_reg)
);

pipe_reg_en #(10) IF_ID_1(
    .clk(clk),
    .reset(reset),
    .en(stall_sig),
    .flush(IF_FLUSH),
    .d(if_pc4),
    .q(id_pc4_reg)
);

ID_pipe_stage ID(
    .clk(clk),
    .reset(reset),
    .pc_plus4(id_pc4_reg),
    .instr(id_instr_reg),
    .mem_wb_reg_write(wb_reg_wr),
    .mem_wb_write_reg_addr(wb_dst),
    .mem_wb_write_back_data(wb_data),
    .Data_Hazard(stall_sig),
    .Control_Hazard(IF_FLUSH),
    .reg1(id_rs_data),
    .reg2(id_rt_data),
    .imm_value(id_imm_ext),
    .branch_address(if_branch_addr),
    .jump_address(if_jump_addr),
    .branch_taken(if_branch_taken),
    .destination_reg(id_dst),
    .mem_to_reg(id_m2r),
    .alu_op(id_alu_ctrl),
    .mem_read(id_mem_r),
    .mem_write(id_mem_w),
    .alu_src(id_src_sel),
    .reg_write(id_wr_en),
    .jump(if_jump_sig)
);

pipe_reg #(1)  ID_EX_11(.clk(clk),.reset(reset),.d(id_wr_en),.q(ex_wr_en));
pipe_reg #(1)  ID_EX_10(.clk(clk),.reset(reset),.d(id_src_sel),.q(ex_src_sel));
pipe_reg #(1)  ID_EX_9 (.clk(clk),.reset(reset),.d(id_mem_w),.q(ex_mem_w));
pipe_reg #(1)  ID_EX_8 (.clk(clk),.reset(reset),.d(id_mem_r),.q(ex_mem_r));
pipe_reg #(2)  ID_EX_7 (.clk(clk),.reset(reset),.d(id_alu_ctrl),.q(ex_alu_ctrl));
pipe_reg #(1)  ID_EX_6 (.clk(clk),.reset(reset),.d(id_m2r),.q(ex_m2r));
pipe_reg #(5)  ID_EX_5 (.clk(clk),.reset(reset),.d(id_dst),.q(ex_dst));
pipe_reg #(32) ID_EX_4 (.clk(clk),.reset(reset),.d(id_imm_ext),.q(ex_imm_ext));
pipe_reg #(32) ID_EX_3 (.clk(clk),.reset(reset),.d(id_rt_data),.q(ex_rt_data));
pipe_reg #(32) ID_EX_2 (.clk(clk),.reset(reset),.d(id_rs_data),.q(ex_rs_data));
pipe_reg #(32) ID_EX_1 (.clk(clk),.reset(reset),.d(id_instr_reg),.q(ex_instr_reg));

EX_Forwarding_unit EXFU(
    .ex_mem_reg_write(mem_reg_wr),
    .ex_mem_write_reg_addr(mem_dst),
    .id_ex_instr_rs(ex_instr_reg[25:21]),
    .id_ex_instr_rt(ex_instr_reg[20:16]),
    .mem_wb_reg_write(wb_reg_wr),
    .mem_wb_write_reg_addr(wb_dst),
    .Forward_A(fwdA),
    .Forward_B(fwdB)
);

Hazard_detection HD(
    .id_ex_mem_read(ex_mem_r),
    .id_ex_destination_reg(ex_dst),
    .if_id_rs(id_instr_reg[25:21]),
    .if_id_rt(id_instr_reg[20:16]),
    .branch_taken(if_branch_taken),
    .jump(if_jump_sig),
    .Data_Hazard(stall_sig),
    .IF_Flush(IF_FLUSH)
);

EX_pipe_stage EX(
    .id_ex_instr(ex_instr_reg),
    .reg1(ex_rs_data),
    .reg2(ex_rt_data),
    .id_ex_imm_value(ex_imm_ext),
    .ex_mem_alu_result(mem_alu_out),
    .mem_wb_write_back_result(wb_data),
    .id_ex_alu_src(ex_src_sel),
    .id_ex_alu_op(ex_alu_ctrl),
    .Forward_A(fwdA),
    .Forward_B(fwdB),
    .alu_in2_out(ex_alu_inB),
    .alu_result(ex_alu_out)
);

pipe_reg #(1)  EX_MEM_8(.clk(clk),.reset(reset),.d(ex_wr_en),.q(mem_reg_wr));
pipe_reg #(1)  EX_MEM_7(.clk(clk),.reset(reset),.d(ex_mem_w),.q(mem_wr));
pipe_reg #(1)  EX_MEM_6(.clk(clk),.reset(reset),.d(ex_mem_r),.q(mem_rd));
pipe_reg #(1)  EX_MEM_5(.clk(clk),.reset(reset),.d(ex_m2r),.q(mem_m2r));
pipe_reg #(32) EX_MEM_4(.clk(clk),.reset(reset),.d(ex_alu_inB),.q(mem_wdata));
pipe_reg #(32) EX_MEM_3(.clk(clk),.reset(reset),.d(ex_alu_out),.q(mem_alu_out));
pipe_reg #(5)  EX_MEM_2(.clk(clk),.reset(reset),.d(ex_dst),.q(mem_dst));
pipe_reg #(32) EX_MEM_1(.clk(clk),.reset(reset),.d(ex_instr_reg),.q(mem_instr_reg));

data_memory data_mem(
    .clk(clk),
    .mem_access_addr(mem_alu_out),
    .mem_write_data(mem_wdata),
    .mem_write_en(mem_wr),
    .mem_read_en(mem_rd),
    .mem_read_data(mem_rdata)
);

pipe_reg #(5)  MEM_WB_5(.clk(clk),.reset(reset),.d(mem_dst),.q(wb_dst));
pipe_reg #(1)  MEM_WB_4(.clk(clk),.reset(reset),.d(mem_reg_wr),.q(wb_reg_wr));
pipe_reg #(1)  MEM_WB_3(.clk(clk),.reset(reset),.d(mem_m2r),.q(wb_m2r));
pipe_reg #(32) MEM_WB_2(.clk(clk),.reset(reset),.d(mem_rdata),.q(wb_mem_out));
pipe_reg #(32) MEM_WB_1(.clk(clk),.reset(reset),.d(mem_alu_out),.q(wb_alu_out));

mux2 #(.mux_width(32)) WB(
    .a(wb_alu_out),
    .b(wb_mem_out),
    .sel(wb_m2r),
    .y(wb_data)
);

endmodule
