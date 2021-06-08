import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


always @ (tb_clk iff (dut.ms.op == DONE)) begin
	assert ( (dut.product_o == (dut.multiplier_i * dut.multiplicand_i)))	/* If in DONE state, and product_o holds incorrect product, report BAD_PRODUCT error */
		else begin
			$error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
			report_error(BAD_PRODUCT);
		end
end

always @ (tb_clk iff (dut.ms.op == DONE)) begin
	assert (dut.ready_o)																	/* If in DONE state, and ready_o is not asserted, report NOT_READY error */
		else begin
			$error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
			report_error(NOT_READY);
		end
end

always @ (tb_clk iff (dut.reset_n_i == 1'b0)) begin
	assert (dut.ready_o)																	/* If ready_o is not asserted after a reset, report NOT_READY error */
		else begin
			$error("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
			report_error(NOT_READY);
		end
end

/* useful macro definitions */
`define MAX_WAIT_CYCLES					6
`define MIN_WAIT_CYCLES					1
`define YES									1'b1
`define NO									1'b0
/* macro to toggle start signal between consecutive multiply operations */
`define INITIALIZE						\
	itf.start <= `YES;					\
	##(`MAX_WAIT_CYCLES);				\
	itf.start <= `NO; 					\
	##(`MIN_WAIT_CYCLES);						
	
/* macro to assign unsigned random values to signals for multiplicand and multiplier */
`define SET_RANDOM_VALS					\
	reset();									\
	##(`MAX_WAIT_CYCLES);				\
	itf.multiplicand <= $urandom();	\
	itf.multiplier   <= $urandom();	\
	`INITIALIZE;



initial itf.reset_n = 1'b0;
initial begin
	 reset();
    /********************** Your Code Here *****************************/
	 itf.start = `NO;
	 for (int op1 = 8'b00000000; op1 <= 8'b11111111; op1++) begin			// iterate over each 8-bit multiplicand value, 0 to 255 
		for (int op2 = 8'b00000000; op2 <= 8'b11111111; op2++) begin		// iterate over each 8-bit multiplier value, 0 to 255
			reset();
			##(`MAX_WAIT_CYCLES);
			itf.multiplicand = op1;														// load multiplicand input signal with multiplicand operand.
			itf.multiplier   = op2;														// load multiplier input signal with multiplier operand.
			`INITIALIZE;
			/* wait for ready_o signal to be asserted. */
			@(tb_clk iff (dut.ready_o == `YES));
		end
	end
	
	/* Cover tests when reset/start signals asserted. */
	`SET_RANDOM_VALS;
	do @(tb_clk); while (dut.ms.op != DONE);										// wait for DONE state to be asserted.
	
	`INITIALIZE;
	@(tb_clk iff (dut.ready_o == `YES));											// wait for ready_o signal to be asserted.
	
	/* ADD cover tests */
	`SET_RANDOM_VALS;
	do @(tb_clk); while (dut.ms.op != ADD);										// wait for ADD state to be asserted.
	reset();
	
	/* SHIFT cover tests */
	`SET_RANDOM_VALS;
	do @(tb_clk); while (dut.ms.op != SHIFT);										// wait for SHIFT state to be asserted.
	reset();
	
    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end

endmodule : testbench
`endif
