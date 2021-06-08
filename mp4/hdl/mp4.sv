`include "cache_struct.sv"
`include "control_word.sv"
module mp4(
    input logic clk, 
    input logic rst,
    /* burst memory */
    input logic mem_resp,
    input logic[63:0] mem_rdata,
     
    output logic[63:0] mem_wdata,
    output logic[31:0] mem_addr,
    output logic mem_read,
    output logic mem_write
);

cache_types::cache_struct_t data_cache;
cache_types::cache_struct_t inst_cache;

/* Arbiter-Core Signals */
logic arbiter_state;

logic[255:0] inst_cache_rdata256;
logic[255:0] data_cache_rdata256;
logic[255:0] data_cache_wdata256;
logic[255:0] inst_cache_wdata256;
logic[255:0] adapter_data_out;

logic[31:0] arbiter_mem_address_o;
logic[31:0] inst_cache_pmem_address;
logic[31:0] data_cache_pmem_address;
logic inst_cache_pmem_read;
logic inst_cache_pmem_write;
logic data_cache_pmem_read;
logic data_cache_pmem_write;
logic inst_cache_pmem_resp;
logic data_cache_pmem_resp;
logic inst_cache_request;
logic data_cache_request;
assign inst_cache_request = inst_cache_pmem_read;
assign data_cache_request = data_cache_pmem_read || data_cache_pmem_write;

core cpu(
        // Inputs
        .clk           (clk),
        .rst           (rst),
        .inst_resp     (inst_cache.mem_resp),
        .inst_rdata    (inst_cache.mem_rdata),
        .inst_addr     (inst_cache.mem_address),
        .inst_read     (inst_cache.mem_read),

        // .arbiter_state (arbiter_state),
        // .pmem_read     (data_cache_pmem_read | inst_cache_pmem_read),
        // .pmem_write    (data_cache_pmem_write),

        // Outputs
        .data_resp    (data_cache.mem_resp),
        .data_rdata   (data_cache.mem_rdata),
        .data_read    (data_cache.mem_read),
        .data_write   (data_cache.mem_write),
        .data_mbe     (data_cache.mem_byte_enable),
        .data_addr    (data_cache.mem_address),
        .data_wdata   (data_cache.mem_wdata)		  
);

assign inst_cache.mem_byte_enable = 4'hF;
assign inst_cache.mem_wdata = 'd0;
logic adapter_done;
logic[255:0] line_i;

// d_cache datacache(
// 	.clk              (clk),
//     .rst              (rst),

// 	/* CPU Interface */
//     .mem_address      (data_cache.mem_address),
// 	.mem_read         (data_cache.mem_read),
//     .mem_write        (data_cache.mem_write),
// 	.mem_wdata        (data_cache.mem_wdata),
// 	.mem_byte_enable  (data_cache.mem_byte_enable),
// 	.mem_resp         (data_cache.mem_resp),
// 	.mem_rdata        (data_cache.mem_rdata),

// 	/* Memory Interface */
// 	.pmem_resp        (data_cache_pmem_resp),
// 	.pmem_rdata       (data_cache_rdata256),
//     .pmem_read        (data_cache_pmem_read),
//     .pmem_write       (data_cache_pmem_write),
// 	.pmem_address     (data_cache_pmem_address),
// 	.pmem_wdata       (data_cache_wdata256)
// );

// assign inst_cache.mem_write = 0;
// d_cache instcache(
//     .clk              (clk),
//     .rst              (rst),

// 	/* CPU Interface */
//     .mem_address      (inst_cache.mem_address),
// 	.mem_read         (inst_cache.mem_read),
//     .mem_write        (inst_cache.mem_write),
// 	.mem_wdata        (inst_cache.mem_wdata),
// 	.mem_byte_enable  (inst_cache.mem_byte_enable),
// 	.mem_resp         (inst_cache.mem_resp),
// 	.mem_rdata        (inst_cache.mem_rdata),

// 	/* Memory Interface */
// 	.pmem_resp        (inst_cache_pmem_resp),
// 	.pmem_rdata       (inst_cache_rdata256),
//     .pmem_read        (inst_cache_pmem_read),
//     .pmem_write       (inst_cache_pmem_write),
// 	.pmem_address     (inst_cache_pmem_address),
// 	.pmem_wdata       (inst_cache_wdata256)        
// );

mike_cache datacache(
	.clk              (clk),
    .rst              (rst),

	/* CPU Interface */
    .mem_address      (data_cache.mem_address),
	.mem_read         (data_cache.mem_read),
    .mem_write        (data_cache.mem_write),
	.mem_wdata        (data_cache.mem_wdata),
	.mem_byte_enable  (data_cache.mem_byte_enable),
	.mem_resp         (data_cache.mem_resp),
	.mem_rdata        (data_cache.mem_rdata),

	/* Memory Interface */
	.pmem_resp        (data_cache_pmem_resp),
	.pmem_rdata       (data_cache_rdata256),
    .pmem_read        (data_cache_pmem_read),
    .pmem_write       (data_cache_pmem_write),
	.pmem_address     (data_cache_pmem_address),
	.pmem_wdata       (data_cache_wdata256)
);

