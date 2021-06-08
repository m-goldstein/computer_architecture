import cache_types::*;
`define CPU_ADDR_MASK     32'hFFFFFFE0
module addr_translation_unit(
    input logic[31:0] mem_address,
    input sourcemux::sourcemux_sel_t sourcemux_sel,
    input logic[23:0] tag,
    input logic[2:0] index,
    input  logic[4:0] offset,
    output logic[31:0] mem_address_out
);
always_comb begin
    mem_address_out = 32'({mem_address & (`CPU_ADDR_MASK)});
    unique case (sourcemux_sel)
        sourcemux::memory:  mem_address_out = 32'({mem_address & (`CPU_ADDR_MASK)});
        sourcemux::cache:   mem_address_out = 32'({tag, index, 5'd0});
        default: mem_address_out = 32'({mem_address & (`CPU_ADDR_MASK)});
    endcase
end
endmodule
