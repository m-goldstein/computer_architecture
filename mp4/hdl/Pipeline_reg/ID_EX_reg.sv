/* 
    Description: takes in data from decode stage, outputs data as a packed struct
                 into the execute stage
    Inputs: 
            word     -> control word from control rom
            instr    -> pc_out
            pipe_reg -> old strucure data
*/
import pipe_types::*;


module ID_EX_register #(parameter width = 32)
(
    input clk,
    input rst,
    input load,

    input rv32i_types::rv32i_word rs1_out,
    input rv32i_types::rv32i_word rs2_out,  
    input ctrl_word::ctrl_word_t id_ex_word_in,
    input pipe_types::pipeline_reg_t id_ex_pipe_reg_in,

    output pipe_types::pipeline_reg_t id_ex_pipe_reg_out
);

/* New Data Declaration */
logic [width - 1:0] rs1_out_data;
logic [width - 1:0] rs2_out_data;
ctrl_word::ctrl_word_t word_data; 
pipe_types::pipeline_reg_t pipe_reg_data;

/* NEW DATA */
assign id_ex_pipe_reg_out.word    = word_data;
assign id_ex_pipe_reg_out.rs1_out = rs1_out_data;
assign id_ex_pipe_reg_out.rs2_out = rs2_out_data;

/* OLD DATA */
assign id_ex_pipe_reg_out.pc_out       = pipe_reg_data.pc_out;

assign id_ex_pipe_reg_out.opcode       = rv32i_types::rv32i_opcode'(pipe_reg_data.opcode);



assign id_ex_pipe_reg_out.funct3           = pipe_reg_data.funct3; 
assign id_ex_pipe_reg_out.funct7           = pipe_reg_data.funct7;
assign id_ex_pipe_reg_out.rs1              = pipe_reg_data.rs1;
assign id_ex_pipe_reg_out.rs2              = pipe_reg_data.rs2;
assign id_ex_pipe_reg_out.rd               = pipe_reg_data.rd;


assign id_ex_pipe_reg_out.i_imm            = pipe_reg_data.i_imm;
assign id_ex_pipe_reg_out.u_imm            = pipe_reg_data.u_imm;
assign id_ex_pipe_reg_out.b_imm            = pipe_reg_data.b_imm;
assign id_ex_pipe_reg_out.s_imm            = pipe_reg_data.s_imm;
assign id_ex_pipe_reg_out.j_imm            = pipe_reg_data.j_imm;

assign id_ex_pipe_reg_out.pcmux_out          = pipe_reg_data.pcmux_out ;

assign id_ex_pipe_reg_out.inst_cache_rdata = pipe_reg_data.inst_cache_rdata;

assign id_ex_pipe_reg_out.pop              = pipe_reg_data.pop; 


always_ff @(posedge clk)
begin
    if (rst)
    begin
        rs1_out_data  <= '0;
        rs2_out_data  <= '0;
        word_data     <= '0;
        pipe_reg_data <= '0;
    end

    else if (load)
    begin
        rs1_out_data  <= rs1_out;
        rs2_out_data  <= rs2_out;
        word_data     <= id_ex_word_in;
        pipe_reg_data <= id_ex_pipe_reg_in;
    end

    else
    begin
        rs1_out_data  <= rs1_out_data;
        rs2_out_data  <= rs2_out_data;
        word_data     <= word_data;
        pipe_reg_data <= pipe_reg_data;
    end
end

endmodule : ID_EX_register
