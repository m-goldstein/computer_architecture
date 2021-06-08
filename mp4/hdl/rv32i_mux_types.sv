package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b10
    ,alu_mod2 = 2'b11
} pcmux_sel_t;
endpackage

package branchmux;
typedef enum bit {
    pc_plus4   = 1'b0
    ,pcmux_out = 1'b1
}static_branch_sel_t;
endpackage

package nopmux;
typedef enum bit {
    inst_rdata   = 1'b0
    ,nop         = 1'b1
}nop_rdata_sel_t;

typedef enum bit {
    if_id        = 1'b0
    ,if_id_nop   = 1'b1
}nop_if_id_sel_t;

typedef enum bit {
    id_ex        = 1'b0
    ,id_ex_nop   = 1'b1
}nop_id_ex_sel_t;

endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

/* 
   Purpose: used for selecting forwarding data in the Execute stage 
   forwardmux1_sel_t: struct selects from which stage rs1_out should be used in Execute
   forwardmux2_sel_t: struct selects from which stage rs2_out should be used in Execute
*/
package forwardmux;
typedef enum bit [1:0]{
    id_ex_rs1_out   = 2'b00
    ,ex_mem_rs1_out = 2'b01
    ,mem_wb_rs1_out = 2'b10
}forwardmux1_sel_t;

typedef enum bit [1:0]{
    id_ex_rs2_out   = 2'b00
    ,ex_mem_rs2_out = 2'b01
    ,mem_wb_rs2_out = 2'b10
}forwardmux2_sel_t;

typedef enum bit {
    rs2_out         = 1'b0
    ,regfilemux_out = 1'b1
}forwardmux_mem_sel_t;

typedef enum bit {
    ctrl_word        = 1'b0
    ,nop             = 1'b1
}id_ex_mux_sel_t;

endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011   // WHAT IS THIS? FROM MDR? => THIS IS THE LW INSTRUCTION
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101  // signed byte
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111  // signed halfword
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage