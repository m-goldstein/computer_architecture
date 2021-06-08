
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
import ctrl_word::*;
import pipe_types::*;
import rv32i_types::*;
//import rv32i_types::*;
/* To assist in debugging, please pass the entire control
word as well as the instuction's opcode and PC down the pipeline. */
module datapath
(
    input logic clk,
    input logic rst,
    input ctrl_word::ctrl_word_t ctrl_word,
    input logic [31:0] inst_cache_rdata,
    input logic [31:0] datacache_rdata,
    input logic inst_resp,
    input logic data_resp,

	// synthesis turn off
	// input logic [1:0] arbiter_state,
	// input pmem_read,
	// input pmem_write,
	// synthesis turn on

    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic inst_read,
    output logic data_read,
    output logic data_write,
    output rv32i_types::rv32i_opcode opcode,
    output logic [31:0] inst_cache_address,
    output logic [31:0] datacache_wdata,
    output logic [31:0] datacache_address,
    output logic [3:0]  datacache_mem_byte_enable
);

    /* Pipeline Register Structures */
    pipe_types::pipeline_reg_t if_id_reg;
    pipe_types::pipeline_reg_t id_ex_reg;
    pipe_types::pipeline_reg_t ex_mem_reg;
    pipe_types::pipeline_reg_t mem_wb_reg;


    /* Hazard Detection */
    pipe_types::stall_load_reg_t reg_stall;    /* bit structure for stalling registers via load signal */
    forwardmux::id_ex_mux_sel_t id_ex_ctrlmux_sel; /* Select signal for mux in ID stage that selects whther to flush control or no */

    /* INTER STAGE SIGNALS */
    /* EXECUTE */
    logic [31:0] br_en_zext;
    logic cmp_out;
    logic br_en;
    logic [31:0] alu_out;
    rv32i_word nop_inst;

    assign nop_inst = 32'h00000000;
    assign br_en_zext = 32'({31'd0,  cmp_out});
    assign br_en =  (ex_mem_reg.opcode == op_jalr) || (ex_mem_reg.opcode == op_jal) || ((ex_mem_reg.opcode == op_br) && ex_mem_reg.br_en);
    // jal, jalr are unconditional

    logic pipe_reg_rst;
    logic ifid_load;
    logic pipe_load;
    logic pipe_busy;
	logic busy;

