import ctrl_word::*;
import rv32i_types::*;
module control_rom
(
    input rv32i_types::rv32i_opcode opcode, 
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    output ctrl_word::ctrl_word_t ctrl_word
);

rv32i_types::branch_funct3_t branch_funct3;
rv32i_types::store_funct3_t store_funct3;
rv32i_types::load_funct3_t load_funct3;
rv32i_types::arith_funct3_t arith_funct3;

assign branch_funct3 = rv32i_types::branch_funct3_t'(funct3);
assign arith_funct3 = rv32i_types::arith_funct3_t'(funct3);
assign load_funct3 = rv32i_types::load_funct3_t'(funct3);
assign store_funct3 = rv32i_types::store_funct3_t'(funct3);

function void loadPC();
    ctrl_word.load_pc = 1'b1;
    //ctrl_word.pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl_word.regfilemux_sel = sel;
    ctrl_word.load_regfile = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop=1'b0, rv32i_types::alu_ops op);

    //if (setop == 1'b1)
    ctrl_word.aluop = op;
    ctrl_word.alumux1_sel = sel1;
    ctrl_word.alumux2_sel = sel2;

endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, rv32i_types::branch_funct3_t op);
    ctrl_word.cmpmux_sel = sel;
    case (op)
        rv32i_types::beq, rv32i_types::bne, rv32i_types::blt, rv32i_types::bltu, rv32i_types::bge, rv32i_types::bgeu: ctrl_word.cmpop = op;
        default: ctrl_word.cmpop = beq;
    endcase
endfunction

function void set_defaults();
    /* PC signals */
    ctrl_word.load_pc = 1'b0;
    ctrl_word.pcmux_sel = pcmux::pc_plus4;
    
    /* Regfile signals */
    ctrl_word.load_regfile = 1'b0;
    ctrl_word.regfilemux_sel = regfilemux::alu_out;

    /* CMP signals */
    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
    ctrl_word.cmpop = rv32i_types::beq;
    
    /* ALU signals */
    ctrl_word.alumux1_sel = alumux::rs1_out;
    ctrl_word.alumux2_sel = alumux::i_imm;
    ctrl_word.aluop       = alu_ops'(alu_add); //rv32i_types::alu_ops'(funct3);
    /* misc (implemented) */
    ctrl_word.opcode = opcode; 
    //ctrl_word.mem_byte_enable  = 4'b1111;
    ctrl_word.datacache_mem_read         = 1'b0;
    ctrl_word.datacache_mem_write        = 1'b0;
    ctrl_word.instcache_mem_read        = 1'b0;
    
endfunction
/* mem_byte_enable logic logic */
 always_comb begin
     //ctrl_word.rmask = 4'b0000;
     //ctrl_word.wmask = 4'b0000;
     //ctrl_word.trap  = 1'b0; // is this needed here?
     case (opcode)
        rv32i_types::op_store: begin
        //      case (store_funct3)
        //          rv32i_types::sb:      ctrl_word.wmask = (4'b0001); // << mem_address[1:0]; ??
        //          rv32i_types::sh:      ctrl_word.wmas   1023c:	00000063          	beqz	x0,1023c <HALT>/
                         //0  4'b0011); // << mem_address[1:0]; ??
        //          rv32i_types::sw:      ctrl_word.wmask = (4'b1111);
        //          default: ctrl_word.wmask = (4'b1111);
        //      endcase
         end
        rv32i_types::op_load: begin
            // case (load_funct3)
            //     rv32i_types::lb:      ctrl_word.rmask = (4'b0001); // << mem_address[1:0]; ?
            //     rv32i_types::lbu:     ctrl_word.rmask = (4'b0001); // << mem_address[1:0]; ?
            //     rv32i_types::lh:      ctrl_word.rmask = (4'b0011); // << mem_address[1:0]; ?
            //     rv32i_types::lhu:     ctrl_word.rmask = (4'b0011); // << mem_address[1:0]; ?
            //     rv32i_types::lw:      ctrl_word.rmask = (4'b1111);
            //     default: ctrl_word.rmask = (4'b1111); 
            // endcase
        end
        
        rv32i_types::op_br: begin
            case (branch_funct3)
                rv32i_types::beq:  ;
                rv32i_types::bne:  ;
                rv32i_types::blt:  ;
                rv32i_types::bltu: ;
                rv32i_types::bge:  ;
                rv32i_types::bgeu: ;
                default: ctrl_word.trap = 1'b1; // throw a trap error?
            endcase
        end
        rv32i_types::op_imm:   ;
        rv32i_types::op_reg:   ;
        rv32i_types::op_auipc: ;
        rv32i_types::op_lui:   ;
        rv32i_types::op_jal:   ;
        rv32i_types::op_jalr:  ;
        default: ctrl_word.trap = 1'b1;// throw a trap error?
    endcase
end

