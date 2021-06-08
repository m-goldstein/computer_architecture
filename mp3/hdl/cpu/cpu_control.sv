import rv32i_types::*; /* Import types defined in rv32i_types.sv */
/* MACROS **********************************************/
`define SPECIAL		7'b0100000
`define WALL_BYTES	4'b1111
`define WHALF_BYTES     4'b0011
`define WONE_BYTES      4'b0001
`define WNO_BYTES	4'b0000
`define YES				1'b1
`define NO				1'b0
`define GOTO(x)		next_states = (x)
/*******************************************************/
module cpu_control
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
	 /* signals added for cp1 */
	 input logic mem_resp,															// signal generated from memory subcomponent
	 output logic mem_read,															// from Controller, to Memory subcompoent
	 output logic mem_write,														// from Controller, to Memory subcompoent
	 output branch_funct3_t cmpop,												// from Controller, to Datapath
	 output rv32i_mem_wmask mem_byte_enable,									// from Controller, to memory subsystem
	 /* signals added for cp2 */
	 input logic[1:0] mem_addr_mask,
    input logic[1:0] alu_mask,
    input logic[1:0] mar_mask
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        // a mask of 2'b11 for lh,lhu would exceed the word size for the memory layout
        // need to set mask to 4'b1111 or else theres a mismatch error or trap is thrown;
        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = (((mem_addr_mask == 2'b11) || (mem_addr_mask == 2'b01)) ? (`WALL_BYTES) : (`WHALF_BYTES << (mem_addr_mask))); // /* Modify for MP1 Final */ ;
                lb, lbu: rmask = (`WONE_BYTES  << (mem_addr_mask));             // /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        // a mask of 2'b11 for sh would exceed the word size for the memory layout
        // need to constrain to 4-byte alignment
        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = (((mem_addr_mask == 2'b11) || (mem_addr_mask == 2'b01)) ? (`WALL_BYTES) : (`WHALF_BYTES << (mem_addr_mask))) ; // /* Modify for MP1 Final */ ;
                sb: wmask = (`WONE_BYTES  << (mem_addr_mask));           ///* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end

/*****************************************************************************/

