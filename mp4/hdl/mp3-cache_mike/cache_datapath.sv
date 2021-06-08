/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

//`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
import mike_cache_types::*;

/* Description of Signals */
/*
    cpu_address: adress cpu wants to read/write from/to in physical memory

    load_tag_0/1: Load/Write a tag request to way 0/1 of a set
    tag_way0/1_out: dataout from tag_array_way0/1, the tag you want to read

    load_valid_0/1: Request to load valid bit to way 0/1 of a set
    valid_way0/1_in: Valid bit to load into way 0/1 in a set
    valid_way0/1_out: Valid bit to read from way 0/1 in a set

    load_dirty_0/1: Request to load valid bit to way 0/1 of a set
    dirty_way0/1_in: Dirty bit to load into way 0/1 in a set
    dirty_way0/1_out: Dirty bit to read from way 0/1 in a set

    datainmux_way0/1_sel: Select between cpu data and pmem data for cache to recieve
*/

module mike_cache_datapath #(
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
    input [31:0] cpu_address,
    output logic [31:0] pmem_address,
    input logic [31:0] cpu_byte_enable,

    /* ADDRESS BITS */
    input logic [s_offset-1 : 0] offset_bits,
    input logic [s_index-1 : 0] index_bits,
    input logic [s_tag-1 : 0] tag_bits,

    /* DATA */
    input [255:0] pmem_data, 
    input [255:0] cpu_data,

    /* MUX OUTPUTS */
    output logic [255:0] cache_out_data,

    /* SELECT SIGNALS */
    input mike_cache_types::datamuxin_sel_t datainmux_way0_sel,
    input mike_cache_types::datamuxin_sel_t datainmux_way1_sel,
    input mike_cache_types::datamuxout_sel_t dataoutmux_sel,
    input mike_cache_types::bytemux_sel_t bytemux_way0_sel,
    input mike_cache_types::bytemux_sel_t bytemux_way1_sel,
    input mike_cache_types::addressmuxout_sel_t addressmuxout_sel,

    /* TAG SIGNALS */
    input  load_tag_0,
    input  load_tag_1,

    /* VALID SIGNALS */
    input  load_valid_0,
    input  load_valid_1,
    input  valid_way0_in,
    input  valid_way1_in,

    /* DIRTY SIGNALS */
    input  load_dirty_0,
    input  load_dirty_1,
    input  dirty_way0_in,
    input  dirty_way1_in,
    output dirty_way0_out,
    output dirty_way1_out,
    output dirty_set,

    /* LRU SIGNALS */
    input  lru_load,
    input  lru_in,
    output lru_out,

    /* HIT SIGNALS */
    output hit_0, hit_1, 
    output hit
);

/* ***ARRAY  OUTPUTS*** */
logic [255:0] data_way0_out;
logic [255:0] data_way1_out;

logic [s_tag-1 : 0] tag_way0_out;
logic [s_tag-1 : 0] tag_way1_out;

logic valid_way0_out;
logic valid_way1_out;

// logic dirty_way0_out;
// logic dirty_way1_out;
/*****************************************/

/* ***MUX OUTPUTS*** */
logic [31:0] write_en_way0;
logic [31:0] write_en_way1;

logic [255:0] data_way0_in;
logic [255:0] data_way1_in;
/******************************/

assign hit_0 = ((tag_way0_out == tag_bits) & valid_way0_out );
assign hit_1 = ((tag_way1_out == tag_bits) & valid_way1_out );
assign hit = hit_0 | hit_1;

assign dirty_set = (dirty_way0_out & ~lru_out) || (dirty_way1_out & lru_out);

//assign pmem_address = {cpu_address[31:5],5'b0};

/***********************************************************************************/
/******************************** Data Arrays **************************************/

/* DATA ARRAY WAY 0 */
mike_data_array #(
    .s_offset(s_offset),
    .s_index(s_index)
)
data_array_way0(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .write_en    (write_en_way0),
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (data_way0_in),
    .dataout     (data_way0_out),
    .*
);

/* DATA ARRAY WAY 1 */
mike_data_array #(
    .s_offset(s_offset),
    .s_index(s_index)
)
data_array_way1(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .write_en    (write_en_way1),
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (data_way1_in),
    .dataout     (data_way1_out),
    .*
);

/***********************************************************************************/
/******************************** Meta Arrays **************************************/

// WAY: This is a cacheline/block inside a set

/* Tag Array Way 0 */
mike_array #(
    .s_index(s_index),
    .width(s_tag)
)
tag_array_way0(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_tag_0),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (tag_bits),           
    .dataout     (tag_way0_out),
    .*           
);

