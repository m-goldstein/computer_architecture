`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

logic [(width_p-1):0] prev;																					// internal register to store previous FIFO contents

/* macro definitions */
`define ZERO				8'b00000000
`define ONE					8'b00000001
`define ULIM			   cap_p
`define YES					1'b1
`define NO					1'b0
`define MAX_WAIT_CYCLES	10
`define MIN_WAIT_CYCLES	1

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
	 
	/* Enqueue values to the FIFO */
	##(`MIN_WAIT_CYCLES);																		// wait for clock signal
	itf.data_i  <= `ZERO;																		// clear data_i register
	itf.valid_i <= `YES;																			// assert valid_i signal as HIGH
	
	for (int it = 0; it < `ULIM; ++it) begin												// FIFO size in range [0, cap_p-1]
		##(`MIN_WAIT_CYCLES);																	// wait for clock signal
		itf.data_i <= itf.data_i + `ONE;
	end
	itf.valid_i <= `NO;																			// assert valid_i signal as LOW
	/* now, when ready_o is asserted, enqueue operation is performed. */
	
	/* Dequeue values from the FIFO */
	##(`MIN_WAIT_CYCLES);																		// wait for clock signal
	itf.yumi <= `YES;																				// assert yumi_i signal as HIGH
	
	for (int it = 1; it < `ULIM; ++it) begin												// FIFO size in range [1, cap_p]
		if (it == 1'd1) begin
			assert (itf.data_o == `ZERO)														// assert that data_o contains correct value when yumi_i is asserted.
				else begin
					$error ("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
					report_error(INCORRECT_DATA_O_ON_YUMI_I);
				end
		end
		else begin
			assert (itf.data_o == (prev + `ONE))												// assert that data_o contains correct value when yumi_i is asserted.
				else begin
					$error ("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
					report_error(INCORRECT_DATA_O_ON_YUMI_I);
				end
		end
		prev <= itf.data_o;																			// update contents of prev register with current data_o register contents
		##(`MIN_WAIT_CYCLES);																		// wait for clock signal
	end
	/* now, when valid_o is asserted, dequeue operation is performed. */
	
	/* Enqueue and Dequeue values from the FIFO */
	for (int val = 1; val < `ULIM; ++val) begin												// FIFO size in range [1, cap_p-1]
		##(`MIN_WAIT_CYCLES);																		// wait for clock signal
		itf.data_i  <= val;
		itf.valid_i <= `YES;																			// assert valid_i signal as HIGH
		itf.yumi 	<= `NO;																			// assert yumi_i signal as LOW
		/* performs an enqueue operation once ready_o is asserted as HIGH */
		
		##(`MIN_WAIT_CYCLES);																		// wait for clock signal
		itf.yumi		<= `YES;																			// assert yumi_i signal as HIGH
		itf.data_i  <= val;
		/* performs a dequeue operation once valid_o is asserted as HIGH. */
	end
	
	##(`MIN_WAIT_CYCLES);																			// wait for clock signal
	itf.valid_i <= `NO;																				// assert valid_i signal as LOW
	itf.yumi		<= `NO;																				// assert yumi_i signal as LOW
	
	##(`MIN_WAIT_CYCLES);																			// wait for clock signal
	itf.data_i  <= `ZERO;
	itf.valid_i <= `YES;																				// assert valid_i signal as HIGH
	itf.yumi    <= `NO;																				// assert yumi_i signal as LOW
	##(`MAX_WAIT_CYCLES);																			// wait for predetermined amount of clock cycles
	/* performs an enqueue operation once ready_o is asserted as HIGH. */
	
	##(`MIN_WAIT_CYCLES);																			// wait for clock signal
	itf.reset_n <= `NO;																				// assert reset_n_i signal as LOW
	
	##(`MIN_WAIT_CYCLES);																			// wait for the clock signal
	assert (itf.rdy)																		// assert that ready_o is high when reset_n is asserted at @(tb_clk)
		else begin
			$error ("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
			report_error(RESET_DOES_NOT_CAUSE_READY_O);
		end
	itf.valid_i <= `NO;																				// assert valid_i signal as LOW
    
	 /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif