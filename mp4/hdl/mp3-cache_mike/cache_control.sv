//include "cache_types.sv"
import mike_cache_types::*;

/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

/* Description of Signals */
/*
    mem_read: Tells memory system that processor requesting a memory read
    mem_resp: Physical Memory Response signal indicating whether memory is ready or not
*/
module mike_cache_control (
    input clk,
    input rst,
    input mem_read,
    input mem_write,
    output logic pmem_read,
    output logic pmem_write,
    
    output logic mem_resp,
    input pmem_resp,

    /* ADDRESS BITS */
    input [4:0] offset_bits,
    input [2:0] index_bits,
    input [23:0] tag_bits,

    /* SELECT SIGNALS */
    output mike_cache_types::datamuxin_sel_t datainmux_way0_sel,
    output mike_cache_types::datamuxin_sel_t datainmux_way1_sel,
    output mike_cache_types::datamuxout_sel_t dataoutmux_sel,
    output mike_cache_types::bytemux_sel_t bytemux_way0_sel,
    output mike_cache_types::bytemux_sel_t bytemux_way1_sel,
    output mike_cache_types::addressmuxout_sel_t addressmuxout_sel,

    /* TAG SIGNALS */
    output  logic load_tag_0,
    output  logic load_tag_1,

    /* VALID SIGNALS */
    output logic load_valid_0,
    output logic load_valid_1,
    output logic valid_way0_in,
    output logic valid_way1_in,

    /* DIRTY SIGNALS */
    output logic load_dirty_0,
    output logic load_dirty_1,
    output logic dirty_way0_in,
    output logic dirty_way1_in,
    input dirty_way0_out,
    input dirty_way1_out,
    input dirty_set,

    /* LRU SIGNALS */
    output logic lru_load,
    output logic lru_in,
    input lru_out,
    
    /* HIT SIGNALS */
    input hit_0, hit_1, hit
);
/* Description of States */
/*
    IDLE: cache is waiting for memory request(read or write)
    HIT: references cache block through index portion, if the cache block is valid( exists in the cache)
             then, HIT the tag bits of cache block against the tag portion of the address
             if tag matches, then its a hit, return data from cache memory
             else, there is a miss, and cache control transitions to a CACHE_WRITE state on a read request
    CACHE_WRITE: New cacheline/block is fetched from memory through cacheline adaptor, state is idle if memory signal 
              from the physical memory(pmem_resp) is not set. When memory read is complete, go back to CACHE_WRITE state
*/
enum int unsigned {
    /* List of states */
	//idle,           // cache is waiting for memory request(read or write)
    HIT,        // references cache block through index portion, 
    CACHE_WRITE,        // Cache miss, dirty bit is low, only need to CACHE_WRITE new block, evict LRU block if necesary, 
    MEM_WRITE      // Cache miss, dirty bit is high, need to update main memory with this block, transition to "CACHE_WRITE"
	 
} state_cache, next_state_cache;

// enum int unsigned {
//     WAIT,
//      CHECK_HIT, 
//      MEM_WRITE, 
//      MEM_READ, 
//      CACHE_WRITE
// } state, next_state;

function void set_defaults();

    load_tag_0         = 1'b0;
    load_tag_1         = 1'b0;
    load_valid_0       = 1'b0;
    load_valid_1       = 1'b0;
    load_dirty_0       = 1'b0;
    load_dirty_1       = 1'b0;
    lru_load           = 1'b0;

    valid_way0_in      = 1'b0;
    valid_way1_in      = 1'b0;
    dirty_way0_in      = 1'b0;
    dirty_way1_in      = 1'b0;
    lru_in             = 1'b0;
  
    datainmux_way0_sel = mike_cache_types::pmem_data;
    datainmux_way1_sel = mike_cache_types::pmem_data;
    dataoutmux_sel     = mike_cache_types::dataout_way0;
    bytemux_way0_sel   = mike_cache_types::zero_enable;
    bytemux_way1_sel   = mike_cache_types::zero_enable;
    addressmuxout_sel  = mike_cache_types::cpu;

    mem_resp           = 1'b0;
    pmem_read          = 1'b0;
    pmem_write         = 1'b0;

endfunction

// always_ff @(posedge clk) begin : next_state_assignment
// 	if (rst == 1'b1) begin
// 		state <= WAIT;
// 	end
// 	else begin
// 		state <= next_state;
// 	end
// end

// always_comb begin : next_state_logic
// 	next_state = state;
	
// 	if (state == WAIT) begin
// 		if(mem_read == 1'b1 || mem_write == 1'b1)		next_state = CHECK_HIT;
// 	end
// 	else if (state == CHECK_HIT) begin
// 		if (hit)		                                   next_state = WAIT;
// 		else if (dirty_set == 1'b0)						   next_state = MEM_READ;
// 		else											   next_state = MEM_WRITE;
// 	end
// 	else if (state == MEM_WRITE) begin
// 		if (pmem_resp == 1'b1)	next_state = MEM_READ;	
// 	end
// 	else if (state == MEM_READ) begin
// 		if (pmem_resp == 1'b1)	next_state = CACHE_WRITE;
// 	end
// 	else if (state == CACHE_WRITE) begin
// 		next_state = WAIT;
// 	end
// end

