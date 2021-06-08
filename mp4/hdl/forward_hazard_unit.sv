import rv32i_types::*;
import pipe_types::*;
import ctrl_word::*;

module forward_unit
(
    input logic clk,

    input pipe_types::pipeline_reg_t if_id,
    input pipe_types::pipeline_reg_t id_ex,
    input pipe_types::pipeline_reg_t ex_mem,
    input pipe_types::pipeline_reg_t mem_wb,
    
    input rv32i_word regfilemux_out,

    /* Select Signals */
    output forwardmux::forwardmux1_sel_t forwardmux1_sel,
    output forwardmux::forwardmux2_sel_t forwardmux2_sel,
    output forwardmux::forwardmux_mem_sel_t forwardmux_mem_sel,

    output logic load_pc,
    output logic if_id_load,
    output forwardmux::id_ex_mux_sel_t id_ex_mux_sel,

    /* Data Output */
    output rv32i_word ex_mem_rs1_out,
    output rv32i_word mem_wb_rs1_out,
    output rv32i_word ex_mem_rs2_out,
    output rv32i_word mem_wb_rs2_out,

    output rv32i_word forward_regfilemux_out
);

/* Hazard Detection Unit */
/* Purpose: Detect Hazards with read followed by a load */
/* Inputs: id_ex.mem_read, if_id.rs1, if_id.rs2, id_ex.rd*/
/* Outputs: mux_sel, pc_load, IF_ID_load */
/* Notes: */
always_comb begin
    
    if( (id_ex.word.datacache_mem_read == 1'b1) & ( (id_ex.rd == if_id.rs1) | (id_ex.rd == if_id.rs2) ) & (id_ex.rd != 0) 
        & (if_id.opcode != op_store) ) begin 
        //& (id_ex.rd != 0) & (id_ex.opcode != op_store) ) begin
        id_ex_mux_sel = forwardmux::nop;
        if_id_load = 1'b0;
        load_pc = 1'b0;
    end
    else begin
        id_ex_mux_sel = forwardmux::ctrl_word;
        if_id_load = 1'b1;
        load_pc = 1'b1;
    end
end

/* MEM Forwarding Unit */
/* Purpose: Forward regfilemux_out from WB stage to a store instruction in MEM stage */
/* Inputs: mem_wb.rd, mem_wb.load, regfilemux_out */
/* Outputs: regfilemux_out */
/* Notes: Possible bug with regfilemux_out, it comes from WB stage */
always_comb begin
    
    forward_regfilemux_out = regfilemux_out;

    if( (mem_wb.word.load_regfile == 1'b1) & (mem_wb.rd != 0) & (mem_wb.rd == ex_mem.rs2) )
        forwardmux_mem_sel = forwardmux::regfilemux_out;
    else
        forwardmux_mem_sel = forwardmux::rs2_out;
end

/* EX Forwarding Unit */
/* Purpose: Forward data from MEM and WB stage to be used as rs1_out or rs2_out in EX stage*/
/* Inputs: ex_mem.rd, ex_mem.load, mem_wb.rd, mem_wb.load, ex_mem.alu_out, ex_mem.u_imm, ex_mem.br_en, mem_wb.regfilemux_out*/
/* Outputs: */
/* Note: Possible bug when checking whether there is a EX-WB hazard, and making sure (ex_mem.rd == id_ex.rs1) */
/*       Possible bug with U_imm */
always_comb begin
    
    /* Forward data from WB stage to EX stage */
    mem_wb_rs1_out = regfilemux_out;
    mem_wb_rs2_out = regfilemux_out;
    /* Default Values */
    ex_mem_rs1_out = ex_mem.alu_out;
    ex_mem_rs2_out = ex_mem.alu_out;

    /* Forward MUX 1 Control */
    /* EX-MEM Hazard RS1 */
    if( (ex_mem.word.load_regfile == 1'b1) & (ex_mem.rd != 0) & (ex_mem.rd == id_ex.rs1) ) begin

        forwardmux1_sel = forwardmux::ex_mem_rs1_out; 

        if(ex_mem.opcode == op_lui) 
            ex_mem_rs1_out = ex_mem.u_imm;

        else if( (ex_mem.opcode == op_imm) & ( (ex_mem.funct3 == slt) |  (ex_mem.funct3 == sltu) ) )
            ex_mem_rs1_out = ex_mem.br_en;

        else if( (ex_mem.opcode == op_reg) & ( (ex_mem.funct3 == slt) |  (ex_mem.funct3 == sltu) ) )
            ex_mem_rs1_out = ex_mem.br_en;

        else if( ( ex_mem.opcode == op_jal) | (ex_mem.opcode == op_jalr ) )
            ex_mem_rs1_out = ex_mem.pc_out + 4;

        else 
            ex_mem_rs1_out = ex_mem.alu_out;

    end

    /* EX-WB Hazard RS1 */
    else if( (mem_wb.word.load_regfile  == 1'b1) & (mem_wb.rd != 0) & (mem_wb.rd == id_ex.rs1) & 
        ~( (ex_mem.word.load_regfile == 1'b1) & (ex_mem.rd != 0) & (ex_mem.rd == id_ex.rs1) ) )begin 

        forwardmux1_sel = forwardmux::mem_wb_rs1_out;

    end

    /* NO Hazard */
    else begin
        forwardmux1_sel = forwardmux::id_ex_rs1_out;
    end

    /* Forward MUX 2 Control */
    /* EX-MEM Hazard RS2 */
    if(  (ex_mem.word.load_regfile == 1'b1) & (ex_mem.rd != 0) & (ex_mem.rd == id_ex.rs2) ) begin

        forwardmux2_sel = forwardmux::ex_mem_rs2_out; 

        if( ex_mem.opcode == op_lui)
            ex_mem_rs2_out = ex_mem.u_imm;

        else if( (ex_mem.opcode == op_imm) & ( (ex_mem.funct3 == slt) |  (ex_mem.funct3 == sltu) ) )
            ex_mem_rs2_out = ex_mem.br_en;

        else if( (ex_mem.opcode == op_reg) & ( (ex_mem.funct3 == slt) |  (ex_mem.funct3 == sltu) ) )
            ex_mem_rs2_out = ex_mem.br_en;

         else if( ( ex_mem.opcode == op_jal) | (ex_mem.opcode == op_jalr ) )
            ex_mem_rs2_out = ex_mem.pc_out + 4;

        else 
            ex_mem_rs2_out = ex_mem.alu_out;

    end

    /* EX_WB Hazard RS2 */
    else if( (mem_wb.word.load_regfile  == 1'b1) & (mem_wb.rd != 0) & (mem_wb.rd == id_ex.rs2) & ~( (ex_mem.word.load_regfile == 1'b1) & (ex_mem.rd != 0) & (ex_mem.rd == id_ex.rs2) ) )begin 
        forwardmux2_sel = forwardmux::mem_wb_rs2_out;

    end

    /* NO Hazard */
    else begin
        forwardmux2_sel = forwardmux::id_ex_rs2_out;

    end

end

endmodule: forward_unit