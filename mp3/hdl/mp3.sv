import rv32i_types::*;
import cache_types::*;
module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp3 module to `cpu`
//cpu cpu(.*);

/* signals between CPU datapath and Cache */
cache_if cif(.clk(clk),
             .rst(rst)
            );
cpu cpu(
    .clk(clk),
    .rst(rst),
    .mem_resp(cif.mem_resp),
    .mem_rdata(cif.mem_rdata),
    .mem_read(cif.mem_read),
    .mem_write(cif.mem_write),
    .mem_byte_enable(cif.mem_byte_enable),
    .mem_address(cif.mem_address),
    .mem_wdata(cif.mem_wdata),
    .mem_addr(cif.mem_addr)
);
// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk(clk),
    .rst(rst),
    .mem_address(cif.mem_addr),
    .mem_wdata(cif.mem_wdata),
    .mem_byte_enable(cif.mem_byte_enable),
    .pmem_rdata(cif.pmem_rdata),
    .pmem_resp(cif.pmem_resp),
    .mem_read(cif.mem_read),
    .mem_write(cif.mem_write),
    .mem_rdata(cif.mem_rdata),
    .pmem_wdata(cif.pmem_wdata),
    .mem_resp(cif.mem_resp),
    .pmem_read(cif.pmem_read),
    .pmem_write(cif.pmem_write),
    .pmem_address(cif.pmem_address)
);


// From MP1
cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),
    .line_i(cif.pmem_wdata),
    .line_o(cif.pmem_rdata),
    .address_i(cif.pmem_address),
    .read_i(cif.pmem_read),
    .write_i(cif.pmem_write),
    .resp_o(cif.pmem_resp),
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3
