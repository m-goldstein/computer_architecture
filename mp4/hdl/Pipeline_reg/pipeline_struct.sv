`ifndef PIPE_TYPES
`define PIPE_TYPES
package pipe_types;
`define WIDTH 32
import rv32i_types::*;
import ctrl_word::*;
/* Pipeline register definition */

typedef struct packed {
    rv32i_types::rv32i_opcode opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    rv32i_types::rv32i_reg rs1;
    rv32i_types::rv32i_reg rs2;
    rv32i_types::rv32i_reg rd;
    rv32i_types::rv32i_word rs1_out;
    rv32i_types::rv32i_word rs2_out;
    rv32i_word datacache_rdata;


    logic [(`WIDTH)-1:0] i_imm;
    logic [(`WIDTH)-1:0] u_imm;
    logic [(`WIDTH)-1:0] b_imm;
    logic [(`WIDTH)-1:0] s_imm;
    logic [(`WIDTH)-1:0] j_imm;

    rv32i_types::rv32i_word alu_out;
    rv32i_types::rv32i_word cmp_out;
    logic [31:0] br_en;
    logic pop;

    rv32i_types::rv32i_word pcmux_out;  
    rv32i_types::rv32i_word datacache_address;
    rv32i_types::rv32i_word inst_cache_rdata;
    rv32i_types::rv32i_word regfilemux_out;

    logic [(`WIDTH)-1:0] pc_out;
    ctrl_word::ctrl_word_t word;
}pipeline_reg_t;

typedef struct packed {
    logic load_pc;
    logic load_if_id;
    logic load_id_ex;
    logic load_ex_mem;
    logic load_mem_wb;
}stall_load_reg_t;
endpackage : pipe_types
`endif
