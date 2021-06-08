`define FULL_LINE   32'hFFFFFFFF
`define EMPTY_LINE  32'h00000000
module dataline_selector (
    input waymux::waymux_sel_t sel,
    input logic ld,
    input datamux::datamux_sel_t src,
    input logic[31:0] mbe256,
    output logic[31:0] dout0,
    output logic[31:0] dout1
);
always_comb
    begin
        dout0 = (`EMPTY_LINE);
        dout1 = (`EMPTY_LINE);
        if (sel == waymux::way0) begin
            if (ld) dout0 = (src == datamux::cache) ? (`FULL_LINE) : mbe256;
            else    dout0 = (`EMPTY_LINE);
        end else if (sel == waymux::way1) begin
            if (ld) dout1 = (src == datamux::cache) ? (`FULL_LINE) : mbe256;
            else    dout1 = (`EMPTY_LINE);
        end
    end
endmodule
