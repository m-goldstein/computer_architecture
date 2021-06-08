import rv32i_types::*;
`define SEXT			1'b0
`define ZEXT			1'b1
`define WZERO			32'd0
module ext_unit
#(size=32)
(
	input logic load,
        input rv32i_word sig,
	input logic[1:0] mask,
	input logic[2:0] ld_op,
	output rv32i_word out
);									 
rv32i_word garbage = 32'h00000000;
always_comb begin
        out = sig;
        if (load == 1'b1) begin
            if (ld_op == rv32i_types::lw) begin
                out = rv32i_word'(sig);
            end
            else if (ld_op == rv32i_types::lh) begin
               unique case(mask)
                    2'b00:      out = rv32i_word'({{16{sig[15]}}, sig[15:0]}); // lower half
                    2'b10:      out = rv32i_word'({{16{sig[31]}}, sig[31:16]}); // upper half
                    2'b11:      out = (`WZERO);                                   // rvfimon doesn't like this so put zeroes
                    default:      out = (`WZERO);
                endcase
            end else if (ld_op == rv32i_types::lhu) begin
               case(mask)
                    2'b00:      out = rv32i_word'({{16{1'b0}}, sig[15:0]});
                    2'b10:      out = rv32i_word'({{16{1'b0}}, sig[31:16]});
                    2'b11:      out = (`WZERO);
                    default:      out = (`WZERO);
               endcase
            end else if (ld_op == rv32i_types::lb) begin
                case (mask)
                    2'b00: out = rv32i_word'({{24{sig[7]}}, sig[7:0]});
                    2'b01: out = rv32i_word'({{24{sig[15]}}, sig[15:8]});
                    2'b10: out = rv32i_word'({{24{sig[23]}}, sig[23:16]});
                    2'b11: out = rv32i_word'({{24{sig[31]}}, sig[31:24]});
                    default: ;
                endcase
            end else if (ld_op == rv32i_types::lbu) begin
                case(mask)
                    2'b00: out = rv32i_word'({{24{1'b0}}, sig[7:0]});
                    2'b01: out = rv32i_word'({{24{1'b0}}, sig[15:8]});
                    2'b10: out = rv32i_word'({{24{1'b0}}, sig[23:16]});
                    2'b11: out = rv32i_word'({{24{1'b0}}, sig[31:24]});
                    default: ;
                endcase
            end
        end else begin
            out = garbage;
        end
end
endmodule
