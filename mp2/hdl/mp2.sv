import rv32i_types::*;

module mp2
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_regfile;
/*****************************************************************************/
logic[2:0] funct3;
logic[6:0] funct7;
logic br_en;
logic[4:0] rs1;
logic[4:0] rs2;
logic load_ir;
logic load_mdr;
logic load_data_out;
alu_ops aluop;
branch_funct3_t cmpop;
logic load_mar;
rv32i_opcode opcode;
logic[1:0] mem_addr_mask;
logic[1:0] alu_mask;
logic[1:0] mar_mask;
/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
/*****************************************************************************/

/* Instantiate MP 1 top level blocks here */

// Keep control named `control` for RVFI Monitor
control control(.*);
datapath datapath(.*);
/*control control(
	.clk		(clk),
	.rst		(rst),
	.opcode 	(opcode),
	.funct3	(funct3),
	.funct7	(funct7),
	.br_en	(br_en),
	.rs1		(rs1),
	.rs2		(rs2),
	.pcmux_sel	(pcmux_sel),
	.alumux1_sel(alumux1_sel),
	.alumux2_sel(alumux2_sel),
	.regfilemux_sel	(regfilemux_sel),
	.marmux_sel (marmux_sel),
	.cmpmux_sel (cmpmux_sel),
	.aluop	(aluop),
	.load_pc (load_pc),
	.load_regfile (load_regfile),
	.load_ir (load_ir),
	.load_mar (load_mar),
	.load_mdr (load_mdr),
	.load_data_out(load_data_out),
	.mem_resp(mem_resp),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.cmpop (cmpop),
	.mem_byte_enable(mem_byte_enable)
);
// Keep datapath named `datapath` for RVFI Monitor
//datapath datapath(.*);
datapath datapath(
	.clk		(clk),
	.rst		(rst),
	.load_mdr (load_mdr),
	.mem_rdata (mem_rdata),
	.mem_wdata (mem_wdata),
	.load_pc (load_pc),
	.load_ir (load_ir),
	.load_mar (load_mar),
	.load_regfile (load_regfile),
	.load_data_out (load_data_out),
	.pcmux_sel (pcmux_sel),
	.alumux1_sel (alumux1_sel),
	.alumux2_sel (alumux2_sel),
	.regfilemux_sel (regfilemux_sel),
	.marmux_sel (marmux_sel),
	.cmpmux_sel (cmpmux_sel),
	.aluop (aluop),
	.opcode (opcode),
	.funct3 (funct3),
	.funct7 (funct7),
	.br_en (br_en),
	.rs1 (rs1),
	.rs2 (rs2),
	.cmpop (cmpop),
	.mem_address (mem_address)
);*/

endmodule : mp2
