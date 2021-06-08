 /* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
module cache_control (
      input clk,
      input rst,
		input logic lru,
		input pmem_resp,
      input mem_write,
      input mem_read,
      input logic dirty_bit1,
      input logic dirty_bit2,
		input logic [23:0] tag1,
      input logic [23:0] tag2,
      input logic [1:0] valid,
		input logic hit_status,
		input logic dirty_status,
      input logic [31:0] mem_address,
      output logic mem_resp,
      output logic pmem_read,
      output logic pmem_write,
		output logic pmem_address_sel,
		output logic lru_load,
      output logic lru_datain,
      output logic tag_load_1,
      output logic tag_load_2,
      output logic dirty_load_1,
		output logic dirty_load_2,
      output logic dirty_datain_1,
      output logic dirty_datain_2,
      output logic valid_load,
      output logic [1:0] valid_in,
      output logic [1:0] data1_write_en_sel,
		output logic [1:0] data2_write_en_sel,
      output logic data1_datain_sel,
      output logic data2_datain_sel,
      output logic data_way_sel
);



enum int unsigned {
	idle,
	HIT_state, 
	PHY_MEM_state,
	DIRTY_state,
	READ_WRITE_state
} state, next_state;

always_comb begin
      if(rst) begin
            next_state <= idle;
      end 
		else begin
            if(state == idle) begin
                  if(mem_write == 0 && mem_read == 0)
                        next_state <= idle;
                  else 
                        next_state <= HIT_state; 
            end
            else if(state == HIT_state) begin
                  if(hit_status == 1'b1)
                        next_state <= idle;
                  else if(dirty_status == 1'b1)
                        next_state <= DIRTY_state;
                  else
                        next_state <= PHY_MEM_state;
            end
            else if(state == DIRTY_state) begin
                  if(pmem_resp == 1'b1)
                        next_state <= PHY_MEM_state;
                  else
                        next_state <= DIRTY_state;
            end

            else if(state == PHY_MEM_state) begin
                  if(pmem_resp == 1'b1)
                     next_state <= READ_WRITE_state;
                  else 
							next_state <= PHY_MEM_state; 
            end

            else if(state == READ_WRITE_state)
						next_state <= idle;
            else
                  next_state <= idle;
      end
end

function void READ_SETUP();
if(valid == 2'b10 || valid == 2'b11) begin
	dirty_datain_1 = 1'b0;
	dirty_datain_2 = 1'b0;
	lru_load = 1'b1;
	valid_load = 1'b1;
	valid_in = 2'b11;
	if(lru == 1'b1) begin 
		dirty_load_1 = 1'b1;
		dirty_load_2 = 1'b0;
		lru_datain = 1'b0;
		data_way_sel = 1'b0;
	end 
	else begin 
		dirty_load_1 = 1'b0;
		dirty_load_2 = 1'b1;
		lru_datain = 1'b1;
		data_way_sel = 1'b1;
	end 
end
else if(valid == 2'b00) begin
	data_way_sel = 1'b0;
	dirty_load_1 = 1'b1;
	dirty_datain_1 = 1'b0;
	lru_datain = 1'b0;
	valid_in = 2'b01;
	lru_load = 1'b1;
	valid_load = 1'b1;
end 
else if (valid == 2'b01) begin
	data_way_sel = 1'b1;
	dirty_load_2 = 1'b1;
	dirty_datain_2 = 1'b0;
	lru_datain = 1'b1;
	valid_in = 2'b11;
	lru_load = 1'b1;
	valid_load = 1'b1;
end 
endfunction 

function void WRITE_SETUP();
if(valid == 2'b10 || valid == 2'b11) begin
	dirty_datain_1 = 1'b1;
	dirty_datain_2 = 1'b1;
	data1_datain_sel = 1'b1;
	data2_datain_sel = 1'b1;
	lru_load = 1'b1;
	valid_load = 1'b1;
	valid_in = 2'b11;
	if(lru == 1'b1) begin 
		data_way_sel = 1'b0;
		dirty_load_1 = 1'b1;
		dirty_load_2 = 1'b0;
		data1_write_en_sel = 2'b10;
		data2_write_en_sel = 2'b00;
		lru_datain = 1'b0;
	end
	else begin 
		data_way_sel = 1'b1;
		dirty_load_1 = 1'b0;
		dirty_load_2 = 1'b1;
		data1_write_en_sel = 2'b00;
		data2_write_en_sel = 2'b10;
		lru_datain = 1'b1;
	end 
end
else if(valid == 2'b00) begin
	dirty_load_1 = 1'b1;
	dirty_datain_1 = 1'b1;
	data1_write_en_sel = 2'b10;
	data1_datain_sel = 1'b1;
	data_way_sel = 1'b0;
	lru_datain = 1'b0;
	valid_in = 2'b01;
	lru_load = 1'b1;
	valid_load = 1'b1;
end 
else begin
	dirty_load_2 = 1'b1;
	dirty_datain_2 = 1'b1;
	data2_write_en_sel = 2'b10;
	data2_datain_sel = 1'b1;
	data_way_sel = 1'b1;
	lru_datain = 1'b1;
	lru_load = 1'b1;
	valid_load = 1'b1;
	valid_in = 2'b11;
end 
endfunction 

function void PHY_MEM_SETUP();
if(valid == 2'b10 || valid == 2'b11) begin
	dirty_datain_1 = 1'b0;
	dirty_datain_2 = 1'b0;
	data1_datain_sel = 1'b0;
	data2_datain_sel = 1'b0;
	if(lru == 1'b1) begin 
		tag_load_1 = 1'b1;
		tag_load_2 = 1'b0;
		dirty_load_1 = 1'b1;
		dirty_load_2 = 1'b0;
		data1_write_en_sel = 2'b01;
		data2_write_en_sel = 2'b00;
	end 
	else begin 
		tag_load_1 = 1'b0;
		tag_load_2 = 1'b1;
		dirty_load_1 = 1'b0;
		dirty_load_2 = 1'b1;
		data1_write_en_sel = 2'b00;
		data2_write_en_sel = 2'b01;
	end
end
else if(valid == 2'b00) begin
	tag_load_1 = 1'b1;
	dirty_load_1 = 1'b1;
	dirty_datain_1 = 1'b0;
	data1_write_en_sel = 2'b01;
	data1_datain_sel = 1'b0;
end 
else begin
	tag_load_2 = 1'b1;
	dirty_load_2 = 1'b1;
	dirty_datain_2 = 1'b0;
	data2_write_en_sel = 2'b01;
	data2_datain_sel = 1'b0;
end 
endfunction 

always_comb begin
      data_way_sel = 1'b0;
      pmem_address_sel = 1'b0;
      mem_resp = 1'b0;
      pmem_read = 1'b0;
      pmem_write = 1'b0;
      tag_load_1 = 1'b0;
      tag_load_2 = 1'b0;
      dirty_load_1 = 1'b0;
		dirty_load_2 = 1'b0;
      dirty_datain_1 = 1'b0;
      dirty_datain_2 = 1'b0;
      lru_load = 1'b0;
      lru_datain = 1'b0;
      valid_load = 1'b0;
      valid_in = 2'b0;
      data1_write_en_sel = 2'b00;
      data1_datain_sel = 1'b0;
      data2_write_en_sel = 2'b00;
      data2_datain_sel = 1'b0;
		
      if(hit_status == 1'b1 && state == HIT_state) begin
			lru_load = 1'b1;
			mem_resp = 1'b1;
			if(mem_write == 1'b1) begin 
            dirty_datain_1 = 1'b1;
            dirty_datain_2 = 1'b1;
				data1_datain_sel = 1'b1;
            data2_datain_sel = 1'b1;
				if(tag1 == mem_address[31:8]) begin 
					dirty_load_1 = 1'b1; 
					dirty_load_2 = 1'b0;
					data1_write_en_sel = 2'b10;
					data2_write_en_sel = 2'b00;
					lru_datain = 1'b0;
					data_way_sel = 1'b0;
				end
				else begin 
					dirty_load_1 = 1'b0;
					dirty_load_2 = 1'b1; 
					data1_write_en_sel = 2'b00;
					data2_write_en_sel = 2'b10;
					lru_datain = 1'b1;
					data_way_sel = 1'b1; 
				end
			end 
			else begin
				if (tag1 == mem_address[31:8]) begin 
					lru_datain = 1'b0;
					data_way_sel = 1'b0; 
				end
				else begin 
					lru_datain = 1'b1;
					data_way_sel = 1'b1;
				end
			end 
      end
		
		else if (state == PHY_MEM_state) begin
			pmem_read = 1'b1;
			PHY_MEM_SETUP();
      end

      else if (state == READ_WRITE_state) begin
			mem_resp = 1'b1;
			if(mem_read == 1'b1) begin 
				READ_SETUP();
			end 
			else begin 
				WRITE_SETUP();
			end 
      end 
		
		else if (state == DIRTY_state) begin
			pmem_write = 1'b1;
			pmem_address_sel = 1'b1;
			if(lru == 1'b1) 
				data_way_sel = 1'b0;
			else 
				data_way_sel = 1'b1;
      end

end

always_ff @(posedge clk) begin
      state <= next_state;
end

endmodule : cache_control
