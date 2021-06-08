`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
/* macros for interfacing with padding units */
`define SEXT				1'b0
`define ZEXT				1'b1
`define PAD_LEFT			1'b1
`define PAD_RIGHT			1'b0
`define ADDR_MOD4_MASK			32'hFFFFFFFC
/* Implementation of CMP module for datapath (comparator) */
`define     CHECK_EQU               3'b000
`define     CHECK_NEQU              3'b001
`define     CHECK_LESS              3'b100
`define     CHECK_LESS_UNSIGNED     3'b110
`define     CHECK_GREQ              3'b101
`define     CHECK_GREQ_UNSIGNED     3'b111
`define		IS_EQUAL(x,y)				\
				( (x) == (y) )
`define		IS_LESS(x,y)				\
					(signed'((x)) < signed'((y)) )
`define		IS_LESS_UNSIGNED(x,y)	\
					(unsigned'((x)) < (unsigned'(y)) )
module cmp
(
	input  branch_funct3_t cmpop,
	input  rv32i_word	cmp_mux_out,
	input  rv32i_word	rs1_out,
	output logic br_en
);
		always_comb begin
			case (cmpop)
				`CHECK_EQU :          br_en = `IS_EQUAL(rs1_out, cmp_mux_out);    
				`CHECK_NEQU:          br_en = !(`IS_EQUAL(rs1_out, cmp_mux_out)); 
				`CHECK_LESS:          br_en = `IS_LESS(rs1_out, cmp_mux_out);     
				`CHECK_LESS_UNSIGNED: br_en = `IS_LESS_UNSIGNED(rs1_out, cmp_mux_out); 
				`CHECK_GREQ:          br_en = !(`IS_LESS(rs1_out, cmp_mux_out));       
				`CHECK_GREQ_UNSIGNED: br_en = !(`IS_LESS_UNSIGNED(rs1_out, cmp_mux_out)); 
				default: ;
			endcase
		end
endmodule
/**********************************************************************/
module cpu_datapath
(
    input clk,
    input rst,
    input load_mdr,
    input rv32i_word mem_rdata,     // from input port, to MDR
    output rv32i_word mem_wdata, // signal used by RVFI Monitor     // from mem_data_out, to output port
    /* You will need to connect more signals to your datapath module*/
    // Control to Datapath signals
    input logic load_pc,            // to PC
    input logic load_ir,            // to IR
    input logic load_regfile,       // to regfile
    input logic load_mar,           // to MAR
    //input logic load_mdr,         // to MDR
    input logic load_data_out,      // to mem_data_out
    input pcmux::pcmux_sel_t pcmux_sel, //  to PCMUX
    input branch_funct3_t cmpop,        // to CMP
    input alumux::alumux1_sel_t alumux1_sel,    // to ALUMUX1
    input alumux::alumux2_sel_t alumux2_sel,    // to ALUXMUX2
    input regfilemux::regfilemux_sel_t regfilemux_sel,  // to regfilemux
    input marmux::marmux_sel_t marmux_sel,              // to MARMUX
    input cmpmux::cmpmux_sel_t cmpmux_sel,              // to CMPMUX
    input alu_ops aluop,                                // to ALU
    // Datapath to Control signals
    output rv32i_opcode opcode,                         // from IR, to Controller
    output logic[2:0] funct3,                           // from IR, to Controller
    output logic[6:0] funct7,                           // from IR, to Controller
    output logic      br_en,                            // from CMP, to Controller and Regfilemux
    output logic[4:0] rs1,                              // from Regfile, to ALUMUX1 and CMP
    output logic[4:0] rs2,                              // from Regfile, to CMPMUX and mem_data_out
    // Memory to Datapath signals
    // input rv32i_word mem_rdata,
    // Datapath to Memory signals
    //output rv32i_word mem_wdata
    output rv32i_word mem_address,                       // from MAR, to output port
    output logic[1:0] mem_addr_mask,			// from Datapath to controller
    output logic[1:0] alu_mask,                          // from Datapath to Controller
    output logic[1:0] mar_mask,
    output logic[31:0] mem_addr
    );
/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
/****************************** HELPER MACROS DECLARATIONS *******************/
`define ASSIGN(sig, val)	\
	sig = (val)
	
`define ALIGN_ADDR(signal, lsb)	\
	{signal[31:(lsb)], {(lsb){1'b0}} }
`define ZEXT32(sig, size)			\
	 { {(32-(size)){1'b0}}, sig[((size)-1):0]}
/*****************************************************************************/
/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
rv32i_word marmux_out;
rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm; 		// internal registers for i_imm, ... j_imm, signals.
rv32i_reg rd;													// internal connection for rd signal
rv32i_word	mem_address_out;								// internal register to force address alignment
rv32i_word rs1_out;											// internal rs1_out register
rv32i_word rs2_out;											// internal rs2_out register
// IR Register
ir IR(
	.clk		(clk),
	.rst		(rst),
	.load		(load_ir),										// from Controller, to IR
	.in 		(mdrreg_out),									// from MDR, to regfilemux, IR
	.funct3  (funct3),										// from IR, to Controller
	.funct7 	(funct7),										// from IR, to Controller
	.opcode	(opcode),										// from IR, to Controller
	.i_imm	(i_imm),											// from IR, to alumux2, cmpmux
	.s_imm	(s_imm),											// from IR, to alumux2
	.b_imm	(b_imm),											// from IR, to alumux2
	.u_imm	(u_imm),											// from IR, to alumux2, regfilemux
	.j_imm	(j_imm),											// from IR, to alumux2
	.rs1		(rs1),											// from IR, to regfile, Controller
	.rs2		(rs2),											// from IR, to regfile, Controller
	.rd		(rd)												// from IR, to regfile
);

// MAR and MDR registers
register MAR(
	.clk		(clk),
	.rst		(rst),
	.load		(load_mar),										// from Controller, to MAR
	.in		(marmux_out),									// from marmux, to MAR
	.out		(mem_address_out)								// from MAR, to internal register and then to output port
);	
assign mem_address = (mem_address_out & (`ADDR_MOD4_MASK));					// forces memory alignment (constraint) by chopping off last 2 bits
assign mem_addr = (mem_address_out & (`ADDR_MOD4_MASK));
assign mar_mask = {marmux_out[1],marmux_out[0]};
assign mem_addr_mask = {mem_address_out[1], mem_address_out[0]};
rv32i_word mem_data_in;
// MDR Register
register MDR(
    .clk  	(clk),
    .rst 	(rst),
    .load 	(load_mdr),											// from Controller, to MDR
    .in   	(mem_rdata),										// from input port, to MDR
    .out  	(mdrreg_out)										// from MDR, to regfilemux, IR
);

// MEM_DATA_OUT Register (described in block diagram and 13.1 Datapath Signals)

register MEM_DATA_OUT	(
	.clk		(clk),
	.rst		(rst),
	.load		(load_data_out),		// from Controller, to mem_data_out
	.in		(mem_data_in),				// from regfile , to mem_data_out
	.out            (mem_wdata)				// from mem_data_out, to output signal
);
/*****************************************************************************/

/******************************* ALU and CMP *********************************/
rv32i_word	alumux1_out;
rv32i_word	alumux2_out;
rv32i_word	alu_out;
rv32i_word	alu_out_mod2;										// see RISC-V Spec, page 17 on differences between U and J formats
assign alu_out_mod2 = `ALIGN_ADDR(alu_out, 1);			// only top 31 bits are used for J-type instructions?

/* ALU */
alu ALU	(
	.aluop	(alu_ops'(aluop)),				// from Controller, to ALU
	.a			(alumux1_out),		// from alumux1, to ALU
	.b			(alumux2_out),		// from alumux2, to ALU
	.f			(alu_out)			// from ALU, to regfilemux, marmux, pcmux
);

rv32i_word	cmp_mux_out;
/* CMP */
cmp CMP (
	.cmpop			(branch_funct3_t'(cmpop)),			// from Controller, to CMP; cast to branch_funct3_t needed or BAD_MUX_SEL error thrown.
	.cmp_mux_out	(cmp_mux_out),							// from cmpmux, to CMP
	.rs1_out			(rs1_out),								// from regfile, to CMP
	.br_en			(br_en)									// from CMP, to controller, regfilemux
);
/*****************************************************************************/
/******************************** PC *****************************************/
rv32i_word	pc_out;
/* PC */
pc_register PC	(
	.clk		(clk),
	.rst		(rst),
	.load		(load_pc),		// from Controller, to PC
	.in		(pcmux_out),	// from pcmux, to PC
	.out		(pc_out)			// from PC, to pc_plus4, alumux1, marmux
);
/*****************************************************************************/
/******************************** RegFile ************************************/
rv32i_word	regfilemux_out;
/* Regfile */
regfile regfile	(
	.clk		(clk),
	.rst		(rst),
	.load		(load_regfile),		// from Controller, to regfile
	.in		(regfilemux_out),		// from regfilemux, to regfile
	.src_a	(rs1),					// from IR to regfile, Controller
	.src_b	(rs2),					// from IR to regfile, Controller
	.dest		(rd),						// from IR to regfile
	.reg_a	(rs1_out),				// from regfile, to alumux1, CMP
	.reg_b	(rs2_out)				// from regfile, to CMPMUX, mem_data_out
);
/*****************************************************************************/
logic[1:0] __br;						// internal array putting br_en into correct format so helper macro can proces it.
assign alu_mask = {alu_out[1], alu_out[0]};
/* mask out/apply padding to select correct bits at datasize boundaries when writing to memory */
/* encapsulates logic to explicitly align data */
padding_unit #(.mode(`PAD_RIGHT)) rs2_padder
(
        .load(1'b1),
	.sig(rs2_out),
	.mask(alu_mask),            // need to use alu_mask because mem_addr_mask is a cycle behind and causes a mem_wdata mismatch
	.op(funct3),
        .out(mem_data_in)
);

/* logic to select correct bits at datasize boundaries when reading from memory */
/* encapsulates sign/zero extension and byte masking logic */
rv32i_word ext32_out;
ext_unit #(.size(32)) ext32
(
        .load(1'b1),
	.sig (mdrreg_out),
	.mask(mem_addr_mask),
        .ld_op(funct3),
        .out(ext32_out)
);

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
    /* pc mux */
	 /* Enumerated typedefs defined in rv32i_mux_types.sv */
	 unique case (pcmux_sel)
        pcmux::pc_plus4: `ASSIGN(pcmux_out, pc_out+4);     
		  pcmux::alu_out:	 `ASSIGN(pcmux_out, alu_out);     // see rv32i_mux_types.sv
		  pcmux::alu_mod2: `ASSIGN(pcmux_out, alu_out_mod2);// see rv32i_mux_types.sv and comment above
        // etc.
        default: `BAD_MUX_SEL;
    endcase
	 
	/* cmp mux */
	/* Enumerated typedefs defined in rv32i_mux_types.sv */
	unique case (cmpmux_sel)
		default: `BAD_MUX_SEL;
		cmpmux::i_imm:	  `ASSIGN(cmp_mux_out, i_imm);
		cmpmux::rs2_out: `ASSIGN(cmp_mux_out, rs2_out); 
	endcase
	
	/* Regfile Mux */
	/* Enumerated typedefs defined in rv32i_mux_types.sv */
	__br =  {1'b0, br_en};                                  // __br loaded with {0, br_en}
	unique case (regfilemux_sel)
		default: `BAD_MUX_SEL;
		regfilemux::alu_out:	 `ASSIGN(regfilemux_out, alu_out);
		regfilemux::u_imm:	 `ASSIGN(regfilemux_out, u_imm);					
		regfilemux::pc_plus4:   `ASSIGN(regfilemux_out, pc_out+4);
		regfilemux::br_en:      `ASSIGN(regfilemux_out, `ZEXT32(__br,1));			// need to zero out top 31 bits to conform to spec.
		regfilemux::lw:		 `ASSIGN(regfilemux_out, mdrreg_out);	

		// need to perform SEXT/ZEXT operations to conform to spec.
		// SEE page 19: https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf#page=30
                // LB loads 8-bit value from memory, sign extends to 32 bits before storing in rd
                regfilemux::lb:		`ASSIGN(regfilemux_out,ext32_out); 
                // LBU loads 8-bit value from memory, zero extends to 32 bits before storing in rd
		regfilemux::lbu:	`ASSIGN(regfilemux_out,ext32_out);
                // LH loads 16-bit value from memory, sign extends to 32-bits before storing in rd
		regfilemux::lh:		`ASSIGN(regfilemux_out,ext32_out);
                // LHU loads 16-bit value from memory, zero extends to 32-bit before sotring in rd
		regfilemux::lhu:	`ASSIGN(regfilemux_out,ext32_out);
	endcase
	
	/* MAR mux */
	/* Enumerated typedefs defined in rv32i_mux_types.sv */
	unique case (marmux_sel)
		default: `BAD_MUX_SEL;
		marmux::alu_out:  `ASSIGN(marmux_out, alu_out);
		marmux::pc_out:	`ASSIGN(marmux_out, pc_out); 
	endcase
	
	/* ALU Mux (1) */
	/* Enumerated typedefs defined in rv32i_mux_types.sv */
	unique case (alumux1_sel)
		default: `BAD_MUX_SEL;
		alumux::pc_out:	`ASSIGN(alumux1_out, pc_out); 
		alumux::rs1_out:	`ASSIGN(alumux1_out, rs1_out);	
	endcase
	
	/* ALU Mux (2) */
	/* Enumerated typedefs defined in rv32i_mux_types.sv */
	unique case (alumux2_sel)
		default: `BAD_MUX_SEL;
		alumux::rs2_out:  `ASSIGN(alumux2_out, rs2_out);
		alumux::i_imm: 	`ASSIGN(alumux2_out, i_imm);
		alumux::u_imm:		`ASSIGN(alumux2_out, u_imm);
		alumux::b_imm:		`ASSIGN(alumux2_out, b_imm);
		alumux::s_imm:		`ASSIGN(alumux2_out, s_imm);
		alumux::j_imm:		`ASSIGN(alumux2_out, j_imm);
	endcase
end
/*****************************************************************************/
endmodule : cpu_datapath