/* OPCODE STAGE LOGIC */
always_comb begin
    set_defaults();
    unique case (opcode)
        /* CHECKED  ,rd <== (u_imm << 12) */
        rv32i_types::op_lui: begin
            ctrl_word.instcache_mem_read = 1'b1;
            loadPC();
            setALU(alumux::rs1_out, alumux::u_imm, 1, alu_add);
            loadRegfile(regfilemux::u_imm);
        end
        
        // rd <== (u_imm << 12) + PC
        rv32i_types::op_auipc: begin
            loadPC();
            loadRegfile(regfilemux::alu_out);
            setALU(alumux::pc_out, alumux::u_imm, 1, alu_add);
        end
        
        // jump-and-link (J-type)
        // pc+4 (instuction following jump) written to rd
        rv32i_types::op_jal: begin
            loadPC();
            ctrl_word.instcache_mem_read = 1'b1;
            setALU(alumux::pc_out, alumux::j_imm, 1, alu_add);
            loadRegfile(regfilemux::pc_plus4);
        end
        
        // jump-and-link-register (I-type)
        // pc+4 (instuction following jump) written to rd
        rv32i_types::op_jalr: begin
            loadPC();
            ctrl_word.instcache_mem_read = 1'b1;
            setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add);
            loadRegfile(regfilemux::pc_plus4);
        end
        
        // pcmux_sel set to br_en
        // aluop set to alu_add
        // need to set cmpop to evaluate branching condition
        rv32i_types::op_br: begin
            ctrl_word.instcache_mem_read = 1'b1;
            loadPC(); 
            //loadPC(pcmux::alu_out); // need logic in alumux for whether or not branch is taken..
            setALU(alumux::pc_out, alumux::b_imm, 0, alu_add);
            setCMP(cmpmux::rs2_out, rv32i_types::branch_funct3_t'(funct3));
        end
        
        rv32i_types::op_load: begin

            //ctrl_word.instcache_mem_read = 1'b1;
            loadPC();
            setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add);
            ctrl_word.datacache_mem_read = 1'b1;
            case (load_funct3)
                lb:      loadRegfile(regfilemux::lb);
                lbu:     loadRegfile(regfilemux::lbu);
                lh:      loadRegfile(regfilemux::lh);
                lhu:     loadRegfile(regfilemux::lhu);
                default: loadRegfile(regfilemux::lw);
            endcase 
        end
        
        rv32i_types::op_store: begin    

            /* not implemented but maybe needed 
             *  CALC_ADDRESS:
             *      setALU(alumux::rs1_out, alumux::i_imm, 1, alu_add);
             *      datapath.load_data_out = 1'b1; load data out register in datapath
             *      loadMAR(marmux::alu_out);
             *  STR_STEP1 (definitely needed and implemented below):
             *  STR_STEP2: // for after mem_resp received
             *      loadPC(pcmux::pc_plus4);
             */
            loadPC();
            setALU(alumux::rs1_out, alumux::s_imm, 1, alu_add);
            ctrl_word.datacache_mem_write = 1'b1;
             //ctrl_word.datacache_mem_read = 1'b0;
    
             // this is being done in datapath
             /* Neither ctrl_word.mem_byte_enable or mem_address are valid signals right now...
             ctrl_word.mem_write = 1'b0; // not a valid signal ... 
             case (store_funct3)
                sb:      ctrl_word.mem_byte_enable = (4'b0001 << mem_address[1:0]);
                
                sh:      ctrl_word.mem_byte_enable = (4'b0011 << mem_address[1:0]);
                
                sw:      ctrl_word.mem_byte_enable = 4'b1111;
                
                default: ctrl_word.mem_byte_enable = 4'b1111;
             endcase
             */
        end
        
        rv32i_types::op_reg: begin
            ctrl_word.instcache_mem_read = 1'b1;
            loadRegfile(regfilemux::alu_out);
            loadPC();
            setALU(alumux::rs1_out, alumux::rs2_out, 1, rv32i_types::alu_ops'(funct3));
            case (rv32i_types::arith_funct3_t'(funct3))
                // rd <== rs1 << rs2
                sll:    ctrl_word.aluop = alu_sll;
                
                // rd <== rs1 ^ rs2
                axor:   ctrl_word.aluop = alu_xor;
                
                // rd <== rs1 | rs2
                aor:    ctrl_word.aluop = alu_or;
                
                // rd <== rs1 & rs2
                aand:   ctrl_word.aluop = alu_and;
                
                // rd <== rs1 >> rs2
                sr:     ctrl_word.aluop = (funct7 == 7'b0100000) ? alu_sra : alu_srl;

                //rd <== rs1 + rs2
                add:    ctrl_word.aluop = (funct7 == 7'b0100000) ? alu_sub : alu_add;

                // rd <== (rs1 < rs2) ? 1 : 0
                slt: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out, blt);
                end
                
                // rd <== (unsigned'(rs1) < unsigned'(rs2)) ? 1 : 0
                sltu: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out, bltu);
                end
                
                // otherwise cast to alu_ops type using bits of funct3
                default:    ctrl_word.aluop = rv32i_types::alu_ops'(funct3);        
            endcase
            end
            
        rv32i_types::op_imm: begin
            ctrl_word.instcache_mem_read = 1'b1;
            loadPC();
            loadRegfile(regfilemux::alu_out);
            ctrl_word.aluop = rv32i_types::alu_ops'(funct3);
            case (arith_funct3)
                // rd <== rs1 >> rs2 
                // OR (depending on funct7) 
                // rd <== rs1 << rs2
                sr: ctrl_word.aluop = (funct7 == 7'b0100000) ? alu_sra : alu_srl;
                
                // rd <== (rs1 < i_imm ) ? 1 : 0 
                slt: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, blt);
                end

                // rd <== (unsigned'(rs1) < unsigned'(i_imm)) ? 1 : 0
                sltu: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, bltu);
                end
                
                // covers addi,xori,ori,andi,slli cases...
                default: begin
                    ctrl_word.aluop = rv32i_types::alu_ops'(funct3);
                end
            endcase
        end
        
        rv32i_types::op_csr: begin
        end
        // bad instuction or data
        default: begin
            ctrl_word.datacache_mem_write = 1'b0;
            ctrl_word.datacache_mem_read = 1'b0; 
            
        end
    endcase
end

endmodule