assign inst_cache.mem_write = 0;
mike_cache instcache(
    .clk              (clk),
    .rst              (rst),

	/* CPU Interface */
    .mem_address      (inst_cache.mem_address),
	.mem_read         (inst_cache.mem_read),
    .mem_write        (inst_cache.mem_write),
	.mem_wdata        (inst_cache.mem_wdata),
	.mem_byte_enable  (inst_cache.mem_byte_enable),
	.mem_resp         (inst_cache.mem_resp),
	.mem_rdata        (inst_cache.mem_rdata),

	/* Memory Interface */
	.pmem_resp        (inst_cache_pmem_resp),
	.pmem_rdata       (inst_cache_rdata256),
    .pmem_read        (inst_cache_pmem_read),
    .pmem_write       (inst_cache_pmem_write),
	.pmem_address     (inst_cache_pmem_address),
	.pmem_wdata       (inst_cache_wdata256)        
);

// cache datacache(
// 	.clk              (clk),
//     .rst              (rst),

// 	/* CPU Interface */
//     .mem_address      (data_cache.mem_address),
// 	.mem_read         (data_cache.mem_read),
//     .mem_write        (data_cache.mem_write),
// 	.mem_wdata        (data_cache.mem_wdata),
// 	.mem_byte_enable  (data_cache.mem_byte_enable),
// 	.mem_resp         (data_cache.mem_resp),
// 	.mem_rdata        (data_cache.mem_rdata),

// 	/* Memory Interface */
// 	.pmem_resp        (data_cache_pmem_resp),
// 	.pmem_rdata       (data_cache_rdata256),
//     .pmem_read        (data_cache_pmem_read),
//     .pmem_write       (data_cache_pmem_write),
// 	.pmem_address     (data_cache_pmem_address),
// 	.pmem_wdata       (data_cache_wdata256)
// );

// assign inst_cache.mem_write = 0;
// cache instcache(
//     .clk              (clk),
//     .rst              (rst),

// 	/* CPU Interface */
//     .mem_address      (inst_cache.mem_address),
// 	.mem_read         (inst_cache.mem_read),
//     .mem_write        (inst_cache.mem_write),
// 	.mem_wdata        (inst_cache.mem_wdata),
// 	.mem_byte_enable  (inst_cache.mem_byte_enable),
// 	.mem_resp         (inst_cache.mem_resp),
// 	.mem_rdata        (inst_cache.mem_rdata),

// 	/* Memory Interface */
// 	.pmem_resp        (inst_cache_pmem_resp),
// 	.pmem_rdata       (inst_cache_rdata256),
//     .pmem_read        (inst_cache_pmem_read),
//     .pmem_write       (inst_cache_pmem_write),
// 	.pmem_address     (inst_cache_pmem_address),
// 	.pmem_wdata       (inst_cache_wdata256)        
// );

arbiter mem_arbiter(
    .clk(clk),
    .rst(rst),

    /* Instruction Cache Interface */
    .inst_cache_mem_read           (inst_cache_pmem_read),
    .inst_cache_mem_address        (inst_cache_pmem_address),
    .arbiter_inst_cache_resp_o     (inst_cache_pmem_resp),
    .inst_cache_rdata_o            (inst_cache_rdata256),

    /* Data Cache Interface */
    .data_cache_mem_read           (data_cache_pmem_read),
    .data_cache_mem_write          (data_cache_pmem_write),
    .data_cache_mem_address        (data_cache_pmem_address),
    .data_cache_wdata_i            (data_cache_wdata256),
    .arbiter_data_cache_resp_o     (data_cache_pmem_resp),
    .data_cache_rdata_o            (data_cache_rdata256),

    /* Memory Interface */
    .arbiter_resp_i                (adapter_done),
    .read_request                  (arbiter_read),
    .write_request                 (arbiter_write),
    .arbiter_rdata_i               (adapter_data_out),
    .arbiter_mem_address_o         (arbiter_mem_address_o),
    .arbiter_data_o                (line_i)     

    /* CPU Datapath Interface */
    //.state_o                       (arbiter_state)               
);

// given_cache datacache(
//         .clk(clk),
//         // PMem Inputs
//         .pmem_resp(data_cache_pmem_resp),
//         .pmem_rdata(data_cache_rdata256),
//         // Pmem Outputs
//         .pmem_address(data_cache_pmem_address),
//         .pmem_wdata(data_cache_wdata256),    
//         .pmem_read(data_cache_pmem_read),   
//         .pmem_write(data_cache_pmem_write),
//         // CPU Mem Inputs
//         .mem_read(data_cache.mem_read),   
//         .mem_write(data_cache.mem_write), 
//         .mem_byte_enable_cpu(data_cache.mem_byte_enable),  
//         .mem_address(data_cache.mem_address), 
//         .mem_wdata_cpu(data_cache.mem_wdata),
//         // CPU Mem Outputs
//         .mem_resp(data_cache.mem_resp),     
//         .mem_rdata_cpu(data_cache.mem_rdata)
// );

