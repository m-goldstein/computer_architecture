import ctrl_word::*;
import rv32i_types::*;

module core(
    input logic clk, 
    input logic rst,

    input inst_resp,
    input data_resp,
    input rv32i_word inst_rdata,
    input rv32i_word data_rdata,

    // input [1:0] arbiter_state,
    // input pmem_read,
    // input pmem_write,

    output inst_read,
    output data_read,
    output data_write,
    output [3:0] data_mbe,
    output rv32i_word inst_addr,
    output rv32i_word data_addr,
    output rv32i_word data_wdata

);

ctrl_word::ctrl_word_t ctrl_word;
rv32i_types::rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;

rv32i_word inst_addr_datapath;
rv32i_word data_addr_datapath;

assign inst_addr = {inst_addr_datapath[31:2], 2'b00};
assign data_addr = {data_addr_datapath[31:2], 2'b00};

datapath DATAPATH
(
    .clk                              (clk),    
    .rst                              (rst),
    .ctrl_word                        (ctrl_word), 
	.inst_resp					      (inst_resp),
	.data_resp					      (data_resp),
    .inst_cache_rdata                 (inst_rdata),
    .inst_cache_address               (inst_addr_datapath),

    // synthesis turn off
    // .arbiter_state                    (arbiter_state),
    // .pmem_read                        (pmem_read),
    // .pmem_write                       (pmem_write),
    // synthesis turn on

    .inst_read                        (inst_read),
    .data_read                        (data_read),
    .data_write                       (data_write),
    .opcode                           (opcode),             /*OUTPUT, datapath -> control rom*/
    .funct3                           (funct3),             /*OUTPUT, datapath -> control rom*/
    .funct7                           (funct7),             /*OUTPUT, datapath -> control rom*/
    .datacache_wdata                  (data_wdata),
    .datacache_rdata                  (data_rdata), 
    .datacache_address                (data_addr_datapath), 
    .datacache_mem_byte_enable        (data_mbe)            /*OUTPUT, datapath -> top level */
);

control_rom ctrl_rom
(
        .opcode          (opcode),
        .funct3          (funct3),
        .funct7          (funct7),
        .ctrl_word       (ctrl_word)
);

endmodule : core

