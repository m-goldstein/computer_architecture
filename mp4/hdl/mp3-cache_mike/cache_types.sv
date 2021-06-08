
package mike_cache_types;

typedef enum bit [1:0] {
    byte_enable = 2'b00,
    f_enable    = 2'b01,
    zero_enable = 2'b10
} bytemux_sel_t;

typedef enum bit {
    pmem_data = 1'b0,
    cpu_data  = 1'b1
} datamuxin_sel_t;

typedef enum bit {
    dataout_way0 = 1'b0,
    dataout_way1  = 1'b1
} datamuxout_sel_t;

typedef enum bit [1:0]{
    cpu = 2'b00,
    cache_way0  = 2'b01,
    cache_way1  = 2'b10
} addressmuxout_sel_t;


endpackage : mike_cache_types