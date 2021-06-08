import rv32i_types::*;
`define PAD_LEFT		1'b1
`define PAD_RIGHT		1'b0
`define WZERO                   32'd0
module padding_unit
#(mode=`PAD_RIGHT)
(
        input logic load,
	input rv32i_word sig,
	input logic[1:0] mask,
        input logic[2:0] op,
	output rv32i_word out
);
    always_comb begin
        out =`WZERO;
        if (load == 1'b1) begin
            if (mode==`PAD_RIGHT) begin
                if (op == rv32i_types::sb) begin
                    unique case(mask)               // want to apply padding at byte granularity
                        2'b00: out = 32'({sig[31:0]});
                        2'b01: out = 32'({sig[23:0], 8'h00});
                        2'b10: out = 32'({sig[15:0], 16'h0000});
                        2'b11: out = 32'({sig[7:0],  24'h000000});
                        default: out = sig;
                    endcase
                end else if (op == rv32i_types::sh) begin
                    unique case(mask)
                        2'b00: out = 32'({sig[31:0]});
                        2'b01: out = 32'({sig[23:0], 8'h00});
                        2'b10: out = 32'({sig[15:0], 16'h0000});
                        2'b11: out = 32'({sig[7:0],  24'h000000});
                    endcase
                end else if (op == rv32i_types::sw) begin
                    out = rv32i_word'(sig);
                end
            end else if (mode == `PAD_LEFT) begin
                if (op == rv32i_types::sb) begin
                    unique case(mask)
                        2'b00: out = 32'({sig[31:0]});
                        2'b01: out = 32'({8'h00, sig[23:0]});
                        2'b10: out = 32'({16'h0000, sig[15:0]});
                        2'b11: out = 32'({24'h000000, sig[7:0]});
                        default: out = sig;
                    endcase
                end else if (op == rv32i_types::sh) begin
                    unique case(mask)
                        2'b00: out = 32'({sig[31:0]});
                        2'b01: out = 32'({8'h00, sig[23:0]});
                        2'b10: out = 32'({16'h0000, sig[15:0]});
                        2'b11: out = 32'({24'h000000, sig[7:0]});
                        default: out = sig;
                    endcase
                end else if (op == rv32i_types::sw) begin
                    out = rv32i_word'(sig);
                end
            end
        end else begin
            out = `WZERO;
        end
    end
endmodule
