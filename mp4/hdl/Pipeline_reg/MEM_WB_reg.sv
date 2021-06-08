/* 
    Description: takes in a 32 bit instruction code, outputs data from
                 instruction in a packed structure
    Inputs: 
            data_cache_rdata_in -> 32 bit value from data cache
*/
import ctrl_word::*;
import pipe_types::*;

module MEM_WB_register #(parameter width = 32)
(
    /* Inputs */
    input clk,
    input rst,
    input load,
    input rv32i_types::rv32i_word datacache_address, 
    input rv32i_types::rv32i_word data_cache_rdata_in,
    input pipe_types::pipeline_reg_t mem_wb_pipe_reg_in,
    
    /* Outputs */
    output pipe_types::pipeline_reg_t mem_wb_pipe_reg_out
);

/* New Data Declaration */
rv32i_types::rv32i_word datacache_address_data;   
rv32i_types::rv32i_word data_cache_rdata_data;
pipe_types::pipeline_reg_t pipe_reg_data;



/* NEW DATA */
assign mem_wb_pipe_reg_out.datacache_rdata = data_cache_rdata_data;
assign mem_wb_pipe_reg_out.datacache_address   = datacache_address_data;

/* OLD DATA */

/* Introduced in IF_ID Reg */
assign mem_wb_pipe_reg_out.pc_out           = pipe_reg_data.pc_out;

assign mem_wb_pipe_reg_out.opcode           = pipe_reg_data.opcode;



assign mem_wb_pipe_reg_out.funct3           = pipe_reg_data.funct3;
assign mem_wb_pipe_reg_out.funct7           = pipe_reg_data.funct7;
assign mem_wb_pipe_reg_out.rs1              = pipe_reg_data.rs1;
assign mem_wb_pipe_reg_out.rs2              = pipe_reg_data.rs2;
assign mem_wb_pipe_reg_out.rd               = pipe_reg_data.rd;

assign mem_wb_pipe_reg_out.i_imm            = pipe_reg_data.i_imm;
assign mem_wb_pipe_reg_out.u_imm            = pipe_reg_data.u_imm;
assign mem_wb_pipe_reg_out.b_imm            = pipe_reg_data.b_imm;
assign mem_wb_pipe_reg_out.s_imm            = pipe_reg_data.s_imm;
assign mem_wb_pipe_reg_out.j_imm            = pipe_reg_data.j_imm;

assign mem_wb_pipe_reg_out.pcmux_out         = pipe_reg_data.pcmux_out ;

assign mem_wb_pipe_reg_out.inst_cache_rdata = pipe_reg_data.inst_cache_rdata;

assign mem_wb_pipe_reg_out.pop              = pipe_reg_data.pop; 

/* Introduced in ID_EX Reg */

assign mem_wb_pipe_reg_out.word             = pipe_reg_data.word;
assign mem_wb_pipe_reg_out.rs1_out          = pipe_reg_data.rs1_out;
assign mem_wb_pipe_reg_out.rs2_out          = pipe_reg_data.rs2_out;

/* Introduced in EX_MEM Reg */

assign mem_wb_pipe_reg_out.alu_out          = pipe_reg_data.alu_out;  
assign mem_wb_pipe_reg_out.br_en            = pipe_reg_data.br_en;             

always_ff @(posedge clk)
begin
    if (rst)
        begin
            datacache_address_data <= '0;
            data_cache_rdata_data <= '0;
            pipe_reg_data <= '0;
        end 
    
    else if (load)
        begin
            datacache_address_data <= datacache_address;
            data_cache_rdata_data <= data_cache_rdata_in;
            pipe_reg_data <= mem_wb_pipe_reg_in;
        end 
    
    else
        begin
            datacache_address_data <= datacache_address_data;
            data_cache_rdata_data <= data_cache_rdata_data;
            pipe_reg_data <= pipe_reg_data;
        end
end
endmodule
