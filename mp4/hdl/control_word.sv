`ifndef CTRL_WORD
`define CTRL_WORD
package ctrl_word;
import rv32i_types::*;

/* generic control word structure */
typedef struct packed {
    pcmux::pcmux_sel_t pcmux_sel;
    cmpmux::cmpmux_sel_t cmpmux_sel;
    alumux::alumux1_sel_t alumux1_sel;
    alumux::alumux2_sel_t alumux2_sel;
    regfilemux::regfilemux_sel_t regfilemux_sel;
    rv32i_types::alu_ops aluop;
    rv32i_types::rv32i_opcode opcode;

    logic load_pc;
    logic load_regfile;
    logic instcache_mem_read;
    logic datacache_mem_read;
    logic datacache_mem_write;
    
    logic [3:0] mem_byte_enable;
    logic [3:0] rmask;
    logic [3:0] wmask;
	logic [2:0] cmpop;
    logic trap;
} ctrl_word_t;

endpackage : ctrl_word
`endif