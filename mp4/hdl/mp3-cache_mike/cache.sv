/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */
import mike_cache_types::*;

/* NOTES */
/*
    -cacheline in comments refer to caheline adaptor
*/

/* Description of Signals */
/*
    mem_read_i: memory request signal from CPU
    mem_read_o: memory request signal from cache, if miss
    mem_rdata: 32 bit Output from bus, goes to CPU
    mem_rdata256: 256 data from physical memory, comes from cacheline adaptor as line_o
    mem_byte_enable: Used by Bus adaptor, tells us which byte in 4byte address to read/write
    cache_resp_i: Physical memory response signal from cacheline adaptor
    cache_resp_o: Caches response signal to CPU

    //***Signals for Autograder***\\\ 
    pmem_resp: Ready response signal from physical memory
    pmem_rdata: data read from physical memory
    pmem_wdata: data to be written to physical memory
    pmem_read:  Read request signal to physical memory
    pmem_write: Write request signal to physical memory
    pmem_address: address cache wants to access in physical memory

    mem_read: Read request signal recieved from CPU
    mem_write: Write request signal recieved from CPU
    mem_byte_enable: 
    mem_address: Address CPU wants to access in physical memory(invisible Cache)
    mem_wdata: Data CPU wants to write to the physical memory
    mem_resp: memory cache sends to CPU
    mem_rdata: Data read from physical memory to be sent to CPU

*/

module mike_cache #(
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

    input  mem_read,
    input  mem_write,
    input  [3:0] mem_byte_enable,
    input  logic [31:0] mem_address,
    input  logic [31:0] mem_wdata,
    output mem_resp,
    output logic [31:0] mem_rdata,

    input  pmem_resp,
    input  [255:0] pmem_rdata,
    output [255:0] pmem_wdata,
    output pmem_read,
    output pmem_write,
    output logic [31:0] pmem_address

);

/* FROM Bus Adaptor */
logic [255:0] mem_wdata256_bus;
logic [31:0]  mem_rdata_bus;
logic [31:0]  mem_byte_enable256_bus;       // Only used within cache module, comes from bus
/*************************************/

/* FROM CACHE CONTROLLER */
logic mem_resp_ctrl;
logic pmem_read_ctrl;
logic pmem_write_ctrl;

logic read_data_0_ctrl;
logic read_data_1_ctrl;
// logic [255:0] data_way0_in;
// logic [255:0] data_way1_in;

logic read_tag_0_ctrl;
logic read_tag_1_ctrl;
logic load_tag_0_ctrl;
logic load_tag_1_ctrl;

logic read_valid_0_ctrl;
logic read_valid_1_ctrl;
logic load_valid_0_ctrl;
logic load_valid_1_ctrl;
logic valid_way0_in_ctrl;
logic valid_way1_in_ctrl;

logic read_dirty_0_ctrl;
logic read_dirty_1_ctrl;
logic load_dirty_0_ctrl;
logic load_dirty_1_ctrl;
logic dirty_way0_in_ctrl;
logic dirty_way1_in_ctrl;

logic lru_read_ctrl;
logic lru_load_ctrl;
logic lru_in_ctrl;

mike_cache_types::datamuxin_sel_t datainmux_way0_sel_ctrl;
mike_cache_types::datamuxin_sel_t datainmux_way1_sel_ctrl;
mike_cache_types::datamuxout_sel_t dataoutmux_sel_ctrl;
mike_cache_types::bytemux_sel_t bytemux_way0_sel_ctrl;
mike_cache_types::bytemux_sel_t bytemux_way1_sel_ctrl;
mike_cache_types::addressmuxout_sel_t addressmuxout_sel_ctrl;
/*************************************/

/* FROM CACHE DATAPATH */
logic [255:0] datamux_out_datapath;                // from datamux output from data array         
logic lru_out_datapath;     
logic hit_0_datapath; logic hit_1_datapath; logic hit_datapath;  
logic [31:0] pmem_address_datapath;
logic write_en_way0_datapath;
logic write_en_way1_datapath;
logic dirty_way0_out_ctrl;
logic dirty_way1_out_ctrl;
logic dirty_set_datapath;
/*************************************/

logic [s_offset - 1:0] offset_bits;
logic [s_index - 1:0]  index_bits;
logic [s_tag - 1:0]    tag_bits;

/* ASSIGNMENTS */
assign offset_bits = mem_address[s_offset - 1 : 0];
assign index_bits  = mem_address[s_index + s_offset - 1 : s_offset];
assign tag_bits    = mem_address[31 : s_index + s_offset];

/* ASSIGNMENTS CACHE.SV ->CPU*/
assign mem_rdata = mem_rdata_bus;
assign mem_resp = mem_resp_ctrl;