/* Stalling Logic */
	logic instruction_read;
	logic delay_resp;          /* keeps a resp signal high until*/
	always_comb begin
		if( ( (inst_read & ~inst_resp) | ( (data_read | data_write) & ~data_resp ) )  ) begin
			busy = 1;
		end
		else begin
			busy = 0;
		end
	end

	/* Stalling Response logic,*/
	//assign inst_read  = instruction_read & ~delay_resp;
	assign inst_read  = instruction_read;
	assign data_read  = ex_mem_reg.word.datacache_mem_read & ~delay_resp;
	assign data_write = ex_mem_reg.word.datacache_mem_write & ~delay_resp;
	always_ff @( posedge clk ) begin  /* sample on each posedge of clock */
		if (busy & data_resp) begin
			delay_resp <= 1'b1;
		end
		else begin
			delay_resp <= 1'b0;
		end
	end

    // pipeline busy if no (instruction response or no inst_cache read) or no (data response or data_cache requests)
    //assign busy  = (~(inst_resp || ~instruction_read) || ~(data_resp || (~data_read && ~data_write))) ? 1'b1 : 1'b0;

    //assign pipe_reg_rst = (rst || ~(~br_en || busy)) ? 1'b1 : 1'b0;
    assign ifid_load = (~busy && reg_stall.load_if_id);
    assign pipe_load = ~busy;
    assign fetch_pc_en = (~busy && reg_stall.load_pc);
    /* WB STAGE */
    logic [31:0] regfilemux_out;

    /*************************************************************************************************/
    /******************************Hazard and Forwarding Unit *******************************************/
    forwardmux::forwardmux1_sel_t forwardmux1_sel;
    forwardmux::forwardmux2_sel_t forwardmux2_sel;
    forwardmux::forwardmux_mem_sel_t forwardmux_mem_sel;

    rv32i_word ex_mem_rs1_out;
    rv32i_word mem_wb_rs1_out;
    rv32i_word ex_mem_rs2_out;
    rv32i_word mem_wb_rs2_out;
    rv32i_word forward_regfilemux_out;

    rv32i_word forwardmux1_out;
    rv32i_word forwardmux2_out;
    rv32i_word forwardmux_mem_out;




    forward_unit forward_unit(
	.clk                     (clk),
	.if_id                   (if_id_reg),
	.id_ex                   (id_ex_reg),
	.ex_mem                  (ex_mem_reg),
	.mem_wb                  (mem_wb_reg),
	.regfilemux_out          (regfilemux_out),
	.forwardmux1_sel         (forwardmux1_sel),
	.forwardmux2_sel         (forwardmux2_sel),
	.forwardmux_mem_sel      (forwardmux_mem_sel),
	.load_pc                 (reg_stall.load_pc),
	.if_id_load              (reg_stall.load_if_id),
	.id_ex_mux_sel           (id_ex_ctrlmux_sel),
	.ex_mem_rs1_out          (ex_mem_rs1_out),
	.mem_wb_rs1_out          (mem_wb_rs1_out),
	.ex_mem_rs2_out          (ex_mem_rs2_out),
	.mem_wb_rs2_out          (mem_wb_rs2_out),
	.forward_regfilemux_out  (forward_regfilemux_out)
    );

    /*************************************************************************************************/
    /******************************* INSTUCTION FETCH STAGE *********************************/
    logic ctrl_nop_sel;
    logic [31:0] pc_out;
    logic [31:0] pcmux_out;			               /* PC address chosen by logical flow */
    logic [31:0] branch_pcmux_out;                 /* pc address chosen by branch prediction */
    rv32i_word fetched_instruction;                /* 32-bit instruction from memory or nop */

    pipe_types::pipeline_reg_t if_id_reg_nop;	   /* nop, if_id struct */
    pipe_types::pipeline_reg_t id_ex_reg_nop;      /* nop, id_ex struct */

    ctrl_word::ctrl_word_t nopctrl_branchmux_out;
    nopmux::nop_rdata_sel_t nopmux_sel;			   			/* Selects inst_rdata or nop */
    nopmux::nop_if_id_sel_t if_id_nopmux_sel;         			/* Selects if_id_reg or nop  */
    nopmux::nop_id_ex_sel_t id_ex_nopmux_sel; 					/* Selects id_ex struct or nop &*/
    branchmux::static_branch_sel_t static_branchmux_sel;    /* Slects static branch prediction or normal sequence */

	assign instruction_read = (rst) ? 1'b0 : 1'b1;

    /* FETCH */
    assign inst_cache_address = pc_out;

    pc_register PC(
	.clk    (clk),
	.rst    (rst),
	.load   ( fetch_pc_en),
	.in     (branch_pcmux_out),
	.out    (pc_out)
    );

	/* RETURN STACK ADDRESS: predicts return address to avoid unnecessary flushes, grabs instruction from decode */
	/*
	rv32i_word ras_address_out; 
	logic pop;
	RAS stack(
    .clk             (clk),
    .rst             (rst),
	.rs1_addr        (inst_cache_address[19:15]),
	.rd_addr         (inst_cache_address[11:7]),
    .opcode_in       (rv32i_types::rv32i_opcode'(inst_cache_address[6:0]) ),
    .pc_out          (pc_out),

	.pop             (pop),
    .return_address  (ras_address_out)
	);
	*/
    /**** Branch Prediction MUX ***/

	always_comb begin
		unique case (static_branchmux_sel)
			branchmux::pc_plus4  :   begin
				// if(pop)
				// 	branch_pcmux_out = ras_address_out;
				// else
				branch_pcmux_out = pc_out + 4;
			end
			branchmux::pcmux_out :     branch_pcmux_out = pcmux_out;
			default: branch_pcmux_out = pc_out+4;
		endcase
	end
    //assign branch_pcmux_out = (static_branchmux_sel == branchmux::pc_plus4) ? (pc_out+4) : pcmux_out;


    /* ***PC MUX*** Currently Not Used*/
    //assign pcmux_out = (br_en) ? (pc_out+4) : {ex_mem_reg.alu_out[31:2],2'b0};
	always_comb begin

		unique case ( {br_en, (br_en & (ex_mem_reg.opcode == op_jalr) )} )
			pcmux::pc_plus4 :        pcmux_out = pc_out + 4;
			pcmux::alu_out  :        pcmux_out = ex_mem_reg.alu_out;
			pcmux::alu_mod2 :        pcmux_out = {ex_mem_reg.alu_out[31:1],1'b0};
			default: pcmux_out = pc_out + 4;
		endcase

	end

    /* NOP MUX, if branch prediction is incorrect, put nop in if_id register */
    assign fetched_instruction = (nopmux_sel == nopmux::nop) ? nop_inst : inst_cache_rdata;

    /* Branch Predictor Unit */
    always_comb begin
	/* Mispredicted branch  in MEM stage */
	if( br_en == 1'b1 /*& ~ex_mem_reg.pop*/) begin
	    static_branchmux_sel = branchmux::pcmux_out;
	    // flush the pipeline instructions in IF, ID and EX stage. This is done with nops
	    nopmux_sel = nopmux::nop;                 /* Changes instruction in IF stage to NOP */

	    if_id_nopmux_sel     = nopmux::if_id_nop; /* Changes instruction in ID stage to NOP */
	    if_id_reg_nop.i_imm  = 0;
	    if_id_reg_nop.rs1    = 0;
	    if_id_reg_nop.funct3 = 0;
	    if_id_reg_nop.rd     = 0;
	    if_id_reg_nop.opcode = rv32i_opcode'(0);
	    ctrl_nop_sel         = 1'b1;

	    id_ex_nopmux_sel     = nopmux::id_ex_nop; /* Changes instruction in EX stage to NOP */
	    id_ex_reg_nop.i_imm  = 0;
	    id_ex_reg_nop.rs1    = 0;
	    id_ex_reg_nop.funct3 = 0;
	    id_ex_reg_nop.rd     = 0;
	    id_ex_reg_nop.opcode = rv32i_opcode'(0);
	    id_ex_reg_nop.word   = 0;
	end
	/* Predict Static Branch, IF, ID, and EX aren't filled with nops */
	else begin
	    nopmux_sel 	            = nopmux::inst_rdata;
	    if_id_nopmux_sel        = nopmux::if_id;
	    id_ex_nopmux_sel        = nopmux::id_ex;
	    static_branchmux_sel    = branchmux::pc_plus4;
	    ctrl_nop_sel            = 1'b0;
	end
    end

    /***************************************************************************************/
    /******************************* IF_ID Pipeline Register *********************************/
    IF_ID_register IF_ID_REG(
	.clk                   (clk),
	.rst                   (rst),
	.load                  (ifid_load),
	.pop_in                (pop),
	.pcmux_out             (branch_pcmux_out),
	.pc_out                (pc_out),                /* Incorrect if branch is mispredicted */
	.inst_cache_rdata_in   (fetched_instruction),
	.if_id_pipe_reg_out    (if_id_reg)
    );
    /***************************************************************************************/
    /******************************* DECODE DATAPATH ELEMENTS *********************************/

    /* DECODE  */
    logic [31:0] rs1_out;
    logic [31:0] rs2_out;
    pipe_types::pipeline_reg_t if_id_regmux_out;   /* Output of IF_ID nop mux */

    /* Hazard Detection */
    ctrl_word::ctrl_word_t id_ex_ctrlmux_out;

	/* Branch Predictor */
	pipe_types::pipeline_reg_t id_ex_regmux_out;   /* id_ex struct or nop */

    assign funct3    = if_id_reg.funct3;
    assign funct7    = if_id_reg.funct7;
    assign opcode    = rv32i_types::rv32i_opcode'(if_id_reg.opcode);

    /* ***REGFILE*** */
    regfile regfile(
	.clk     (clk),
	.rst     (rst),
	.load    (mem_wb_reg.word.load_regfile),
	.in      (regfilemux_out),
	.src_a	 (if_id_reg.rs1),
	.src_b   (if_id_reg.rs2),
	.dest    (mem_wb_reg.rd),
	.reg_a   (rs1_out),
	.reg_b   (rs2_out)
    );

	 /* IF_ID MUX or NOP */
    assign if_id_regmux_out      = (if_id_nopmux_sel == nopmux::if_id) ? if_id_reg : if_id_reg_nop;

    /* ID_EX MUX CTRL WORD: Controls whether nop or ctrl word enters id_ex reg depending on if read after load, Hazard detection mux */
    assign id_ex_ctrlmux_out     = (id_ex_ctrlmux_sel == forwardmux::nop) ? 'd0 : ctrl_word;

	/* Branch Prediction MUX, if branch, choose '0' for control word even if no hazard detected, else choose output dependent on if there is a hazard */
    assign nopctrl_branchmux_out = (ctrl_nop_sel == 1'b1 ) ? 0 : id_ex_ctrlmux_out;

	/* ID_EX MUX or NOP,  if branch predictor is wrong, then fucking put a nop into ex_mem*/
    assign id_ex_regmux_out      = (id_ex_nopmux_sel == nopmux::id_ex) ? id_ex_reg : id_ex_reg_nop;

    /* ***Control ROM*** */

    /***************************************************************************************/
    /******************************* ID_EX Pipeline Register *********************************/
    ID_EX_register ID_EX_REG(
	.clk                   (clk),
	.rst                   (rst),
	.load                  (pipe_load),
	.rs1_out               (rs1_out),          /*input*/
	.rs2_out               (rs2_out),          /*input*/
	.id_ex_word_in         (nopctrl_branchmux_out),    /* ctrl_word, id_ex_ctrlmux_out */
	.id_ex_pipe_reg_in     (if_id_regmux_out),
	.id_ex_pipe_reg_out    (id_ex_reg)
    );



    /****************************************************************************************/
    /******************************* EXECUTE DATAPATH ELEMENTS *********************************/

    /* EXECUTE OUTPUT*/
    logic [31:0] alumux1_out;
    logic [31:0] alumux2_out;
    logic [31:0] cmpmux_out;


    /* ***ALU*** */
    alu ALU(
	.aluop       (id_ex_reg.word.aluop),
	.a           (alumux1_out),
	.b		 	 (alumux2_out),
	.f		     (alu_out)
    );


    /* ***CMP*** */
    cmp CMP(
	.first      (forwardmux1_out),
	.second     (cmpmux_out),
	.cmpop      (id_ex_reg.word.cmpop),
	.out        (cmp_out)
    );

    always_comb begin : EX_MUXES
		/* ***ALU MUX 1*** */
		unique case (id_ex_reg.word.alumux1_sel)
			alumux::rs1_out:             alumux1_out = forwardmux1_out;
			alumux::pc_out:              alumux1_out = id_ex_reg.pc_out;
			default: alumux1_out = forwardmux1_out;
		endcase

		/****ALU MUX 2*** */
		unique case (id_ex_reg.word.alumux2_sel)
			alumux::i_imm:      alumux2_out = id_ex_reg.i_imm;
			alumux::u_imm:      alumux2_out = id_ex_reg.u_imm;
			alumux::b_imm:      alumux2_out = id_ex_reg.b_imm;
			alumux::s_imm:      alumux2_out = id_ex_reg.s_imm;
			alumux::j_imm:
			begin
				if(id_ex_reg.word.opcode == rv32i_types::op_jal)
					alumux2_out = $signed(id_ex_reg.j_imm);  // not doing anything? okay....
				else
					alumux2_out = id_ex_reg.j_imm;
			end
			alumux::rs2_out:    alumux2_out = forwardmux2_out;
			default:		alumux2_out = id_ex_reg.i_imm;
		endcase

		/* ***CMP MUXy*** */
		unique case (id_ex_reg.word.cmpmux_sel)
			cmpmux::rs2_out:     cmpmux_out = forwardmux2_out;
			cmpmux::i_imm:       cmpmux_out = id_ex_reg.i_imm;
			default:		 cmpmux_out = forwardmux2_out;
		endcase
		end

		always_comb begin : FORWARD_MUXES
		/* FOWARD MUX 1*/
		unique case (forwardmux1_sel)
			forwardmux::id_ex_rs1_out:        forwardmux1_out = id_ex_reg.rs1_out;
			forwardmux::ex_mem_rs1_out:       forwardmux1_out = ex_mem_rs1_out;
			forwardmux::mem_wb_rs1_out:       forwardmux1_out = mem_wb_rs1_out;
			default:			  forwardmux1_out = id_ex_reg.rs1_out;
		endcase

		/* FOWARD MUX 2*/
		unique case (forwardmux2_sel)
			forwardmux::id_ex_rs2_out:        forwardmux2_out = id_ex_reg.rs2_out;
			forwardmux::ex_mem_rs2_out:       forwardmux2_out = ex_mem_rs2_out;
			forwardmux::mem_wb_rs2_out:       forwardmux2_out = mem_wb_rs2_out;
			default:			  forwardmux2_out = id_ex_reg.rs2_out;
		endcase
    end

    /***************************************************************************************/
    /******************************* EX_MEM Pipeline Register *********************************/

    EX_MEM_register EX_MEM_REG(
	.clk                  (clk),
	.rst                  (rst),
	.load                 (pipe_load),
	.rs1_out              (forwardmux1_out),
	.rs2_out		      (forwardmux2_out),
	.ex_mem_alu_in        (alu_out),
	.ex_mem_br_en_zext_in (br_en_zext),
	.ex_mem_pipe_reg_in   (id_ex_regmux_out),
	.ex_mem_pipe_reg_out  (ex_mem_reg)
    );

    /****************************************************************************************/
    /******************************* MEMORY DATAPATH ELEMENTS *********************************/

    /* MEM Forwarding */

    /*** MEMORY Logic ***/
    rv32i_word datacache_wdata_path;
    assign datacache_address = {ex_mem_reg.alu_out[31:2],2'b0}; //& 2'b11;
    assign datacache_wdata = datacache_wdata_path;

    /* FORWARD MEM MUX*/
    assign forwardmux_mem_out = (forwardmux_mem_sel == forwardmux::rs2_out) ? ex_mem_reg.rs2_out : regfilemux_out;

    /* Store Align MUX, store a byte, half-word or word into memory depending on funct3 field for Store */
    always_comb begin

		unique case( rv32i_types::store_funct3_t'(ex_mem_reg.funct3) )
			rv32i_types::sb:
				begin
					datacache_mem_byte_enable = (4'b0001 << ( ex_mem_reg.alu_out & 2'b11 ) );
					datacache_wdata_path      = (32'(forwardmux_mem_out[7:0] << ((ex_mem_reg.alu_out & 2'b11) << 3) ) );
				end
			rv32i_types::sh:
				begin
					datacache_mem_byte_enable = (4'b0011 << ( ex_mem_reg.alu_out & 2'b11 ) );
					datacache_wdata_path      = (32'(forwardmux_mem_out[15:0] << ((ex_mem_reg.alu_out & 2'b11) << 3) ) );
				end
			rv32i_types::sw:
				begin
					datacache_mem_byte_enable = 4'b1111;
					datacache_wdata_path      = forwardmux_mem_out;
				end
			default:
				begin
					datacache_mem_byte_enable = 4'b1111;
					datacache_wdata_path      = forwardmux_mem_out;
				end
		endcase
    end
    /***************************************************************************************/
    /******************************* MEM_WB Pipeline Register *********************************/
    MEM_WB_register MEM_WB_REG(
	.clk                 (clk),
	.rst                 (rst),
	.load                (pipe_load),
	.datacache_address   (datacache_address),
	.data_cache_rdata_in (datacache_rdata),
	.mem_wb_pipe_reg_in  (ex_mem_reg),
	.mem_wb_pipe_reg_out (mem_wb_reg)
    );
    /****************************************************************************************/
    /******************************* WRITE BACK DATAPATH ELEMENTS ***************************/

    /* WRITE BACK */
    //logic [31:0] regfilemux_out;
    //logic[31:0] datacache_rdata_out;
	//assign mem_wb_reg.regfilemux_out = regfilemux_out;

    /* ***MUXES*** */
    always_comb begin
		/* ***REGFILEMUX*** */
		unique case (mem_wb_reg.word.regfilemux_sel)
			regfilemux::br_en:       regfilemux_out = mem_wb_reg.br_en;//br_en_zext;
			regfilemux::u_imm:       regfilemux_out = mem_wb_reg.u_imm;
			regfilemux::alu_out:     regfilemux_out = mem_wb_reg.alu_out;
			regfilemux::pc_plus4:    regfilemux_out = mem_wb_reg.pc_out + 4;
			/* datacache_rdata PATH */
			regfilemux::lw:	     regfilemux_out = mem_wb_reg.datacache_rdata;
			regfilemux::lh:
			begin
				case (mem_wb_reg.alu_out[1:0] & 2'b11)
				2'b00:	 regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata[15:0]));
				2'b10:	 regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata[31:16]));
				default: regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata));
				endcase
			end
			regfilemux::lhu:
			begin
				case (mem_wb_reg.alu_out[1:0] & 2'b11)
				2'b00:	 regfilemux_out = 32'({16'h0000, mem_wb_reg.datacache_rdata[15:0]});
				2'b10:	 regfilemux_out = 32'({16'h0000, mem_wb_reg.datacache_rdata[31:16]});
				default: regfilemux_out = 32'(mem_wb_reg.datacache_rdata);
				endcase
			end
			regfilemux::lb:
			begin
				case(mem_wb_reg.alu_out[1:0] & 2'b11)
				2'b00:	 regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata[7:0]));
				2'b01:	 regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata[15:8]));
				2'b10:   regfilemux_out  = 32'($signed(mem_wb_reg.datacache_rdata[23:16]));
				2'b11:	 regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata[31:24]));
				default: regfilemux_out = 32'($signed(mem_wb_reg.datacache_rdata));
				endcase
			end
			regfilemux::lbu:
			begin
				case (mem_wb_reg.alu_out[1:0] & 2'b11)
				2'b00:	 regfilemux_out = 32'({24'h000000, mem_wb_reg.datacache_rdata[7:0]});
				2'b01:	 regfilemux_out = 32'({24'h000000, mem_wb_reg.datacache_rdata[15:8]});
				2'b10:   regfilemux_out =  32'({24'h000000, mem_wb_reg.datacache_rdata[23:16]});
				2'b11:	 regfilemux_out = 32'({24'h000000, mem_wb_reg.datacache_rdata[31:24]});
				default: regfilemux_out = 32'(mem_wb_reg.datacache_rdata);
				endcase
			end
			default: `BAD_MUX_SEL;
		endcase
    end
endmodule: datapath
