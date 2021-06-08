/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */
import cache_types::*;
`define YES     1'b1
`define NO      1'b0
`define GOTO(x) next_state = (x)

module cache_control (
    input logic clk,
    input logic rst,
    input logic mem_read,
    input logic mem_write,
    input logic pmem_resp,
    input logic[1:0] sighit,
    input logic sigdirty,
    input logic siglru,
    input logic sigvalid,
    output cache_types::cache_control_if ccif
);


enum int unsigned {
    STALLED = 0,
    TAG_CHECK = 1,
    WRITEBACK = 2,
    WRITEALLOC = 3
} state, next_state;
function void set_defaults();
    ccif.datamux_sel = 1'b0;
    ccif.waymux_sel = 1'b0;
    ccif.ld_lru = `NO;
    ccif.pmem_read = `NO;
    ccif.pmem_write = `NO;
    ccif.mem_resp = `NO;
    ccif.dirty_i = 1'b0;
    ccif.sourcemux_sel = 1'b0;
    ccif.ld_data = `NO;
    ccif.cache_rd_en = `NO;
    ccif.lru_i = `NO;
    ccif.cache_wen = `NO;
    ccif.valid_rd_en = `NO;
    ccif.tagmux_sel = 2'b00;
    ccif.validmux_sel =2'b00;
    ccif.dirtymux_sel = 2'b00;
endfunction
always_ff @(posedge clk) begin
   //$display("%d: STATE: %d\nsigdirty: %x\tsigvalid: %x\tsighit %x\tsiglru: %x\tpmem_resp: %x", $time, state, sigdirty, sigvalid,sighit, siglru,pmem_resp);
   //$display("mem_read: %d\tmem_write: %d\tpmem_resp: %d", mem_read, mem_write,pmem_resp);
end
always_comb begin
   set_defaults();
   case (state)
    STALLED: begin
    end
    TAG_CHECK: begin 
            if (sighit[0] | sighit[1]) begin
                if (mem_read) begin
                    if (sighit[1] ) begin
                        //$display("%d hit on way1", $time);
                        ccif.mem_resp = `YES;
                        ccif.waymux_sel = 1'b1;
                        ccif.dirty_i = `YES;
                        ccif.ld_lru = `YES;
                        ccif.lru_i = `YES;
                    end else if (sighit[0]) begin
                        ccif.dirty_i = `YES;
                        ccif.mem_resp = `YES; 
                        ccif.waymux_sel = 1'b0;
                        ccif.ld_lru = `YES;
                        ccif.lru_i = `NO;
                    end
                end else if (mem_write) begin
                    ccif.dirty_i = `YES;
                    ccif.dirtymux_sel = (siglru) ? 2'b10 : 2'b01;
                    ccif.ld_data =`YES;
                    ccif.ld_lru = `YES;
                    ccif.mem_resp = `YES;
                    ccif.waymux_sel = 1'b0;
                end
            end else if (sighit == 2'b00) begin
                    //$display("%d no hit", $time);
                    ccif.waymux_sel = (siglru) ? 1'b1 : 1'b0;
                    if (sigdirty) begin
                       // $display("dirty");
                        ccif.sourcemux_sel = 1'b1;
                        ccif.dirty_i = `NO;
                        ccif.dirtymux_sel = (~siglru) ? 2'b01 : 2'b10;
                    end else begin
                        ccif.dirty_i = `NO;
                        ccif.validmux_sel = (~siglru) ? 2'b01 : 2'b10; 
                    end
            end
    end
    WRITEBACK: begin
        //$display("%d: IN WRITEBACK!\n", $time);
        ccif.waymux_sel = siglru;
        ccif.sourcemux_sel = 1'b1;
        ccif.pmem_write = (`YES);
    end
    WRITEALLOC: begin
        //$display("%d: In write alloc!\n", $time);    
        ccif.pmem_read = `YES;
        ccif.datamux_sel = 1'b1;
        ccif.waymux_sel = (siglru)  ? 1'b1 : 1'b0;
        if (pmem_resp) begin
            ccif.tagmux_sel = (siglru) ? 2'b10 : 2'b01; 
            ccif.ld_data = `YES;
         end
    end
   default ;
   endcase
end
always_comb begin
    //`GOTO((rst) ? STALLED: state);
        case(state)
            STALLED: `GOTO ((mem_read | mem_write) ? TAG_CHECK : STALLED);
            TAG_CHECK: begin
                if  (sighit == 2'b00) `GOTO( (~sigdirty) ? WRITEALLOC: WRITEBACK);
                else `GOTO(STALLED);
            end
            WRITEBACK:  `GOTO((pmem_resp) ? WRITEALLOC : WRITEBACK);
            WRITEALLOC: `GOTO((pmem_resp) ? STALLED : WRITEALLOC);
            default: `GOTO(STALLED);
        endcase
end

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        state <= STALLED;
    else
        state <= next_state;
end
endmodule : cache_control