/* ASSIGNMENTS CACHE.SV -> PMEM*/
assign pmem_address = pmem_address_datapath;
assign pmem_read = pmem_read_ctrl; 
assign pmem_write = pmem_write_ctrl;
assign pmem_wdata = datamux_out_datapath;   

mike_cache_control control
(
    .clk                     (clk),                      /* INPUT */
    .rst                     (rst),                      /* INPUT */
    .mem_read                (mem_read),                 /* INPUT, control <- CPU */
    .mem_write               (mem_write),                 /* INPUT, control <- CPU */
    .pmem_read               (pmem_read_ctrl),           /* OUTPUT, control -> cacheline */
    .pmem_write              (pmem_write_ctrl),          /* OUTPUT, control -> cacheline */

    .mem_resp                 (mem_resp_ctrl),           /* OUTPUT, control -> CPU */             
    .pmem_resp                (pmem_resp),               /* INPUT, control <- p_memory */

    /* ADDRESS BITS */
    .offset_bits             (offset_bits),              /* INPUT, control <- CPU */         
    .index_bits              (index_bits),               /* INPUT, control <- CPU */
    .tag_bits                (tag_bits),                 /* INPUT, control <- CPU */

    /* SELECT SIGNALS */
    .datainmux_way0_sel      (datainmux_way0_sel_ctrl),  /* OUTPUT, control -> datapath */
    .datainmux_way1_sel      (datainmux_way1_sel_ctrl),  /* OUTPUT, control -> datapath */
    .dataoutmux_sel          (dataoutmux_sel_ctrl),      /* OUTPUT, control -> datapath */
    .bytemux_way0_sel        (bytemux_way0_sel_ctrl),    /* OUTPUT, control -> datapath */
    .bytemux_way1_sel        (bytemux_way1_sel_ctrl),    /* OUTPUT, control -> datapath */
    .addressmuxout_sel       (addressmuxout_sel_ctrl),   /* OUTPUT, control -> datapath */

    /* TAG SIGNALS */
    .load_tag_0              (load_tag_0_ctrl),          /* OUTPUT, control -> datapath */
    .load_tag_1              (load_tag_1_ctrl),          /* OUTPUT, control -> datapath */

    /* VALID SIGNALS */
    .load_valid_0            (load_valid_0_ctrl),        /* OUTPUT, control -> datapath */
    .load_valid_1            (load_valid_1_ctrl),        /* OUTPUT, control -> datapath */
    .valid_way0_in           (valid_way0_in_ctrl),       /* OUTPUT, control -> datapath */
    .valid_way1_in           (valid_way1_in_ctrl),       /* OUTPUT, control -> datapath */

    /* DIRTY SIGNALS */
    .load_dirty_0            (load_dirty_0_ctrl),        /* OUTPUT, control -> datapath */
    .load_dirty_1            (load_dirty_1_ctrl),        /* OUTPUT, control -> datapath */
    .dirty_way0_in           (dirty_way0_in_ctrl),       /* OUTPUT, control -> datapath */
    .dirty_way1_in           (dirty_way1_in_ctrl),       /* OUTPUT, control -> datapath */
    .dirty_way0_out          (dirty_way0_out_ctrl),      /* INPUT, control <- datapath  */
    .dirty_way1_out          (dirty_way1_out_ctrl),      /* INPUT, control <- datapath  */
    .dirty_set               (dirty_set_datapath),       /* INPUT, control <- datapath  */

    /* LRU SIGNALS */
    .lru_load                (lru_load_ctrl),            /* OUTPUT, control -> datapath */
    .lru_in                  (lru_in_ctrl),              /* OUTPUT, control -> datapath */
    .lru_out                 (lru_out_datapath),         /* INPUT,  control <- datapath */

    /* HIT SIGNALS */
    .hit_0                   (hit_0_datapath),           /* OUTPUT, control <- datapath */
    .hit_1                   (hit_1_datapath),           /* OUTPUT, control <- datapath */
    .hit                     (hit_datapath),             /* OUTPUT, control <- datapath */

    .*
);