/* Tag Array Way 1 */
mike_array #(
    .s_index(s_index),
    .width(s_tag)
)
tag_array_way1(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_tag_1),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (tag_bits),           
    .dataout     (tag_way1_out)           
);

/* Valid Array Way 0 */
mike_array #(
    .s_index(s_index),
    .width(1)
)
valid_array_way0(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_valid_0),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (valid_way0_in),           
    .dataout     (valid_way0_out)           
);

/* Valid Array Way 1 */
mike_array #(
    .s_index(s_index),
    .width(1)
)
valid_array_way1(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_valid_1),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (valid_way1_in),           
    .dataout     (valid_way1_out)           
);

/* Dirty Array Way 0 */
mike_array #(
    .s_index(s_index),
    .width(1)
)
dirty_array_way0(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_dirty_0),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (dirty_way0_in),           
    .dataout     (dirty_way0_out)           
);

/* Dirty Array Way 1 */
mike_array #(
    .s_index(s_index),
    .width(1)
)
dirty_array_way1(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (load_dirty_1),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (dirty_way1_in),           
    .dataout     (dirty_way1_out)           
);

/* LRU Array: Stores 1 or 0 on whether its mot recently used */
mike_array #(
    .s_index(s_index),
    .width(1)
)
lru(
    .clk         (clk),
    .rst         (rst),
    .read        (1'b1),
    .load        (lru_load),    
    .rindex      (index_bits),
    .windex      (index_bits),
    .datain      (lru_in),           
    .dataout     (lru_out)           
);

/*****************************************************************************/
/******************************** Muxes **************************************/
always_comb begin : MUXES
    
    /* DATA INPUT MUX WAY 0 */
    /* Input: */
    /* Output: */
	unique case (datainmux_way0_sel)

        mike_cache_types::pmem_data   :    data_way0_in = pmem_data;
        mike_cache_types::cpu_data    :    data_way0_in = cpu_data;

        default: data_way0_in = cpu_data;
    endcase

    /* DATA INPUT MUX WAY 1 */
    /* Input: */
    /* Output: */
	unique case (datainmux_way1_sel)

        mike_cache_types::pmem_data   :    data_way1_in = pmem_data;
        mike_cache_types::cpu_data    :    data_way1_in = cpu_data;

        default: data_way1_in = cpu_data;
    endcase

    /* DATA OUTPUT MUX  */
    /* Input: */
    /* Output: */
    /* Description: When a hit happens, select the way in the which the hit occured */
	unique case (dataoutmux_sel) 

        mike_cache_types::dataout_way0  :    cache_out_data = data_way0_out;
        mike_cache_types::dataout_way1  :    cache_out_data = data_way1_out;

        default: cache_out_data = data_way0_out;
    endcase


    /*DATA MEM_BYTE MUX WAY 0*/
    /* Input: datamux_select from control */
    /* Output: which bytes should be changed in data array */
    /* Description: */
	unique case (bytemux_way0_sel)
	 
        mike_cache_types::f_enable       :      write_en_way0 = 32'hFFFFFFFF; 
        mike_cache_types::byte_enable    :      write_en_way0 = cpu_byte_enable;
        mike_cache_types::zero_enable    :      write_en_way0 = 32'h00000000;
		  
        default: write_en_way0 = 32'h00000000;
    endcase

    /*DATA MEM_BYTE MUX WAY 1*/
    /* Input: datamux_select from control */
    /* Output: which bytes should be changed in data array */
    /* Description: */
	unique case (bytemux_way1_sel)
	 
        mike_cache_types::f_enable       :      write_en_way1 = 32'hFFFFFFFF; 
        mike_cache_types::byte_enable    :      write_en_way1 = cpu_byte_enable;
        mike_cache_types::zero_enable    :      write_en_way1 = 32'h00000000;
		
        default: write_en_way1 = 32'h00000000;
    endcase

    /*ADDRESS MUX OUT*/
    /* Input: datamux_select from control */
    /* Output: which bytes should be changed in data array */
    /* Description: */
	unique case (addressmuxout_sel)
	 
        mike_cache_types::cpu            :      pmem_address = {cpu_address[31:5],5'b0};
        mike_cache_types::cache_way0     :      pmem_address = {tag_way0_out,cpu_address[7:5],5'b0};
        mike_cache_types::cache_way1     :      pmem_address = {tag_way1_out,cpu_address[7:5],5'b0};
		
        default: pmem_address = {cpu_address[31:5],5'b0};
    endcase

end

endmodule : mike_cache_datapath
