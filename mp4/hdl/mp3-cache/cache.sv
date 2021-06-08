import rv32i_types::*;
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
	input logic [3:0] mem_byte_enable,
    input rv32i_word mem_address,
	input logic mem_read,
    input logic mem_write,
	input rv32i_word mem_wdata,
	input logic pmem_resp,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	output rv32i_word mem_rdata,
	output mem_resp,
    output pmem_read,
    output pmem_write,
	output logic [31:0] pmem_address
);

logic [23:0] tag1;
logic [23:0] tag2; 
logic [1:0] valid;
logic tag_load_1;
logic tag_load_2;  
logic dirty_bit1;
logic dirty_bit2;
logic dirty_load_1;
logic dirty_load_2;
logic dirty_datain_1;
logic dirty_datain_2;
logic lru;
logic lru_load;
logic lru_datain;
logic valid_load;
logic [1:0] valid_in;
logic data_way_sel;
logic pmem_address_sel;
logic data1_datain_sel;
logic data2_datain_sel;
logic [1:0] data1_write_en_sel;
logic [1:0] data2_write_en_sel;
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;
logic [255:0] data_way_out;
assign pmem_wdata = data_way_out;
assign mem_rdata256 = data_way_out;
logic hit_status; 
logic dirty_status; 
logic hit1;
logic hit2;

always_comb begin 
	if(lru == 1'b1)
		dirty_status = dirty_bit1;
	else 
		dirty_status = dirty_bit2;
	if(tag1 == mem_address[31:8] && valid[0] == 1'b1)
		hit1 = 1'b1;
	else
		hit1 = 1'b0;
	if(tag2 == mem_address[31:8] && valid[1] == 1'b1)
		hit2 = 1'b1;
	else
		hit2 = 1'b0;
end 
assign hit_status = hit1 | hit2; 

cache_control control(.*);

cache_datapath datapath(.*);

bus_adapter bus_adapter
(
      .mem_wdata256(mem_wdata256),
      .mem_rdata256(mem_rdata256),
      .mem_wdata(mem_wdata),
      .mem_rdata(mem_rdata),
      .mem_byte_enable(mem_byte_enable),
      .mem_byte_enable256(mem_byte_enable256),
      .address(mem_address)
);

endmodule : cache