mike_cache_datapath datapath
(
    .clk                     (clk),                            /* INPUT */
    .rst                     (rst),                            /* INPUT */
    .cpu_address             (mem_address),                    /* INPUT, datapath <- CPU*/
    .pmem_address            (pmem_address_datapath),          /* OUTPUT, datapath -> cacheline */
    .cpu_byte_enable         (mem_byte_enable256_bus),         /* INPUT, datapath <- bus */

    /* ADDRESS BITS */
    .offset_bits             (offset_bits),                    /* INPUT, datapath <- CPU */
    .index_bits              (index_bits),                     /* INPUT, datapath <- CPU */
    .tag_bits                (tag_bits),                       /* INPUT, datapath <- CPU */

    /* DATA */
    .pmem_data               (pmem_rdata),                     /* INPUT, datapath <- cacheline */
    .cpu_data                (mem_wdata256_bus),               /* INPUT, datapath <- bus */

    /* MUX OUTPUTS */
    .cache_out_data          (datamux_out_datapath),           /* OUTPUT, datapath -> bus | cacheline */

    /* SELECT SIGNALS */
    .datainmux_way0_sel      (datainmux_way0_sel_ctrl),        /* INPUT, datapath <- control */
    .datainmux_way1_sel      (datainmux_way1_sel_ctrl),        /* INPUT, datapath <- control */
    .dataoutmux_sel          (dataoutmux_sel_ctrl),            /* INPUT, datapath <- control */
    .bytemux_way0_sel        (bytemux_way0_sel_ctrl),          /* INPUT, datapath <- control */
    .bytemux_way1_sel        (bytemux_way1_sel_ctrl),          /* INPUT, datapath <- control */
    .addressmuxout_sel       (addressmuxout_sel_ctrl),         /* INPUT, datapath <- control */

    /* Tag Signals*/
    .load_tag_0              (load_tag_0_ctrl),                /* INPUT, datapath <- control */ 
    .load_tag_1              (load_tag_1_ctrl),                /* INPUT, datapath <- control */

    /* Valid Signals */
    .load_valid_0            (load_valid_0_ctrl),              /* INPUT, datapath <- control */
    .load_valid_1            (load_valid_1_ctrl),              /* INPUT, datapath <- control */
    .valid_way0_in           (valid_way0_in_ctrl),             /* INPUT, datapath <- control */
    .valid_way1_in           (valid_way1_in_ctrl),             /* INPUT, datapath <- control */

    /* Dirty Signals */
    .load_dirty_0            (load_dirty_0_ctrl),              /* INPUT, datapath <- control */
    .load_dirty_1            (load_dirty_1_ctrl),              /* INPUT, datapath <- control */
    .dirty_way0_in           (dirty_way0_in_ctrl),             /* INPUT, datapath <- control */
    .dirty_way1_in           (dirty_way1_in_ctrl),             /* INPUT, datapath <- control */
    .dirty_way0_out          (dirty_way0_out_ctrl),            /* OUTPUT, datapath -> control */
    .dirty_way1_out          (dirty_way1_out_ctrl),            /* OUTPUT, datapath -> control */
    .dirty_set               (dirty_set_datapath),             /* OUTPUT, datapath -> control */ 

    /* LRU Signals */
    .lru_load                (lru_load_ctrl),                  /* INPUT, datapath <- control */
    .lru_in                  (lru_in_ctrl),                    /* INPUT, datapath <- control */
    .lru_out                 (lru_out_datapath),               /* OUTPUT, datapath -> */

    /* HIT SIGNALS */
    .hit_0                   (hit_0_datapath),                     /* OUTPUT, datapath -> control */
    .hit_1                   (hit_1_datapath),                     /* OUTPUT, datapath -> control */
    .hit                     (hit_datapath),                       /* OUTPUT, datapath -> control */
    .*
);

mike_bus_adapter bus_adapter
(
    .address                 (mem_address),             /* INPUT,  bus <- CPU */
    .mem_byte_enable         (mem_byte_enable),         /* INPUT,  bus <- CPU       */
    .mem_rdata256            (datamux_out_datapath),    /* INPUT,  bus <-  datapath*/
    .mem_wdata               (mem_wdata),               /* INPUT,  bus <- CPU */ 
    .mem_wdata256            (mem_wdata256_bus),        /* OUTPUT, bus -> datapath */
    .mem_rdata               (mem_rdata_bus),           /* OUTPUT, bus -> CPU */
    .mem_byte_enable256      (mem_byte_enable256_bus),  /* OUTPUT, bus -> datapath*/
     .*
);

endmodule : mike_cache


/* OLD CODE */

/* OLD PORTS FOR CACHE */
/*
    // input cache_resp_i,
    // input mem_read_i,               // Read request from CPU
    // input mem_write_i,
    // output cache_resp_o,
    // output mem_read_o,              // indicates whether there is a read request from cache to p_mem
    // output mem_write_o,
    // input [3:0] mem_byte_enable,
    // input rv32i_word mem_address,
    // output rv32i_word mem_rdata,
    // output rv32i_word mem_wdata,
    // input [255:0] mem_rdata256,
    // output [255:0] mem_wdata256
*/