enum int unsigned {
    /* List of states */
	 HALTED,
	 FETCH1,
	 FETCH2,
	 FETCH3,
	 DECODE,
	 BR,
	 LUI,
	 AUIPC,
	 REG_IMM_OPS,
	 CALC_ADDR,
	 LDR1,
	 LDR2,
	 STR1,
	 STR2,
         JMP,
	 REG_REG_OPS
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();	/* see Appendix D, 12.1 Control Signals for default assignments*/
	load_pc 				= `NO;
	load_ir 				= `NO;
	load_regfile 		= `NO;
	load_mar 			= `NO;
	load_mdr 			= `NO;
	load_data_out 		= `NO;
	pcmux_sel 			= pcmux::pc_plus4;
	cmpmux_sel 			= cmpmux::rs2_out;
	cmpop 				= beq;																	// set CMP to defaults;
	setALU(alumux::rs1_out, alumux::i_imm, 1, alu_ops'(funct3));	// set ALU to defaults; need to cast op argument to alu_ops type or quartus throws error.
	regfilemux_sel 	= regfilemux::alu_out;
	marmux_sel 			= marmux::pc_out;
	mem_read  			= `NO;
	mem_write 			= `NO;
	mem_byte_enable 	= `WALL_BYTES;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = `YES;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	load_regfile = `YES;
	regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = `YES;
    marmux_sel = sel;
endfunction

function void loadMDR();
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
	 alumux1_sel = sel1; 
	 alumux2_sel = sel2;
    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
					cmpmux_sel = sel;
					case (op)
						beq:		cmpop = beq;
						bne:		cmpop = bne;
						blt:		cmpop = blt;
						bltu:		cmpop = bltu;
						bge:		cmpop = bge;
						bgeu:		cmpop = bgeu;
						default: cmpop = beq;
					endcase
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 case (state)
		HALTED: set_defaults();
		
		// See 10. Appendix B: RTL for control signal behavior based on state
		// Uses enumerated typedefs defined in rv32i_types.sv for type safety.
		FETCH1: begin														// 10.1 FETCH Process
			loadMAR(marmux::pc_out);									// load_mar <== 1; marmux_sel <== 0
		end
		
		FETCH2: begin														// 10.1 FETCH Process
			load_mdr = `YES;
			mem_read = `YES;
		end
		
		FETCH3: begin														// 10.1 FETCH Process
			load_ir  = `YES;
		end
		
		DECODE: begin														// 10.2 DECODE Process
		;
		end
		
		/* for CP1 */
		REG_IMM_OPS: begin												// 10.6 Other immediate instructions
			loadPC(pcmux::pc_plus4);										// load_pc <== 1; pcmux_sel <== 0
			loadRegfile(regfilemux::alu_out);						// load_regfile <== 1; regfilemux_sel <== 0
			aluop = alu_ops'(funct3);									// aluop <== funct3
			case (arith_funct3)
				default: 	aluop = alu_ops'(funct3); // covers addi, xori, ori, andi, and slli; need cases for srli, srai, slti, sltui.
				// rd <== rs1 >>/<< i_imm[4:0]
				sr: 			aluop = (funct7 == `SPECIAL) ? alu_sra : alu_srl;		// 10.5 SRAI Instruction
				// rd <== (rs1 < i_imm) ? 1:0
				slt: begin																			// 10.3 SLTI Instruction
					loadRegfile(regfilemux::br_en);											// load_regfile <== 1; regfilemux_sel <== 1
					setCMP(cmpmux::i_imm, blt);												// cmpmux_sel <== 1; cmpop <== blt
				end
				// rd <== (unsigned'(rs1) < unsigned'(i_imm)) ? 1:0
				sltu: begin																			// 10.4 SLTIU Instruction
					loadRegfile(regfilemux::br_en);											// load_regfile <== 1; regfilemux_sel <== 1
					setCMP(cmpmux::i_imm, bltu);												// cmpmux_sel <== 1; cmpop <== bltu
				end
			endcase
		end
		
