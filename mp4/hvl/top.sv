import ctrl_word::*;
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf   (itf),
    .mem_itf         (itf),
    .sm_itf          (itf),
    .tb_itf          (itf),
    .rvfi            (rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

// timeunit 1ns;
// timeprecision 1ns;

assign rvfi.commit = (dut.cpu.DATAPATH.mem_wb_reg.word.load_regfile 
                    & ~dut.cpu.DATAPATH.busy) & (dut.cpu.DATAPATH.mem_wb_reg.opcode !=0); // Set high when a valid instruction is modifying regfile or PC
//assign rvfi.halt =  (dut.cpu.DATAPATH.if_id_reg.pc_out == dut.cpu.DATAPATH.mem_wb_reg.pc_out) & ( (dut.cpu.DATAPATH.mem_wb_reg.pc_out !=  0) & (dut.cpu.DATAPATH.if_id_reg.pc_out != 0) );
//( (dut.cpu.DATAPATH.PC.out == dut.cpu.DATAPATH.id_ex_reg.pc_out) ) ? 1 : 0; // && (dut.cpu.DATAPATH.mem_wb_reg.opcode == 7'b1100011) && 
       // (dut.cpu.DATAPATH.mem_wb_reg.br_en == 1) ) ? 1 : 0; 
//assign rvfi.halt =  (dut.cpu.DATAPATH.if_id_reg.pc_out == dut.cpu.DATAPATH.mem_wb_reg.pc_out) & ( (dut.cpu.DATAPATH.mem_wb_reg.pc_out !=  0) & (dut.cpu.DATAPATH.if_id_reg.pc_out != 0) );
assign rvfi.halt = (dut.cpu.DATAPATH.mem_wb_reg.pc_out == dut.cpu.DATAPATH.mem_wb_reg.alu_out) & ( (dut.cpu.DATAPATH.mem_wb_reg.pc_out !=  0) & (dut.cpu.DATAPATH.mem_wb_reg.alu_out != 0) )
                    & (dut.cpu.DATAPATH.mem_wb_reg.opcode == 7'b1101111);
// Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap
*/
//assign rvfi.inst = ;
//assign rvfi.trap = ctrl_word.trap;
/*
Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata
*/

assign rvfi.mem_addr= dut.cpu.DATAPATH.mem_wb_reg.datacache_address;
assign rvfi.mem_rmask= dut.cpu.DATAPATH.ctrl_word.rmask;
assign rvfi.mem_wmask= dut.cpu.DATAPATH.ctrl_word.wmask;
assign rvfi.mem_rdata= dut.cpu.DATAPATH.mem_wb_reg.datacache_rdata;
assign rvfi.mem_wdata= dut.cpu.DATAPATH.mem_wb_reg.rs2_out;

assign rvfi.inst = dut.cpu.DATAPATH.mem_wb_reg.inst_cache_rdata;
assign rvfi.trap = 0;//dut.cpu.DATAPATH.ctrl_word.trap;

assign rvfi.pc_rdata = dut.cpu.DATAPATH.mem_wb_reg.pc_out;
assign rvfi.pc_wdata = dut.cpu.DATAPATH.mem_wb_reg.pcmux_out; 

assign rvfi.rs1_addr = dut.cpu.DATAPATH.mem_wb_reg.rs1;
assign rvfi.rs2_addr = dut.cpu.DATAPATH.mem_wb_reg.rs2;
assign rvfi.load_regfile = dut.cpu.DATAPATH.mem_wb_reg.word.load_regfile;

assign rvfi.rs1_rdata = dut.cpu.DATAPATH.mem_wb_reg.rs1_out;
assign rvfi.rs2_rdata = dut.cpu.DATAPATH.mem_wb_reg.rs2_out;

assign rvfi.rd_addr = dut.cpu.DATAPATH.mem_wb_reg.rd; 
assign rvfi.rd_wdata = (dut.cpu.DATAPATH.mem_wb_reg.rd == 0) ? 0 : dut.cpu.DATAPATH.regfilemux_out; 

/*
Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.cpu.DATAPATH.regfile.data;// {default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/
//always_ff @(posedge itf.clk) begin
//    itf.inst_resp <= dut.cpu.inst_resp;//dut.cpu.inst_resp;
//    itf.data_resp <= dut.cpu.data_resp;//dut.cpu.data_resp;
//    itf.inst_rdata <= dut.cpu.inst_rdata;//dut.cpu.DATAPATH.inst_cache_rdata;//inst_rdata;//cpu.inst_rdata;
//    itf.data_rdata <= dut.cpu.data_rdata;//dut.cpu.DATAPATH.datacache_rdata;//cpu.data_rdata;
//end
assign itf.inst_resp = dut.cpu.inst_resp;
assign itf.data_resp = dut.cpu.data_resp;
assign itf.inst_rdata = dut.cpu.DATAPATH.inst_cache_rdata;
assign itf.data_rdata =dut.cpu.DATAPATH.datacache_rdata;//cpu.data_rdata;
assign itf.inst_read = dut.cpu.inst_read;
assign itf.data_read = dut.cpu.data_read;
assign itf.data_write =dut.cpu.data_write;
assign itf.data_mbe =  dut.cpu.data_mbe;
assign itf.inst_addr = dut.cpu.inst_addr;
assign itf.data_addr = dut.cpu.data_addr;
assign itf.data_wdata = dut.cpu.data_wdata;
    
mp4 dut(
    .clk          (itf.clk),
    .rst          (itf.rst),

    .mem_wdata	  (itf.mem_wdata),
    .mem_rdata	  (itf.mem_rdata),
    .mem_read	  (itf.mem_read),
    .mem_write	  (itf.mem_write),
    .mem_addr	  (itf.mem_addr),
    .mem_resp	  (itf.mem_resp)

    // .inst_resp    (itf.inst_resp),
    // .data_resp    (itf.data_resp),
    // .inst_rdata   (itf.inst_rdata),
    // .data_rdata   (itf.data_rdata),
    
    // .inst_read    (itf.inst_read),
    // .data_read    (itf.data_read),
    // .data_write   (itf.data_write),
    // .data_mbe     (itf.data_mbe),
    // .inst_addr    (itf.inst_addr),
    // .data_addr    (itf.data_addr),
    // .data_wdata   (itf.data_wdata),
    
    //.instr_cache_read(itf.inst_read) //
);


/***************************** End Instantiation *****************************/

endmodule

