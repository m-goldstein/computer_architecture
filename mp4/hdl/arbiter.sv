
module arbiter(
        input logic clk,
        input logic rst,

		/*Instruction Cache Interface */
		input logic inst_cache_mem_read,
		input logic[31:0] inst_cache_mem_address,
		output logic arbiter_inst_cache_resp_o,
		output logic[255:0] inst_cache_rdata_o,

		/* DataCache Interface */
        input logic data_cache_mem_read,
        input logic data_cache_mem_write,
        input logic[31:0] data_cache_mem_address,
        input logic[255:0] data_cache_wdata_i,
        output logic arbiter_data_cache_resp_o,
		output logic[255:0] data_cache_rdata_o,

		/* Memory Interface */
		input logic arbiter_resp_i,
		output logic read_request,
		output logic write_request,
		input logic[255:0] arbiter_rdata_i,
		output logic[31:0] arbiter_mem_address_o,
		output logic[255:0] arbiter_data_o

		/*CPU Datapath Interface */
		// output logic [1:0] state_o
        
);
    logic data_request;
    logic inst_request;

	logic pmemmux_sel;   /* 1 - > Instruction request, 0 -> Data request */
	logic cachemux_sel;  /* 1 - > Instruction request, 0 -> Data request */

    assign data_request = (data_cache_mem_read) || (data_cache_mem_write);
    assign inst_request = inst_cache_mem_read;
    // logic[31:0] next_addr;
    // logic[255:0] next_inst_rdata;
    // logic[255:0] next_data_rdata;
    // logic[255:0] next_data;
    // logic next_dcache_resp;
    // logic next_icache_resp;
    // logic next_read_request;
    // logic next_write_request;

    logic[31:0] mem_address;
    // assign read_request = (data_cache_mem_read || inst_cache_mem_read);
    // assign write_request = (data_cache_mem_write);
   	function void set_defaults();
		// next_data        	= arbiter_data_o;
		// next_inst_rdata  	= inst_cache_rdata_o;
		// next_data_rdata  	= data_cache_rdata_o;
		// next_icache_resp 	= arbiter_inst_cache_resp_o;
		// next_dcache_resp 	= arbiter_data_cache_resp_o;
		// next_read_request   = read_request;
		// next_write_request  = write_request;
		// next_addr	    	= mem_address;
		pmemmux_sel  = 0;
		cachemux_sel = 0;
    endfunction
    
   enum int unsigned {
        IDLE = 0,
        DATA_FETCH = 1,
        INST_FETCH = 2
    } state, next_state;

	assign state_o = state;

    /* Single cycle inlined combinational logic */
    // assign data_cache_rdata_o = (data_cache_mem_read && arbiter_data_cache_resp_o) ? arbiter_rdata_i : next_data_rdata; 
    // assign arbiter_data_o = (data_cache_mem_write && arbiter_data_cache_resp_o) ? data_cache_wdata_i : next_data; 
    // assign inst_cache_rdata_o = (inst_cache_mem_read && arbiter_inst_cache_resp_o) ? arbiter_rdata_i : next_inst_rdata;
    // assign arbiter_inst_cache_resp_o = (inst_cache_mem_read ) ? next_icache_resp : 1'b0;
    // assign arbiter_data_cache_resp_o = ((data_cache_mem_read | data_cache_mem_write) ) ?next_dcache_resp : 1'b0;
    // assign arbiter_mem_address_o = (inst_request && ~(data_request)) ? inst_cache_mem_address  :
	// 			    ((data_request) && ~inst_request) ? data_cache_mem_address :
	// 			    32'b0;


	/* Arbiter Datapath */
	always_comb begin
		
		inst_cache_rdata_o = '0;
		data_cache_rdata_o = '0;
		arbiter_data_o     = '0; 
		/* ***Physical MEM MUX*** */
		if( pmemmux_sel ) begin
			read_request          = inst_cache_mem_read;        /* READ REQUERST TO MEMORY */
			write_request         = 0;                          /* Write Request To Memory */
			arbiter_mem_address_o = inst_cache_mem_address;     /* Read Address to Memory */
			//arbiter_wdata       = '0;
		end
		else begin
			read_request          = data_cache_mem_read;        /* READ REQUERST TO MEMORY */
			write_request         = data_cache_mem_write;       /* Write Request To Memory */
			arbiter_mem_address_o = data_cache_mem_address;     /* Read Address to Memory */
			arbiter_data_o        = data_cache_wdata_i;         /* Write Data to Memory */
		end

		/* DATA-INST MUX */
		if( cachemux_sel ) begin
			arbiter_inst_cache_resp_o = arbiter_resp_i;
			inst_cache_rdata_o        = arbiter_rdata_i;
			arbiter_data_cache_resp_o = 0;
		end
		else begin
			arbiter_data_cache_resp_o = arbiter_resp_i;
			data_cache_rdata_o        = arbiter_rdata_i;
			arbiter_inst_cache_resp_o = 0;
		end


	end

	/* FSM LATCH */
    always_ff @ (posedge clk ) begin
		if(rst == 1'b1)
			state <= IDLE;
		else
			state <= next_state;
		//mem_address <= next_addr;
    end 

	/* FSM Output Logic */
    always_comb begin
		set_defaults();
		case (state)
			IDLE: 
			begin
					// next_addr = arbiter_mem_address_o;
					// next_inst_rdata = inst_cache_rdata_o;
					// next_data_rdata = data_cache_rdata_o;
					/* JUST WAITING! */
			end

			DATA_FETCH: 
			begin    
				// next_addr          = data_cache_mem_address;
				// next_data		   = data_cache_wdata_i;
				// next_dcache_resp   = arbiter_resp_i;
				// next_data_rdata	   = arbiter_rdata_i;
				pmemmux_sel  = 0;
				cachemux_sel = 0;
			end
			INST_FETCH: 
			begin
				// next_addr         = inst_cache_mem_address;
				// next_inst_rdata	  =  arbiter_rdata_i; 
				// next_icache_resp  = arbiter_resp_i;
				//arbiter_data_cache_resp_o = 0;
				pmemmux_sel  = 1;
				cachemux_sel = 1;
			end
			default: ;
		endcase
    end
    
	/* FSM Next-State Logic */
    always_comb begin
		//next_state = state;
		case(state)
			IDLE: 
			begin
				if (inst_request & ~data_request)
					next_state = INST_FETCH;
				else if ( ~inst_request & data_request)
					next_state = DATA_FETCH;
				else if(data_request & inst_request)
					next_state = DATA_FETCH;
				else
					next_state = IDLE;
			end
			DATA_FETCH: 
			begin
				if (arbiter_resp_i)
					next_state = IDLE;
				else
					next_state = DATA_FETCH;
			end
			INST_FETCH: 
			begin
				if(arbiter_resp_i)
					next_state = IDLE;
				else
					next_state = INST_FETCH;
			end
			default: next_state = IDLE; 
		endcase
    end
endmodule

/*always_ff @(posedge clk or posedge rst) begin
$display("[Arbiter %t]:",$time);
$display("data_cache_mem_read: %x\ndata_cache_mem_write:%x\nicache_mem_read: %x\narbiter_resp_i: %x\nicache_addr: %x\ndcache_mem_addr: %x\narbiter_data_i: %x\ndcache_wdata_i: %x\n\
icache_rdata_i: %x\narbiter_addr_o: %x\narbiter_data_o: %x\nrequest_o: %x\nicache_resp_o: %x\ndcache_resp_o: %x\n\n",data_cache_mem_read,data_cache_mem_write,inst_cache_mem_read,arbiter_resp_i,inst_cache_mem_address,data_cache_mem_address,arbiter_data_i,data_cache_wdata_i,inst_cache_rdata_i,arbiter_mem_address_o,arbiter_data_o,arbiter_request_o,arbiter_inst_cache_resp_o,arbiter_data_cache_resp_o);
    end
*/
