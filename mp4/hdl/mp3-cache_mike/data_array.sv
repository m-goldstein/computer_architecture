/* A special register array specifically for your
data arrays. This module supports a write mask to
help you update the values in the array. */

/* Description of Signals */
/* 
    read: request to read from a set
    write_en: Specifies which byte you want to write into dataout
    rindex: set index to read from in array
    windex: set index you want to write to in array
    datain: The value you want to write into a set specified by windex
    dataout: The value you read from a set specified by rindex
*/

module mike_data_array #(
    parameter s_offset = 5,
    parameter s_index = 3
)
(
    clk,
    rst,
    read,
    write_en,
    rindex,
    windex,
    datain,
    dataout
);

localparam s_mask   = 2**s_offset;  // 2^5 = 32 bits
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

input clk;
input rst;
input read;
input [s_mask-1:0] write_en;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [s_line-1:0] datain;
output logic [s_line-1:0] dataout;

logic [s_line-1:0] data [num_sets-1:0] = '{default: '0}; 
logic [s_line-1:0] _dataout;
// assign dataout = _dataout;

// always_ff @(posedge clk)
// begin
//     if (rst) begin
//         for (int i = 0; i < num_sets; ++i)
//             data[i] <= '0;
//     end
//   end

always_comb begin
    //if(read) begin
        for (int i = 0; i < s_mask; i++) begin
            dataout[8*i +: 8] = (write_en[i] & (rindex == windex)) ? datain[8*i +: 8] : data[rindex][8*i +: 8];
        end
    //end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < s_mask; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
end

// always_ff @(posedge clk)
// begin
//     if (rst) begin
//         for (int i = 0; i < num_sets; ++i)
//             data[i] <= '0;
//     end
//     else begin
//         if (read)
//             /* Loop 32 times, if write_en[i] & (rindex == windex) */
//             /* then, load datain[8*i +: 8] into _dataout[8*i +: 8] */
//             /* else, load data[rindex][8*i +: 8] into _dataout[8*i +: 8] */
//             /* _dataout[ 8*i +: 8] // == _dataout[ 8*i + 8 : 8*i], 
//             /* x +: N, The start position of the vector is given by x and you count up from x by N. */
//             for (int i = 0; i < s_mask; i++)
//                 _dataout[8*i +: 8] <= (write_en[i] & (rindex == windex)) ?
//                                       datain[8*i +: 8] : data[rindex][8*i +: 8];

//         for (int i = 0; i < s_mask; i++)
//             begin
//                 data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] :
//                                                         data[windex][8*i +: 8];
//             end
//     end
// end

endmodule : mike_data_array
