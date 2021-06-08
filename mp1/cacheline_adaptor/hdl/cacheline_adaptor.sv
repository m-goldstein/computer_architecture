module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);
	/* macro definitions */
	`define YES				1'b1
	`define NO				1'b0
	`define BURST_ZEROES	64'd0
	`define LINE_ZEROES	256'd0
	`define ADDR_ZEROES	32'd0
	`define READ_MASK		2'b10
	`define WRITE_MASK	2'b01
	`define SLICE(x,i)	x[(64*((i)-1)) +: 64]
	`define GOTO(x)		next_state = (x)
	
	enum logic [2:0] {
		INIT    = 0,
		BURST_1 = 1,
		BURST_2 = 2,
		BURST_3 = 3,
		BURST_4 = 4,
		DONE    = 5
	} state, next_state;
	
	logic         rw;				// r/w signal
	logic         next_rw;
	logic [255:0] next_line_o;
	logic [31:0]  next_addr_o;
	logic [63:0]  next_burst_o;
	
	/* sequential state controller logic */
	always_ff @ (posedge clk) begin
		if (~reset_n) begin					// synchronous reset
			state     <= INIT;				// transition back to initial state
			line_o    <= `LINE_ZEROES;		// clear line_o signal
			address_o <= `ADDR_ZEROES;		// clear address_o signal
			burst_o   <= `BURST_ZEROES;	// clear burst_o signal
			rw        <= `NO; 				// clear rw register
		end
		else begin								// otherwise transition to next state and update signals with next values, respectively.
			state     <= next_state;
			rw        <= next_rw;
			line_o    <= next_line_o;
			address_o <= next_addr_o;
			burst_o   <= next_burst_o;
		end
	end
	
	/* combinational state controller logic */
	 always_comb begin
        resp_o       = `NO;
		  next_addr_o  = address_i;
        next_rw      = rw;
        next_line_o  = line_o;
        next_burst_o = `BURST_ZEROES;
		  
		  if (state == INIT || state == DONE) begin
				read_o  = `NO; 														// clear read_o signal
				write_o = `NO;															// clear write_o signal
		  end
		  else begin
				write_o = rw;															// assign write_o signal to be rw
				read_o  = ~rw;															// assign read_o signal to be ~rw
		  end
		  
        case (state)
				default: `GOTO(INIT); 												// default next_state transition
				INIT: 																	// initial state
					begin
						case ({read_i, write_i})
							`READ_MASK:													// read operation
								begin
									next_rw = `NO;
									`GOTO(BURST_1);
								end
							`WRITE_MASK:												// write operation
								begin
									next_rw = `YES;
									`GOTO(BURST_1);
									next_burst_o = `SLICE(line_i, state + 1);	// load 64-bits from line into next burst output register
								end
							default: `GOTO(INIT);								// transition to INIT state (WAIT)
						endcase
					end
				
				DONE:																// done state
					begin
						resp_o = `YES;											// raise resp_o control signal
						`GOTO(INIT);											// transition to INIT state next
					end
				
            BURST_1:																// first burst state
					begin
						if (rw == `NO)
							`SLICE(next_line_o, state) = burst_i;			// next line output signal loaded with burst input signal
						else begin
							if (resp_i == `NO)
								next_burst_o = `SLICE(line_i, state);		// next burst output register loaded with current burst from line input register
							else
								next_burst_o = `SLICE(line_i, state + 1);	// otherwise, next burst output loaded with next burst from line input register
						end
						if (resp_i == `YES)										// load next burst if resp_i is asserted as HIGH
							`GOTO(BURST_2);
						else
							`GOTO(BURST_1);
					end
				
            BURST_2:															// second burst state 
					begin
						if (rw == `YES) 
							next_burst_o = `SLICE(line_i, state + 1);			// next burst output register loaded with next burst from line input register
						else 
							`SLICE(next_line_o, state) = burst_i;			// next line output signal loaded with burst input signal
						`GOTO(BURST_3);
					end
            
				BURST_3: 														// third burst state
					begin
						if (rw == `YES)
							next_burst_o = `SLICE(line_i, state + 1); 			// next burst output register loaded with next burst from line input register
						else
							`SLICE(next_line_o, state) = burst_i;			// next line output signal loaded with burst input signal
						`GOTO(BURST_4);
					end
				
            BURST_4:															// fourth burst state
					begin
						if (rw == `NO)
							`SLICE(next_line_o, state) = burst_i;			// next line output signal loaded with burst input signal	
						`GOTO(DONE);
					end
            
				
        endcase
    end
	 
endmodule : cacheline_adaptor 