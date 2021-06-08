package waymux;
typedef enum bit{
    way0 = 1'b0,
    way1 = 1'b1
} waymux_sel_t;
endpackage

package tagmux;
typedef enum bit[1:0] {
    tag0 = 2'b01,
    tag1 = 2'b10,
    all = 2'b11,
    nan = 2'b00
} tagmux_sel_t;
endpackage

package validmux;
typedef enum bit[1:0] {
    valid0 = 2'b01,
    valid1 = 2'b10,
    all = 2'b11,
    nan = 2'b00
} validmux_sel_t;
endpackage

package hitmux;
typedef enum bit[1:0] {
    hit0 = 2'b01,
    hit1 = 2'b10,
    all = 2'b11,
    nan = 2'b00
} hitmux_sel_t;
endpackage

package datamux;
typedef enum bit {
    memory = 1'b0,
    cache = 1'b1
} datamux_sel_t;
endpackage

package dirtymux;
typedef enum bit[1:0] {
    dirty0 = 2'b01,
    dirty1 = 2'b10,
    all = 2'b11,
    nan = 2'b00
} dirtymux_sel_t;
endpackage

package sourcemux;
typedef enum bit {
    memory = 1'b0,
    cache = 1'b1
} sourcemux_sel_t;
endpackage

package destmux;
typedef enum bit {
    cpu = 1'b0,
    cache = 1'b1
} destmux_sel_t;
endpackage
package dirtysel;
typedef enum bit {
    dirty0 = 1'b0,
    dirty1 = 1'b1
} dirtysel_t;
endpackage
package cache_types;
import waymux::*;
import tagmux::*;
import dirtysel::*;
import validmux::*;
import dirtymux::*;
import hitmux::*;
import sourcemux::*;
import destmux::*;
import datamux::*;
// https://www.chipverify.com/systemverilog/systemverilog-structure
// keeping track of all these wires was giving me a headache
typedef struct packed {
    logic waymux_sel;
    logic sourcemux_sel;
    logic datamux_sel;
    logic[1:0] validmux_sel;
    logic[1:0] tagmux_sel;
    logic[1:0] dirtymux_sel;
    logic ld_lru;
    logic lru_i;
    logic dirty_i;
    logic cache_rd_en;
    logic valid_rd_en;
    logic ld_data;
    logic cache_wen;
    logic mem_resp;
    logic pmem_write;
    logic pmem_read;
} cache_control_if;
endpackage
     

interface cache_if (input clk, input rst);
    logic[31:0] mem_address;
    logic[31:0] mem_addr;
    logic[31:0] mem_wdata;
    logic[3:0] mem_byte_enable;
    logic[255:0] pmem_rdata;
    logic pmem_resp;
    logic mem_write;
    logic mem_read;
    logic [31:0] pmem_address;
    logic [31:0] mem_rdata;
    logic [255:0] pmem_wdata;
    logic mem_resp;
    logic pmem_read;
    logic pmem_write;
    
    modport cpu(
        input clk,
        input rst,
        input mem_resp,
        input mem_rdata,
        output mem_read,
        output mem_write,
        output mem_byte_enable,
        output mem_address,
        output mem_wdata,
        output mem_addr
    );
    modport cache(
        input clk,
        input rst,
        input mem_address,
        input mem_wdata,
        input mem_byte_enable,
        input pmem_rdata,
        input pmem_resp,
        input mem_read,
        input mem_write,
        output pmem_address,
        output mem_resp,
        output mem_rdata,
        output pmem_wdata,
        output pmem_read,
        output pmem_write
    );
    modport cacheline_adapter(
        input clk,
        input rst,
        output pmem_read,
        output pmem_write,
        input pmem_resp,
        output pmem_address,
        input pmem_rdata,
        output pmem_wdata
    );
endinterface

