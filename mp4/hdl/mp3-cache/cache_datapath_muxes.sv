module cache_datapath_muxes
(
	input logic lru, 
	input logic [23:0] tag1, 
	input logic [23:0] tag2,
	input logic data_way_sel, 
	input logic pmem_address_sel, 
	input logic [255:0] pmem_rdata,
	input logic [255:0] mem_wdata256,
	input logic [31:0] mem_byte_enable256,
	input logic [31:0] mem_address,
	input logic [255:0] way1_dataout,
	input logic [255:0] way2_dataout,
	input logic data1_datain_sel,
	input logic [1:0] data1_write_en_sel,
	input logic data2_datain_sel,
	input logic [1:0]  data2_write_en_sel,
	output logic [255:0] data_way_out,
	output logic [31:0] pmem_address,
	output logic [255:0] way1_datain,
	output logic [31:0] way1_write_en,
	output logic [255:0] way2_datain,
	output logic [31:0] way2_write_en
);
logic [23:0] lru_tag; 
always_comb begin
	if(lru)
		lru_tag = tag1; 
	else 
		lru_tag = tag2;
		
   if(data_way_sel == 1'b0) 
		data_way_out = way1_dataout;
   else 
		data_way_out = way2_dataout;
		
   if(pmem_address_sel == 1'b0) 
		pmem_address = {mem_address[31:5], 5'd0};
   else 
		pmem_address = {lru_tag, mem_address[7:5], 5'd0};   
end
always_comb begin
    if(data1_datain_sel == 1'b0)
			way1_datain = pmem_rdata;
    else
			way1_datain = mem_wdata256;
			
    if(data1_write_en_sel == 2'b00)
			way1_write_en = 32'd0;
    else if(data1_write_en_sel == 2'b01)
			way1_write_en = {{32{1'b1}}};
    else
			way1_write_en = mem_byte_enable256;
end
always_comb begin 
    if(data2_datain_sel == 1'b0)
			way2_datain = pmem_rdata;
    else 
			way2_datain = mem_wdata256;

    if(data2_write_en_sel == 2'b00)
			way2_write_en = 32'd0;
    else if(data2_write_en_sel == 2'b01)
			way2_write_en = {{32{1'b1}}};
    else 
			way2_write_en = mem_byte_enable256;            
end 


endmodule 