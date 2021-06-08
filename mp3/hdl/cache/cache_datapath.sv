/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
import cache_types::*;
`define TAG_MASK    32'hFFFFFE00
`define INDEX_MASK  32'h000000E0
`define OFFSET_MASK 32'h0000001F
`define TAG_BITS    \
    24'((mem_address & (`TAG_MASK)) >> 9);
`define INDEX_BITS    \
    3'((mem_address & (`INDEX_MASK)) >> 5);
`define OFFSET_BITS    \
    5'((mem_address & (`OFFSET_MASK)) >> 0);

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
    input logic[31:0] mem_address,
    input logic[255:0] mem_wdata256,
    input logic[255:0] pmem_rdata,
    input logic[31:0] mem_byte_enable256,
    input cache_types::cache_control_if ccif,
    output logic[23:0] tag,
    output logic[2:0] index,
    output logic sigdirty,
    output logic[1:0] sighit,
    output logic siglru,
    output logic sigvalid,
    output logic[255:0] mem_rdata256,
    output logic[31:0] pmem_address
);
logic[23:0] tag_bits;
logic[4:0] offset_bits;
logic valid_out_0, valid_out_1;
logic[23:0] tag_out_0;
logic[23:0] tag_out_1;
logic[255:0] data_out[1:0];
logic[255:0] sourcemux_out;
logic[31:0] data0_i;
logic[31:0] data1_i;
logic[1:0] dirty_arrays_out;

assign tag_bits = mem_address[31:8];//`TAG_BITS
assign index = mem_address[7:5];//`INDEX_BITS
assign offset_bits = mem_address[4:0];//`OFFSET_BITS
assign sigvalid = (valid_out_0 && valid_out_1);

/* 2x valid arrays */
array valid_array_0
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.validmux_sel == 2'b01),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(1'b1),
    .dataout(valid_out_0)
);
array valid_array_1
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.validmux_sel == 2'b10),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(1'b1),
    .dataout(valid_out_1)
);

/* 2x dirty arrays */
array dirty_array_0
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.dirtymux_sel == 2'b01),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(ccif.dirty_i),
    .dataout(dirty_arrays_out[0])
);

array dirty_array_1
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.dirtymux_sel == 2'b10),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(ccif.dirty_i),
    .dataout(dirty_arrays_out[1])
);

/* 2x tag arrays */
array #(.width(24)) tag_array_0
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load((ccif.tagmux_sel == 2'b01)),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(tag_bits),
    .dataout(tag_out_0)
);
array #(.width(24)) tag_array_1
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.tagmux_sel == 2'b10),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(tag_bits),
    .dataout(tag_out_1)
);

/* 2x data arrays */
data_array data_array_0
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .write_en(data0_i),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(sourcemux_out),
    .dataout(data_out[0])
);
data_array data_array_1
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .write_en(data1_i),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(sourcemux_out),
    .dataout(data_out[1])
);

/* 1x lru */
array lru
(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(ccif.ld_lru),
    .rindex({{index}}),
    .windex({{index}}),
    .datain(ccif.lru_i),
    .dataout(siglru)
);
assign sighit[1] = valid_out_1 && (tag_out_1 == tag_bits); //{valid_out_1 && (tag_out_1 == tag_bits)};
assign sighit[0] = valid_out_0 && (tag_out_0 == tag_bits);
always_ff@(posedge clk) begin

//    $display("[datapath %d] pmem_address=%x",$time,pmem_address);
//    $display("[datapath %d] pmem_rdata: %x\nmem_wdata256: %x",$time,pmem_rdata,mem_wdata256);
//    $display("[datapath %d] sourcemux_sel: %x\nsourcemux_out: %x",$time, ccif.sourcemux_sel, sourcemux_out);
//    $display("[datapath %d] mem_rdata256: %x",$time, mem_rdata256);
//    $display("[datapath %d] data_out[0]: %x\n[datapath] data_out[1]: %x",$time, data_out[0], data_out[1]);
//    $display("[datapath %d] mem_rdata256 :%x", $time, mem_rdata256);
//    $display("[datapath %d] waymux_sel: %x\tsiglru: %x\tld: %x\tdatamux_sel %x\n",$time, ccif.waymux_sel ,siglru, ccif.ld_data, ccif.datamux_sel);
//    $display("[datapath] data0_i: %x\tdata1_i: %x", data0_i, data1_i);
//    $display("[datapath] tagmux_sel: %x", ccif.tagmux_sel);
//    $display("[datapath] tag_out: %x\t %x", tag_out_0, tag_out_1);
end
//assign mem_rdata256 = data_out[ccif.waymux_sel];
always_comb begin
    sigdirty = dirty_arrays_out[ccif.waymux_sel];
    mem_rdata256 = data_out[ccif.waymux_sel];//data_out[ccif.waymux_sel]; 
    tag = (ccif.waymux_sel) ? tag_out_1 : tag_out_0;
    sourcemux_out = (ccif.datamux_sel == 1'b0) ? mem_wdata256 : pmem_rdata;
    //tag = (ccif.waymux_sel) ? tag_out_1 : tag_out_0 ;//[ccif.waymux_sel];
    if (ccif.ld_data) begin
        unique case( {ccif.waymux_sel, ccif.datamux_sel})
            2'b00: begin
               // $display("0 %d", $time);
                data0_i = mem_byte_enable256;
                data1_i = 32'h0;
            end
            2'b01: begin
               // $display("1 %d", $time);
                data0_i = 32'hffffffff;
                data1_i = 32'h0;
            end
            2'b10: begin
                //$display("2 %d", $time);
                //data0_i = mem_byte_enable256;
                data0_i = 32'h0;
                data1_i = mem_byte_enable256;
            end
            2'b11: begin
                //$display("3 %d", $time);
                data0_i = 32'h0;
                data1_i = 32'hffffffff;
            end
            default: begin
                //$display("4 %d", $time);
                data0_i = 32'd0;
                data1_i = 32'd0;
            end
        endcase
    end else begin
        data0_i = 32'h0;
        data1_i = 32'h0;
    end
    case (ccif.sourcemux_sel)
        1'b0:  pmem_address= {mem_address & (32'hFFFFFFE0)};
        1'b1: pmem_address = {tag, index, 5'd0};
        default:; 
    endcase
end
endmodule : cache_datapath
