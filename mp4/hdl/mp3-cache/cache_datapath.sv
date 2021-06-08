/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
module cache_datapath #(
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
		input logic [31:0] mem_address,
      input logic [255:0] pmem_rdata,
      input logic [255:0] mem_wdata256,
      input logic [31:0] mem_byte_enable256,
      input logic tag_load_1,
      input logic tag_load_2,
      input logic dirty_load_1,
      input logic dirty_load_2,
		input logic dirty_datain_1,
      input logic dirty_datain_2,
      input logic lru_load,
      input logic lru_datain,
      input logic valid_load,
      input logic [1:0] valid_in,
      input logic [1:0] data1_write_en_sel,
      input logic [1:0]  data2_write_en_sel,
		input logic data1_datain_sel,
      input logic data2_datain_sel,
      input logic data_way_sel,
      input logic pmem_address_sel,
      output logic [31:0] pmem_address,
      output logic [255:0] data_way_out,
		output logic [23:0] tag1,
      output logic [23:0] tag2,
      output logic dirty_bit1,
      output logic dirty_bit2,
      output logic lru,
      output logic [1:0] valid
);

logic [23:0] lru_tag;
logic [255:0] way1_datain;
logic [255:0] way1_dataout;
logic [31:0] way1_write_en;
logic [255:0] way2_datain;
logic [255:0] way2_dataout;
logic [31:0] way2_write_en;

cache_datapath_muxes muxes(.*);

data_array way1
(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .write_en(way1_write_en),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(way1_datain),
      .dataout(way1_dataout)
);


data_array way2
(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .write_en(way2_write_en),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(way2_datain),
      .dataout(way2_dataout)
);


array #(.s_index(3), .width(1))
LRU(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(lru_load),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(lru_datain),
      .dataout(lru)
);

array #(.s_index(3), .width(2))
valid_array(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(valid_load),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(valid_in),
      .dataout(valid)
);

array #(.s_index(3), .width(1))
dirty_array1(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(dirty_load_1),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(dirty_datain_1),
      .dataout(dirty_bit1)
);

array #(.s_index(3), .width(1))
dirty_array2(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(dirty_load_2),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(dirty_datain_2),
      .dataout(dirty_bit2)
);

array #(.s_index(3), .width(24))
tag_array1 (
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(tag_load_1),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(mem_address[31:8]),
      .dataout(tag1)
);

array  #(.s_index(3), .width(24))
tag_array2 (
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(tag_load_2),
      .rindex(mem_address[7:5]),
      .windex(mem_address[7:5]),
      .datain(mem_address[31:8]),
      .dataout(tag2)
);



endmodule : cache_datapath