`ifndef CACHE_TYPES
`define CACHE_TYPES
package arbiter_types;
typedef enum bit {
    inst = 1'b0,
    data = 1'b1
} arbdatamux_sel_t;
endpackage : arbiter_types

package cache_types;
typedef struct packed {
    logic mem_resp;
    logic[31:0] mem_rdata;
    logic[31:0] mem_wdata;
    logic[31:0] mem_address;
    logic[3:0] mem_byte_enable;
    logic mem_read;
    logic mem_write;
} cache_struct_t;

endpackage 
`endif
