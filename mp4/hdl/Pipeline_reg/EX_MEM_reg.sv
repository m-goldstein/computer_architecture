import pipe_types::*;


/* 
    Description: takes in data from decode stage, outputs data as a packed struct
                 into the execute stage
    Inputs: 
            ex_mem_alu_in        -> output from alu
            ex_mem_br_en_zext_in -> output from cmp
*/
module EX_MEM_register 
(
    input clk,
    input rst,
    input load,
    
    input [31:0] rs1_out,
    input [31:0] rs2_out,
    input [31:0] ex_mem_alu_in,
    input [31:0] ex_mem_br_en_zext_in,

    input pipe_types::pipeline_reg_t ex_mem_pipe_reg_in,
    output pipe_types::pipeline_reg_t ex_mem_pipe_reg_out
);

/* New Data Declaration */
logic [31:0] br_en_data;
logic [31:0] rs1_out_data;
logic [31:0] rs2_out_data;
rv32i_types::rv32i_word alu_out_data;
pipe_types::pipeline_reg_t pipe_reg_data;

/* NEW DATA */
assign ex_mem_pipe_reg_out.br_en           = br_en_data;
assign ex_mem_pipe_reg_out.rs1_out         = rs1_out_data;
assign ex_mem_pipe_reg_out.rs2_out         = rs2_out_data;
assign ex_mem_pipe_reg_out.alu_out         = alu_out_data;

/* OLD DATA */

/* Introduced in IF_ID Reg */
assign ex_mem_pipe_reg_out.pc_out          = pipe_reg_data.pc_out;

assign ex_mem_pipe_reg_out.opcode          = pipe_reg_data.opcode;

assign ex_mem_pipe_reg_out.funct3          = pipe_reg_data.funct3; 
assign ex_mem_pipe_reg_out.funct7          = pipe_reg_data.funct7;

assign ex_mem_pipe_reg_out.rs1             = pipe_reg_data.rs1;
assign ex_mem_pipe_reg_out.rs2             = pipe_reg_data.rs2;
assign ex_mem_pipe_reg_out.rd              = pipe_reg_data.rd;


assign ex_mem_pipe_reg_out.i_imm           = pipe_reg_data.i_imm;
assign ex_mem_pipe_reg_out.u_imm           = pipe_reg_data.u_imm;
assign ex_mem_pipe_reg_out.b_imm           = pipe_reg_data.b_imm;
assign ex_mem_pipe_reg_out.s_imm           = pipe_reg_data.s_imm;
assign ex_mem_pipe_reg_out.j_imm           = pipe_reg_data.j_imm;

assign ex_mem_pipe_reg_out.pcmux_out         = pipe_reg_data.pcmux_out ;

assign ex_mem_pipe_reg_out.inst_cache_rdata = pipe_reg_data.inst_cache_rdata;

assign ex_mem_pipe_reg_out.pop              = pipe_reg_data.pop; 

/* Introduced in ID_EX Reg */
assign ex_mem_pipe_reg_out.word            = pipe_reg_data.word;




always_ff @(posedge clk)
begin

    if (rst)
    begin
        rs1_out_data  <= '0;
        rs2_out_data  <= '0;
        br_en_data    <= '0;
        alu_out_data  <= '0;
        pipe_reg_data <= '0;
        
    end

    else if (load)
    begin
        rs1_out_data  <= rs1_out;
        rs2_out_data  <= rs2_out;
        br_en_data    <= ex_mem_br_en_zext_in;
        alu_out_data  <= ex_mem_alu_in;
        pipe_reg_data <= ex_mem_pipe_reg_in;
    end

    else
    begin
        rs1_out_data  <= rs1_out_data;
        rs2_out_data  <= rs2_out_data;
        br_en_data    <= br_en_data;
        alu_out_data  <= alu_out_data;
        pipe_reg_data <= pipe_reg_data;
    end
end

endmodule : EX_MEM_register
