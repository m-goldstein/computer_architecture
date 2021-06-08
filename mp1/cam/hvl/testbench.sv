import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
endtask

task read(input key_t key, output val_t val);
endtask

/* macro definitions */
`define KEYS_DEF			16'b0011001100110011	// 0011 0011 0011 0011 (default value)
`define VALS_DEF			16'b0100010001000100 // 0100 0100 0100 0100 (default value)
`define YES					1'b1
`define NO					1'b0
`define MIN_WAIT_CYCLES	1

key_t [(camsize_p-1):0]  __keys;					// internal register for keys
val_t [(camsize_p-1):0]  __vals;					// internal register for values
/* each key-value pair with matching index are associated together */

/* macros definitions used to test consecutive writes and test consecutive writes followed by reads on data in the CAM */
`define KEY_1		16'b0000000000010111
`define VAL_IDX	16'b0000000000000100
`define KEY_IDX	16'b0000000000000111
logic [(val_width_p-1):0] temp;					// internal register to store randomized value stored at a given key-value pair entry in the CAM.

initial begin
    $display("Starting CAM Tests");

    reset();
	 
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
	 
	 /* Initialize contents of __keys and __vals (internal) registers used by testbench to populate CAM with key-value pairs; */
	 for (int idx = 0; idx < camsize_p; idx++) begin
		__keys[idx] = idx;							// iterate over each index value and assign the associated key to current idx value.
		__vals[idx] = $urandom();					// assign each key-value pair randomized data at the index value given by idx
	end
															// test eviction of a key-value pair from CAM indices.
	/* Perform removal (eviction) to a key-value pair stored in the CAM */ 
	##(`MIN_WAIT_CYCLES);							// wait for clock signal
	itf.rw_n		  = `NO;								// assert rw_n_i signal as LOW
	itf.valid_i	  = `YES;							// assert valid_i signal as HIGH
	/* now, write_i signal can be asserted by CAM controller module */
	itf.key       = `KEYS_DEF;						// load key_i signal with default value (defined above)
	itf.val_i     = `VALS_DEF;						// load val_i signal with default value (defined above)
	/* further, an eviction operation can be performed on an entry in the CAM */
	for (int idx = 0; idx < camsize_p; idx++) begin
		##(`MIN_WAIT_CYCLES);						// wait for clock signal
		itf.key   = __keys[idx];					// assign current key value to corresponding entry in __keys register
		itf.val_i = __vals[idx];					// assign current val value to corresponding entry in __vals register
	end
	##(`MIN_WAIT_CYCLES);							// wait for clock signal
	itf.valid_i  = `NO;								// assert valid_i signal as LOW
															// test read-hit of key-value pair from CAM indices.
	/* Record a read-hit on key-value pairs stored in the CAM */
															// prepare CAM entries for read hit over each index
	##(`MIN_WAIT_CYCLES);							// wait for clock signal
	itf.rw_n		  = `NO;								// assert rw_n_i signal as LOW
	itf.valid_i	  = `YES;							// assert valid_i signal as HIGH
	/* now, write_i signal can be asserted by CAM controller module */
	itf.key       = `KEYS_DEF;						// load key_i signal with default value (defined above)
	itf.val_i     = `VALS_DEF;						// load val_i signal with default value (defined above)
	/* further, an eviction operation can be performed on an entry in the CAM */
	for (int idx = 0; idx < camsize_p; idx++) begin
		##(`MIN_WAIT_CYCLES);						// wait for clock signal
		itf.key   = __keys[idx];					// assign current key value to corresponding entry in __keys register
		itf.val_i = __vals[idx];					// assign current val value to corresponding entry in __vals register
	end
	##(`MIN_WAIT_CYCLES);							// wait for clock signal
	itf.valid_i  = `NO;								// assert valid_i signal as LOW
	/* Perform a read operation on the CAM 	*/
	##(`MIN_WAIT_CYCLES);							// wait for clock signal
	itf.rw_n    = `YES;								// assret rw_n_i signal as HIGH
	itf.valid_i = `YES;								// assert valid_i signal as HIGH
	/* now, read_i signal can be asserted by CAM controller module */
	/* Iterate over each of its eight indices */
	for (int idx = 0; idx < camsize_p; idx++) begin
		itf.key   = __keys[idx];						// load key_i signal with value at corresponding index of internal __keys register
		itf.val_i = __vals[idx];						// load val_i signal with value at corresponding index of internal __vals register
		##(`MIN_WAIT_CYCLES);							// wait for clock signal
		assert (itf.val_o == __vals[idx])			// assert val_o signal contains proper value by checking against source register maintained internally by the testbench
			else begin										// else, throw a READ_ERROR error.
				$error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, __vals[idx]);
				itf.tb_report_dut_error(READ_ERROR);
			end
	end
	##(`MIN_WAIT_CYCLES);								// wait for clock signal
	itf.valid_i = `NO;									// assert valid_i signal as LOW
	 // test writes of different values to the same key on consecutive clock cycles.
	 /* Perform writes of different values to the same key on consecutive clock cycles */	
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 itf.val_i   = $urandom();							// load val_i signal with a random value.
	 itf.key		 = `KEY_1;								// load key_i signal with value defined to be `KEY_1
	 itf.rw_n    = `NO;									// assert rw_n_i signal as LOW
	 itf.valid_i = `YES;									// assert valid_i signal as HIGH
	 /* now, write_i signal can be asserted by CAM controller module */
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 temp        = $urandom(); 						// load val_i signal with a random value
	 itf.val_i   = temp;									//
	 itf.key		 = `KEY_1;								// load key_i signal with value defined to be `KEY_1
	 itf.valid_i = `YES;									// assert valid_i signal as HIGH
	 itf.rw_n    = `NO;									// assert rw_n_i signal as LOW
	 /* now, write_i signal can be asserted by CAM controller module */												
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 itf.key		 = `KEY_1;								// load key_i signal with value defined to be `KEY_1
	 itf.valid_i = `YES;									// assert valid_i signal as HIGH
	 itf.rw_n    = `YES;									// assert rw_n_i signal as HIGH
	 /* now, read_i signal can be asserted by CAM controller module */
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 assert (itf.val_o == temp)						// assert that val_o signal contains correct value after writing different values to same key on consecutive clock cycles
		 else begin
			 $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, temp);
			 itf.tb_report_dut_error(READ_ERROR);	// throw a READ_ERROR if val_o signal is not correct.
		 end
	 itf.valid_i = `NO;									// assert valid_i signal as LOW
	 // test write then a read to the same key on consecutive clock cycles.
    /* Perform a write then a read to the same key on consecutive clock cycles */
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 itf.val_i   = __vals[`VAL_IDX];					// load val_i signal with contents of __vals register at index `VAL_IDX
	 itf.key     = __keys[`KEY_IDX];					// load key_i signal with contents of __keys register at index `KEY_IDX
	 itf.valid_i = `YES;									// assert valid_i signal as HIGH
	 itf.rw_n    = `NO; 									// assert rw_n_i signal as LOW
	 /* now, write_i signal can be asserted by CAM controller module */
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 itf.key 	= __keys[`KEY_IDX];					// load key_i signal with contents of __keys register at index `KEY_IDX
	 itf.valid_i = `YES; 								// assert valid_i signal as HIGH
	 itf.rw_n    = `YES;									// assert rw_n_i signal as HIGH
	 /* now, read_i signal can be asserted by CAM controller module */															
	 ##(`MIN_WAIT_CYCLES);								// wait for clock signal
	 assert (itf.val_o == __vals[`VAL_IDX]) 		// assert that val_o signal contains proper value after performing a write then a read to same key value on consecutive clock cycles
		 else begin
			 $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, __vals[`VAL_IDX]);
			 itf.tb_report_dut_error(READ_ERROR);	// throw a READ_ERROR error if val_o is not correct.
		 end
	 itf.valid_i = `NO; 									// assert valid_i signal as LOW
	 /**********************************************************************/
    itf.finish();
end

endmodule : testbench