		BR: begin															// 10.7 BR Instruction
			// need to cast to pcmux_sel_t or quartus throws error.
			loadPC(pcmux::pcmux_sel_t'(br_en));						// pcmux_sel <== br_en; load_pc <== 1
			setALU(alumux::pc_out, alumux::b_imm, 1, alu_add); // aluop <== alu_add; alumux1_sel <== 1; alumux2_sel <== 2
			setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3));					// set CMP to defaults; Need to cast funct3 to branch_funct3_t type.
		end
		
		JMP: begin
                    loadRegfile(regfilemux::pc_plus4); // load_regfile <== 1; regfilemux_sel <== 4
                    case (opcode)
                        // See page 16 of https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf#page=30.
                        // target address obtained by adding 12 bit I-immediate to rs1.
                        // NEED TO ZERO OUT LEAST SIGNIFICANT BIT OF THE RESULT. (alu_mod2)
                        // pc+4 (instruction following the jump) is written to rd
                        op_jalr: begin                    // jump and link register (I type)
                           setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add); // aluop <== alu_addd; alumux1_sel <== 0;alumux2_sel <== 0
                           loadPC(pcmux::alu_mod2); // load_pc <== 1; pcmux_sel <== alu_mod2
                        end
                        // The J-Immediate encodes the signed offset at 2 byte granularity
                        // Then, target address is computed by adding this offset to PC
                        // pc+4 (instruction following the jump) is written to rd
                        op_jal: begin   // jump and link (J type)
                            setALU(alumux::pc_out, alumux::j_imm, 1, alu_add); // aluop <== alu_add; alumux1_sel <== 1; alumux2_sel <== 4
                            loadPC(pcmux::alu_out); // load_pc <== 1; pcmux_sel <== alu_out
                        end
                        default: ;
                    endcase
                end

       CALC_ADDR: begin													// 10.8/10.9 LW/SW Instruction
			unique case (opcode)
				// Loads have I-type encoding.
            // Need to set alumux according to spec that rd <== M[rs1+i_imm][x:y]
				op_load: begin												// 10.8 LW Instruction
				         setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add);
					 loadMAR(marmux::alu_out);							// marmux_sel <== 1; load_mar <== 1
			        end
				// Need to set ALU according to spec that rd <== M[rs1 + s_imm][x:y]
                                op_store: begin		
                                // Stores have S-type encoding (page 19 of riscv-spec.pdf)
                                // 10.9 SW Instruction
					setALU(alumux::rs1_out, alumux::s_imm, 1, alu_add);
                                        load_data_out = `YES;
					loadMAR(marmux::alu_out);							// marmux_sel <== 1; load_mar <== 1
			        end
			    default: ;
		    endcase 
		end
		
		LDR1: begin															// 10.8 LW Instruction
			load_mdr = `YES;
			mem_read = `YES;												// force mem_write and mem_read not to be simultaneously active
			mem_write = `NO; 
		end
		
		LDR2: begin															// 10.8 LW Instruction
			loadPC(pcmux::pc_plus4);									// load_pc <== 1; pcmux_sel <== 0
                        setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add);
		   case (load_funct3)
                        /* 3'b000 */   lb: loadRegfile(regfilemux::lb);   // 4'b0101
                        /* 3'b100 */   lbu: loadRegfile(regfilemux::lbu); // 4'b0110
			/* 3'b001 */   lh:  loadRegfile(regfilemux::lh);  // 4'b0111
			/* 3'b101 */   lhu: loadRegfile(regfilemux::lhu); // 4'b1000
                        /* 3'b010 */   lw:  loadRegfile(regfilemux::lw);  // 4'b0011
		                       default: loadRegfile(regfilemux::lw); 
		   endcase
		end
		
		STR1: begin															// 10.9 SW Instruction
			mem_read = 	`NO;												// mem_read and mem_write cannot both be active
			mem_write = `YES;
			// Need to set ALU and mem_byte_enable such that M[rs1+s_imm][x:y] <== rs2[x:y]
		        setALU(alumux::rs1_out, alumux::s_imm, 1, alu_add);	
			case (store_funct3)
				/* 3'b000 */ sb: mem_byte_enable = ((`WONE_BYTES) << (mem_addr_mask));		// used for byte alignment (masking bits we want in range x:y)
				/* 3'b001 */ sh: mem_byte_enable = ((`WHALF_BYTES) << (mem_addr_mask));		// used for half word alignment (masking bits we want in range x:y)
				/* 3'b010 */ sw: mem_byte_enable = (`WALL_BYTES);
				default: mem_byte_enable = ((`WALL_BYTES));
			endcase
		end
		
		STR2: begin															// 10.9 SW Instruction
			loadPC(pcmux::pc_plus4);									// load_pc <== 1; pcmux_sel <== 0
		end
		
		// rd <== (u_imm << 12) + PC
 		AUIPC: begin														// 10.10 AUIPC Instruction
			// regfilemux_sel <== 0; load_regfile <== 1
			load_regfile = `YES;
			regfilemux_sel = regfilemux::alu_out;
			setALU(alumux::pc_out, alumux::u_imm, 1, alu_add); // alumux1_sel <== 1; alumux2_sel <== 1; aluop <== alu_add
			loadPC(pcmux::pc_plus4);									// load_pc <== 1; pcmux_sel <== 0
		end
		// rd <== u_imm << 12
		LUI: begin															// 10.11 LUI Instruction
			loadPC(pcmux::pc_plus4);									// load_pc <== 1; pcmux_sel <== 0
			loadRegfile(regfilemux::u_imm);							// load_regfile <== 1; regfilemux_sel <== 2
		end
		
		/* Need to set ALU such that rd <== rs1 * rs2 where * is the selected operation. */
		REG_REG_OPS: begin
			loadRegfile(regfilemux::alu_out);						// load_regfile <== 1; regfilemux_sel <== 0
			loadPC(pcmux::pc_plus4);									// load_pc <== 1; pcmux_sel <== 0
			aluop = alu_ops'(funct3);
			alumux2_sel = alumux::rs2_out;							// alumux2_sel <== 5 ?? TODO: Check this
			alumux1_sel	= alumux::rs1_out;
		   case (arith_funct3_t'(funct3))
				default:		aluop = alu_ops'(funct3);
				// rd <== rs1 << rs2
				sll:			aluop = alu_sll;
				// rd <== rs1 ^ rs2
				axor:			aluop = alu_xor;
				// rd <== rs1 | rs2
				aor:			aluop = alu_or;
				// rd <== rs1 & rs2
				aand:			aluop = alu_and;
				/* Need to check funct7 to differentiate ADD/SUB and SRL/SRA instructions */
				/* see https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf#page=27 */
				sr:			aluop = (funct7 == `SPECIAL) ? alu_sra : alu_srl;				// rd <== rs1 >>/<< rs2
				add:			aluop = (funct7 == `SPECIAL) ? alu_sub : alu_add;				// rd <== rs1 +/- rs2
				/* Set CMP in SLT and SLTU similar to cases for REG_IMM_OPS */
				// rd <== (rs1 < rs2) ? 1:0
				slt: begin											// signed comparison for less than; set BLT select signal;
					loadRegfile(regfilemux::br_en);			// load_regfile <== 1; regfilemux_sel <== 1 
					setCMP(cmpmux::rs2_out, blt);				// cmpop <== blt; cmpmux_sel <== 0
				end
				// rd <== (unsigned'(rs1) < unsigned'(rs2)) ? 1:0
				sltu: begin											// unsigned comparison for less than; set BLTU select signal;
					loadRegfile(regfilemux::br_en);			// load_regfile <== 1; regfilemux_sel <== 1 
					setCMP(cmpmux::rs2_out, bltu);			// cmpop <== bltu; cmpmux_sel <== 0
				end
			endcase
		end
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  `GOTO( (rst == `NO) ? state : FETCH1);
	   case (state)
		FETCH1: `GOTO(FETCH2);
		FETCH2: `GOTO( (mem_resp == `NO) ? FETCH2 : FETCH3);
		FETCH3: `GOTO(DECODE);
		DECODE: begin
			/* Use enumerated typedefs given in rv32i_types.sv */
			unique case (opcode)																// transition to proper next state after decoding opcode from instruction;
				op_load:		`GOTO(CALC_ADDR);
				op_store:	`GOTO(CALC_ADDR);
				op_imm:		`GOTO(REG_IMM_OPS);
				op_br:		`GOTO(BR);
				op_lui:	   `GOTO(LUI);
				op_auipc:   `GOTO(AUIPC);
				op_reg:		`GOTO(REG_REG_OPS);
				op_jalr:		`GOTO(JMP);
				op_jal:		`GOTO(JMP);
				default:		`GOTO(FETCH1); 
			endcase
		end
		CALC_ADDR: begin																// need to transition to proper next state and activate control signals based on opcode;
			/* Use enumerated typedefs given in rv32i_types.sv */
			unique case (opcode)
				op_store: 					`GOTO(STR1);
				op_load:  					`GOTO(LDR1);
				default: 					`GOTO(FETCH1);
			endcase
		end
		LDR1: 			`GOTO( (mem_resp == `NO) ? LDR1 : LDR2);
		STR1: 			`GOTO( (mem_resp == `NO) ? STR1 : STR2);
		LDR2: 			`GOTO(FETCH1);
		STR2: 			`GOTO(FETCH1);
		BR:				`GOTO(FETCH1);
		JMP:           `GOTO(FETCH1);
      REG_REG_OPS:	`GOTO(FETCH1);
		REG_IMM_OPS: 	`GOTO(FETCH1);
		LUI: 				`GOTO(FETCH1);
		AUIPC: 			`GOTO(FETCH1);
		default: 		`GOTO(FETCH1);
	 endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_states;
end

endmodule : cpu_control
