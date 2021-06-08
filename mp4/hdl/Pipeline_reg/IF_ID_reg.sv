/* 
    Description: takes in a 32 bit instruction code, outputs data from
                 instruction in a packed structure
    Inputs: 
            cache_instr_rdata ->  32 bit instruction
*/
`include "pipeline_struct.sv"
//import pipe_types::*;
import rv32i_types::*;

module IF_ID_register #(parameter width = 32)
(
    input clk,
    input rst,
    input load,
    input pop_in,
    input rv32i_types::rv32i_word pcmux_out ,
    input rv32i_types::rv32i_word pc_out,
    input rv32i_types::rv32i_word inst_cache_rdata_in,   
    //input rv32i_types::rv32i_word datacache_address,       
	 //input ctrl_word::ctrl_word_t	ctrl_word,
    output pipe_types::pipeline_reg_t if_id_pipe_reg_out

);

rv32i_types::rv32i_word data;
rv32i_types::rv32i_word pcmux_out_data;
rv32i_types::rv32i_word pc_out_data; 
logic pop_data;

/* Always COMB */
assign if_id_pipe_reg_out.pc_out                = pc_out_data;

assign if_id_pipe_reg_out.opcode                = rv32i_types::rv32i_opcode'(data[6:0]);

assign if_id_pipe_reg_out.funct3                = data[14:12]; 
assign if_id_pipe_reg_out.funct7                = data[31:25];

assign if_id_pipe_reg_out.rs1                   = data[19:15];
assign if_id_pipe_reg_out.rs2                   = data[24:20];
assign if_id_pipe_reg_out.rd                    = data[11:7];

//assign if_id_pipe_reg_out.word                  = ctrl_word;
assign if_id_pipe_reg_out.i_imm                 = { {21{data[31]}}, data[30:20]};
assign if_id_pipe_reg_out.u_imm                 = { data[31:12], 12'h000};
assign if_id_pipe_reg_out.b_imm                 = { {20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign if_id_pipe_reg_out.s_imm                 = { {21{data[31]}}, data[30:25], data[11:7]};
assign if_id_pipe_reg_out.j_imm                 = { {12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};

assign if_id_pipe_reg_out.pcmux_out              = pcmux_out_data;

assign if_id_pipe_reg_out.inst_cache_rdata      = data;

assign if_id_pipe_reg_out.pop                   = pop_data;


always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
        pcmux_out_data <= '0;
        pc_out_data <= '0;
        pop_data <= '0;
    end

    else if (load)
    begin
        data <= inst_cache_rdata_in;
        pcmux_out_data <= pcmux_out;
        pc_out_data <= pc_out;
        pop_data <= pop_in;
    end

    else
    begin
        data <= data;
        pcmux_out_data <= pcmux_out_data;
        pc_out_data <= pc_out_data;
        pop_data <= pop_data;
    end
end


endmodule : IF_ID_register