// assign inst_cache.mem_write = 0;
// given_cache instcache(
//         .clk(clk),
//         // PMem Interface
//         .pmem_resp(inst_cache_pmem_resp),
//         .pmem_rdata(inst_cache_rdata256),
//         .pmem_address(inst_cache_pmem_address), 
//         .pmem_wdata(inst_cache_wdata256),    
//         .pmem_read(inst_cache_pmem_read),   
//         .pmem_write(inst_cache_pmem_write),

//         // CPU Interface
//         .mem_read(inst_cache.mem_read),   
//         .mem_write(inst_cache.mem_write),
//         .mem_byte_enable_cpu(inst_cache.mem_byte_enable),
//         .mem_address(inst_cache.mem_address),           
//         .mem_wdata_cpu(inst_cache.mem_wdata),
//         .mem_resp(inst_cache.mem_resp),             
//         .mem_rdata_cpu(inst_cache.mem_rdata)       
// );


/* CACHLINE <> ARBITER MUX */
cacheline_adaptor adaptor(
    .clk        (clk),
    .reset_n    (~rst),
    .line_i     (line_i),           
    .line_o     (adapter_data_out),              
    .address_i  (arbiter_mem_address_o),
    .read_i     (arbiter_read),           
    .write_i    (arbiter_write),        
    .resp_o     (adapter_done),         

	.burst_i    (mem_rdata),
    .burst_o    (mem_wdata),
    .address_o  (mem_addr),
    .read_o     (mem_read),
    .write_o    (mem_write),
    .resp_i     (mem_resp)
);

endmodule : mp4



/*always_ff @(posedge clk) begin
    $display("[Top level signals: %t]", $time);
    $display("Inputs:\nmem_resp: %x\nmem_rdata: %x\n\nOutputs:\nmem_wdata: %x\nmem_addr: %x\nmem_read: %x\nmem_write: %x\n",mem_resp,mem_rdata,mem_wdata,mem_addr,mem_read,mem_write);
	 $display("\nCacheline Adapter signals:\nline_i: %x\nline_o: %x\naddress_i: %x\naddress_o: %x\nread_i: %x\nread_o: %x\nwrite_i: %x\nwrite_o: %x\nburst_i: %x\nburst_o: %x\n\
				resp_i:%x\nresp_o:%x\n",line_i,adapter_data_out,arbiter_mem_address_o,mem_addr,arbiter_read,mem_read,arbiter_write,mem_write,mem_rdata,mem_wdata,mem_resp,adapter_done);
	 $display("clk: %x\nreset_n: %x\n",clk,~rst);
	 //$display("inputs: \nmem_resp: %x\ndata_resp: %x\ninst_rdata: %x\ndata_rdata: %x\n\noutputs: \ninst_read: %x\ndata_read: %x\ndata_write: %x\ndata_mbe: %x\ninst_addr: %x\ndata_addr: %x\ndata_wdata: %x\n",inst_resp,data_resp,inst_rdata,data_rdata,inst_read,data_read,data_write,data_mbe,inst_addr,data_addr,data_wdata);
    //$display("Data cache signals:");
    //$display("cache_mem_resp: %x\ncache_data_reg: %x\ndata_cache_arb_address: %x\ndata_cache_pmem_wdata: %x\ndata_cache_arb_read: %x\ndata_cache_arb_write: %x\ndata_cache.mem_read: %x\ndata_cache.mem_write: %x\ndata_cache.mem_byte_enable: %x\ndata_cache.mem_address: %x\ndata_cache.mem_wdata: %x\ndata_cache.mem_resp: %x\ndata_cache.mem_rdata: %x\n\n", data_cache_pmem_resp, data_cache_rdata256, data_cache_pmem_address, data_cache_wdata256, data_cache_pmem_read, data_cache_pmem_write, data_cache.mem_read, data_cache.mem_write, data_cache.mem_byte_enable, data_cache.mem_address, data_cache.mem_wdata, data_cache.mem_resp, data_cache.mem_rdata);
    //$display("Instruction cache signals:");
    //$display("cache_mem_resp: %x\ncache_data_reg: %x\ninst_cache_arb_address: %x\ninst_cache_pmem_wdata: %x\ninst_cache_arb_read: %x\ninst_cache_arb_write: %x\ninst_cache.mem_read: %x\ninst_cache.mem_write: %x\ninst_cache.mem_byte_enable: %x\ninst_cache.mem_address: %x\ninst_cache.mem_wdata: %x\ninst_cache.mem_resp: %x\ninst_cache.mem_rdata: %x\n\n", icache_pmem_rdata, inst_cache_rdata256, inst_cache_pmem_address, inst_cache_pmem_rdata, inst_cache_pmem_read, inst_cache_pmem_read, inst_cache.mem_read, inst_cache.mem_write, inst_cache.mem_byte_enable, inst_cache.mem_address, inst_cache.mem_wdata, inst_cache.mem_resp, inst_cache.mem_rdata);
end
*/
//endmodule : mp4
 
