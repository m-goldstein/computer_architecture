/* A register array to be used for tag arrays, LRU array, etc. ie A set of registers*/

/* Description of Signals */
/* 
    read: request to read from a set
    load: request to load/write value in set
    rindex: set index to read from
    windex: set index you want to write to
    datain: The value you want to write into a set specified by windex
    dataout: The value you read from a set specified by rindex
*/


module mike_array #(
    parameter s_index = 3,
    parameter width = 1
)
(
    clk,
    rst,
    read,
    load,
    rindex,
    windex,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input read;
input load;
input [s_index-1:0] rindex;          // set you wanna read from
input [s_index-1:0] windex;          // set you wanna write to
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;
logic [width-1:0] _dataout;
//assign dataout = _dataout;

/*Initialize to zero */
initial begin
    data[0] = 0;
  data[1] = 0;
  data[2] = 0;
  data[3] = 0;
  data[4] = 0;
  data[5] = 0;
  data[6] = 0;
  data[7] = 0;
    // for (int i = 0; i < num_sets; ++i)
    //          data[i] = '0;
end

always_comb begin
    dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

/* Data from cache will be available to read next clock cycle */
always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end


// always_ff @(posedge clk)
// begin
//     if (rst) begin
//         for (int i = 0; i < num_sets; ++i)
//             data[i] <= '0;
//     end
//     else begin
//         if (read)
//             _dataout <= (load  & (rindex == windex)) ? datain : data[rindex];

//         if(load)
//             data[windex] <= datain;
//     end
// end

endmodule : mike_array