// always_comb begin : state_actions
// 	set_defaults();
	
// 	if (state == WAIT) begin
		
// 	end
// 	else if (state == CHECK_HIT) begin
// 		if (hit) begin
// 			if (mem_read == 1'b1) begin
//                 lru_load = 1'b1;
//                 mem_resp = 1'b1;
//                 if(hit_0) begin
//                     //cache_way = hit_way0;	// cache_way = way with hit
//                     dataoutmux_sel = mike_cache_types::dataout_way0;
//                     lru_in = 1;
//                 end
//                 else begin
//                     //cache_way = hit_way0;	// cache_way = way with hit
//                     dataoutmux_sel = mike_cache_types::dataout_way1;
//                     lru_in = 0;
//                 end
// 			end		
// 			else begin	// mem_write == 1'b1
//                 lru_load = 1'b1;
//                 mem_resp = 1'b1;
//                 if(hit_0) begin
//                     load_dirty_0 = 1'b1;
//                     bytemux_way0_sel = mike_cache_types::byte_enable;
//                     //cache_way = hit_way1;	// cache_way = way with hit
//                     datainmux_way0_sel = mike_cache_types::cpu_data;
//                     //load_way0 = hit_way0;	// load way with hit
//                     //load_way1 = hit_way1;
//                     //dirty_in = 1'b1;
//                     dirty_way0_in = 1'b1;
//                     //lru_in = hit_way0;
//                     lru_in = 1'b1;
//                 end
// 				else begin
//                     load_dirty_1 = 1'b1;
//                     bytemux_way1_sel = mike_cache_types::byte_enable;
//                     //cache_way = hit_way1;	// cache_way = way with hit
//                     datainmux_way1_sel = mike_cache_types::cpu_data;
//                     //load_way0 = hit_way0;	// load way with hit
//                     //load_way1 = hit_way1;
//                     //dirty_in = 1'b1;
//                     dirty_way1_in = 1'b1;
//                     //lru_in = hit_way0;
//                     lru_in = 1'b0;
//                 end
// 				// if(hit_way1 == 1'b1)		write_en_way1 = mem_byte_enable;
// 				// else						write_en_way0 = mem_byte_enable;
// 			end
// 		end
// 	end
//     /* WRITE TO MEMORY STAGE */
// 	else if (state == MEM_WRITE) begin
// 		pmem_write = 1'b1;
// 		//cache_way = lru_out;
// 		if(lru_out == 1'b1)begin
//             addressmuxout_sel = mike_cache_types::cache_way1;
//             dataoutmux_sel = mike_cache_types::dataout_way1;
//         end
//         else begin
//             addressmuxout_sel = mike_cache_types::cache_way0;
//             dataoutmux_sel = mike_cache_types::dataout_way0;
//         end
// 	end

// 	else if (state == MEM_READ) begin
// 		pmem_read = 1'b1;
// 		//cache_way = lru_out; // NEEDED?
// 		//tag_select = tag_mux::mem_address;
		
// 		// load_way0 = ~lru_out;
// 		// load_way1 = lru_out;
// 		//data_in_select = data_in_mux::pmem_rdata;

//         if(lru_out) begin
//             datainmux_way1_sel = mike_cache_types::pmem_data;
//             bytemux_way1_sel = mike_cache_types::f_enable;
//             load_tag_1 = 1'b1;
//             load_valid_1 = 1'b1;
//             valid_way1_in = 1'b1;
//             load_dirty_1 = 1'b1;
//             dirty_way1_in = 1'b0;
//         end
//         else begin
//             datainmux_way0_sel = mike_cache_types::pmem_data;
//             bytemux_way0_sel = mike_cache_types::f_enable;
//             load_tag_0 = 1'b1;
//             load_valid_0 = 1'b1;
//             valid_way0_in = 1'b1;
//             load_dirty_0 = 1'b1;
//             dirty_way0_in = 1'b0;
//         end
		
// 	end

// 	else if (state == CACHE_WRITE) begin
// 		//cache_way = lru_out;
// 		mem_resp = 1'b1;
// 		lru_load = 1'b1;
// 		if (mem_write == 1'b1) begin	
//             if(lru_out == 1'b1) begin
//                 lru_in = ~lru_out;
//                 load_dirty_0 = 1'b1;
//                 dirty_way0_in = 1'b1;
//                 bytemux_way0_sel = mike_cache_types::byte_enable;
//                 datainmux_way0_sel = mike_cache_types::cpu_data;
//             end
//             else begin
//                 lru_in = ~lru_out;
//                 load_dirty_1 = 1'b1;
//                 dirty_way1_in = 1'b1;
//                 bytemux_way1_sel = mike_cache_types::byte_enable;
//                 datainmux_way1_sel = mike_cache_types::cpu_data;
//             end
// 			// load_way1 = lru_out;
// 			// dirty_in = 1'b1;
// 			// data_in_select = data_in_mux::mem_wdata;
			
