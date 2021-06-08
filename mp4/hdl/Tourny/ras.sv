import rv32i_types::*;
/* added for clarity */
`ifndef RAS_MACROS
`define RAS_MACROS
`define STACK_SIZE	8'hff
`define FALSE		1'b0
`define TRUE		1'b1
`endif
module RAS
(
    input clk,
    input rst,
	input logic [4:0]rs1_addr,
	input logic [4:0] rd_addr,
    input rv32i_opcode opcode_in,
    input rv32i_word   pc_out,

	output logic pop,           /* Boolean for if pop is ready */
    output rv32i_word  return_address

);
    logic[31:0] stack[256];// = '{default: '0}; // 256 groups of 32 bits;
    logic[7:0]  count;                      /* pointer to stack*/
	logic[7:0]  next_count;

	rv32i_opcode opcode;
	assign opcode = opcode_in;

	rv32i_word pc_plus4;
	assign pc_plus4 = pc_out + 4;

	/* FOR JALR, when it should push/pop */
	logic link_rs1;            /* True when the register is either x1 or x5 */
	logic link_rd;
	assign link_rs1 = (rs1_addr == 4'b0001) | (rs1_addr == 4'b0101);
	assign link_rd  = (rd_addr == 4'b0001)  | (rd_addr == 4'b0101);
	always_comb begin
		
		pop = 1'b0;
		stack[count] = 0;
		next_count = count;
		return_address = '0;
		/* PUSH */
		if ( (opcode == op_jal) & (link_rd)  ) begin
			stack[count] = pc_plus4;
			next_count = ((count+1'b1)&(`STACK_SIZE));
		end

		/* JALR TABLE*/
		else if( opcode == op_jalr ) begin

			if( ~link_rd & ~link_rs1 )begin 
				/* DO NOTHING */
			end

			/* POP */
			else if( ~link_rd & link_rs1 )begin 
				return_address = stack[count - 1'b1];
				next_count = ((count-1'b1)&(`STACK_SIZE));
				pop = 1'b1;
			end

			/* PUSH */
			else if( link_rd & ~link_rs1 ) begin
				stack[count] = pc_plus4;
			    next_count = ((count+1'b1)&(`STACK_SIZE));
			end

			/*LINK*/
			else if (link_rd & link_rs1) begin
				/* PUSH AND POP */
				if(rs1_addr != rd_addr) begin
					/* PUSH */
					stack[count] = pc_plus4;
					/* POP */
					return_address = stack[count - 1'b1];
					next_count = count;
					pop = 1'b1;
				end 
				/* PUSH */
				else begin
					stack[count] = pc_plus4;
			    	next_count = ((count+1'b1)&(`STACK_SIZE));
				end	
			end

		end

	end
    
	always_ff @(posedge clk) begin
		if (rst) 
			count <= 'd0;

		else 
			count <= next_count;
    end

    // always_comb begin
	// 	address_out = address_in;
	// 	empty = (`TRUE); // default value

	// 	if (count < 'd0) begin  // invalid RAS
	// 		empty = (`TRUE);
	// 		address_out = address_in; // forward address in to address out
	// 	end 

	// 	else begin
	// 		// empty stack and PUSH 
	// 		if (count == 'd0 && opcode_in == rv32i_types::op_jal) begin
	// 			stack[count] = address_in;
	// 			empty = (`FALSE); // valid RAS. 1 entry.
	// 		end 
	// 		// empty stack and POP
	// 		else if (count == 'd0 && opcode_in == rv32i_types::op_jalr) begin
	// 			empty = (`TRUE);	  // invalid RAS
	// 			address_out = address_in; // forward address in to address out
	// 		end	
	// 		// non-empty stack and PUSH
	// 		else if (count > 'd0 && opcode_in == rv32i_types::op_jal)begin
	// 			empty = (`FALSE);	// valid RAS ( > 1 entry)
	// 			address_out = stack[count];
	// 		end 
	// 		// non-empty stack and POP
	// 		else if (count > 'd0 && opcode_in == rv32i_types::op_jalr) begin
	// 			empty = (`FALSE); // valid RAS ( > 1 entry)
	// 			address_out = stack[count-1];
	// 		end
	// 	end
    // end
    

    // /* index into stack gets modified at the END of a clock cycle. */
    // always_ff @(negedge clk) begin
	// 	if (rst) 
	// 		count <= 'd0;

	// 	else if (~empty) begin
	// 		unique case (opcode_in)
	// 			rv32i_types::op_jal:         count <= ((count+1'b1)&(`STACK_SIZE));    /* PUSH */
	// 			rv32i_types::op_jalr:		 count <= ((count-1'b1)&(`STACK_SIZE));    /* POP */
	// 			default: ;
	// 		endcase
	// 	end
    // end
    /*always_comb begin
	address_out = 'd0;
	if (rst) begin
	    count = 'd0;
	    address_out = 'd0;
	end else begin
	    unique case (opcode_in)
	    rv32i_types::op_jal:		// PUSH
	    begin
		stack[count] = address_in;
		count = (count+1'b1)&(`STACK_SIZE);
	    end
	    rv32i_types::op_jalr:		// POP
	    begin
		count = (count-1'b1)&(`STACK_SIZE);
		address_out = stack[count];
	    end
	    default: ;
	    endcase
	end
    end*/
endmodule : RAS
	
