
import cache_types::*;
/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input logic[31:0] mem_address,
    input logic[31:0] mem_wdata,
    input logic[3:0] mem_byte_enable,
    input logic[255:0] pmem_rdata,
    input logic pmem_resp,
    input logic mem_read,
    input logic mem_write,
    output logic[31:0] pmem_address,
    output logic[31:0] mem_rdata,
    output logic[255:0] pmem_wdata,
    output logic mem_resp,
    output logic pmem_read,
    output logic pmem_write
);
logic[255:0] mem_wdata256;
logic[255:0] mem_rdata256;
logic[31:0] mem_byte_enable256;
cache_types::cache_control_if ccif;
assign mem_resp = ccif.mem_resp;
assign pmem_read = ccif.pmem_read;
assign pmem_write = ccif.pmem_write;
hitmux::hitmux_sel_t hitmux_sel;
tagmux::tagmux_sel_t tagmux_sel;
validmux::validmux_sel_t validmux_sel;
datamux::datamux_sel_t datamux_sel;
logic ld_lru;
logic hit;
logic valid_rd_en;
logic sigdirty;
logic[1:0] sighit;
logic siglru;
waymux::waymux_sel_t waymux_sel;
dirtymux::dirtymux_sel_t dirtymux_sel;
logic dirty_i;
logic cache_rd_en;
sourcemux::sourcemux_sel_t sourcemux_sel;
logic cache_wen;
logic ld_data;
logic sigvalid;
assign pmem_wdata = mem_rdata256;
logic[23:0] tag;
logic[2:0] index;
logic[255:0] __mem_rdata256;
cache_control control
(
    .clk(clk),
    .rst(rst),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .pmem_resp(pmem_resp),
    .sighit(sighit),
    .sigvalid(sigvalid),
    .sigdirty(sigdirty),
    .siglru(siglru),
    .ccif(ccif)
    //.waymux_sel(waymux_sel),
    //.pmem_read(ccif.pmem_read),
    //.pmem_write(ccif.pmem_write),
    //.mem_resp(ccif.mem_resp),
    //sourcemux_sel(sourcemux_sel),
    //.datamux_sel(datamux_sel),
    //.ld_data(ld_data),
    //.ld_lru(ld_lru),
    //.valid_rd_en(valid_rd_en),
    //.cache_wen(cache_wen),
    //.cache_rd_en(cache_rd_en),
    //.tagmux_sel(tagmux_sel),
    //.validmux_sel(validmux_sel),
    //.dirtymux_sel(dirtymux_sel)
);
/*
always_comb begin
    $display("cpu_mem_resp: %d\npmem_resp: %d\n", mem_resp, pmem_resp);
    $display("mem_address: %x\n", mem_address);
    $display("pmem_address: %x\n", pmem_address);
end
*/
cache_datapath datapath
(
    .clk(clk),
    .rst(rst),
    .mem_address(mem_address),
    .ccif(ccif),
    //.validmux_sel(validmux_sel),
    //.tagmux_sel(tagmux_sel),
    //.datamux_sel(datamux_sel),
    //.dirtymux_sel(dirtymux_sel),
    //.ld_lru(ld_lru),
    //.valid_rd_en(valid_rd_en),
    //.cache_wen(cache_wen),
    .sighit(sighit),
    .siglru(siglru),
    .sigvalid(sigvalid),
    //.waymux_sel(waymux_sel),
    //.cache_rd_en(cache_rd_en),
    .mem_byte_enable256(mem_byte_enable256),
    .pmem_rdata(pmem_rdata),
    .pmem_address(pmem_address),
    .sigdirty(sigdirty),
    //.sourcemux_sel(sourcemux_sel),
    //.ld_data(ld_data),
    .tag(tag),
    .index(index),
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(__mem_rdata256)
);
always_ff @ (posedge clk) begin
    mem_rdata256 <= __mem_rdata256;
end
bus_adapter bus_adapter
(
    .address(mem_address),
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(__mem_rdata256),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata)
);
//always_comb begin
//$display("mem_address: %x\nmem_wdata256: %x\nmem_rdata256: %x\nmem_byte_enable: %x\nmem_byte_enable256: %x\nmem_wdata: %x\nmem_rdata: %x\n", mem_address, mem_wdata256, mem_rdata256, mem_byte_enable, mem_byte_enable256, mem_wdata, mem_rdata);
//end
endmodule : cache