// 			// if(lru_out == 1'b1)		write_en_way1 = mem_byte_enable;
// 			// else					write_en_way0 = mem_byte_enable;
// 		end
// 	end

// end

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();

    /* Actions for each state */
	case (state_cache)

        // idle:
        // begin
        //     /* Do nothing */

        // end

        // Determine if peice of memory is loaded into the cache or not
        HIT:
        begin
            // IF HIT ;hit_1 = ((tag_way0_out == tag_bits) & valid_way0_out );
            if(hit & mem_read) begin 
                mem_resp = 1'b1;  // cache is ready
                lru_load = 1'b1;
                // HIT IN WAY 0
                if (hit_0) begin
                    lru_in = 1'b1;   // way 0 was used most recently
                    dataoutmux_sel = mike_cache_types::dataout_way0;
                end
                // HIT IN WAY 1
                else begin
                    lru_in = 1'b0;   // way 1 was used most recently
                    dataoutmux_sel = mike_cache_types::dataout_way1;
                end
            end
            // ELSE IF HIT & WRITE,
            else if(hit & mem_write) begin
                lru_load = 1'b1;
                mem_resp = 1'b1;
                if(hit_0) begin
                    lru_in = 1'b1;     // way 0 most recent, way 1 least recent
                    load_dirty_0 = 1'b1;
                    dirty_way0_in = 1'b1;    
                    bytemux_way0_sel = mike_cache_types::byte_enable;
                    datainmux_way0_sel = mike_cache_types::cpu_data;
                end
                // hit in way 1
                else begin
                    lru_in = 1'b0;
                    load_dirty_1 = 1'b1;
                    dirty_way1_in = 1'b1;
                    bytemux_way1_sel = mike_cache_types::byte_enable;
                    datainmux_way1_sel = mike_cache_types::cpu_data;
                end
            end
            // ELSE, MISS, ADDRESS NOT LOADED IN CACHE

        end

        CACHE_WRITE:
        begin 
            pmem_read = 1'b1;    // load data from mem
            
            // lru = 1, way 0 was most recently used
            // => evict way 1 and load new data into way 1
            if(lru_out == 1'b1) begin
                datainmux_way1_sel = mike_cache_types::pmem_data;
                bytemux_way1_sel = mike_cache_types::f_enable;
                load_tag_1 = 1'b1;
                load_valid_1 = 1'b1;
                valid_way1_in = 1'b1;
                load_dirty_1 = 1'b1;
                dirty_way1_in = 1'b0; // load dirty for writes
            end
            // lru = 0,  way 1 was most recently used
            // => evict way 0 and load new data into way 0
            else begin
                datainmux_way0_sel = mike_cache_types::pmem_data;
                bytemux_way0_sel = mike_cache_types::f_enable;
                load_tag_0 = 1'b1;
                load_valid_0 = 1'b1;
                valid_way0_in = 1'b1;
                load_dirty_0 = 1'b1;
                dirty_way0_in = 1'b0; // load dirty for writes
            end
        end

        MEM_WRITE: 
        begin
            pmem_write = 1'b1;
            // way 1 was least recently used
            if(lru_out == 1'b1) begin
                addressmuxout_sel = mike_cache_types::cache_way1;
                dataoutmux_sel = mike_cache_types::dataout_way1;
            end
            // way 0 was least recently used
            else begin
                addressmuxout_sel = mike_cache_types::cache_way0;
                dataoutmux_sel = mike_cache_types::dataout_way0;
            end
        end

        default: ;

    endcase
	 
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  
	  case (state_cache)
		  
		// idle:
        // begin
        //     if(mem_read  || mem_write) 
        //         next_state_cache = HIT;
        //     else
        //         next_state_cache = idle;
        // end

        HIT:	
        begin
            /* if block is up to date with memory */
             // old block is clean
            if(dirty_set == 1'b0 & ~hit & (mem_read  | mem_write) ) 
                next_state_cache = CACHE_WRITE;

            /*old block is dirty, block is not up to date with memory */
            // dirty_set = (dirty_way0_out & ~lru_out) || (dirty_way1_out & lru_out)
            else if( dirty_set == 1'b1 & ~hit & (mem_read  | mem_write) )
                next_state_cache = MEM_WRITE;

           
            else
                next_state_cache = HIT;
    
        end	
		 
        CACHE_WRITE: 
        begin
            if(pmem_resp == 1'b1)
                next_state_cache = HIT;      // memory is ready
            else
                next_state_cache = CACHE_WRITE;     // wait for memory

        end
        MEM_WRITE:
        begin
            if(pmem_resp == 1'b1)
                next_state_cache = CACHE_WRITE;
            else
                next_state_cache = MEM_WRITE;
        end
		
		default: ;  // Put something here?
		  
	  
	  endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 if(rst == 1'b1)begin
		 state_cache <= HIT ;
	 end
	 else begin
		 state_cache <= next_state_cache;
	 end
	 
end

endmodule : mike_cache_control
