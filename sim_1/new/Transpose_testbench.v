//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/08/16 23:13:42
// Design Name: 
// Module Name: Transpose_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: verify TT compute dataflow
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "CNN_defines.vh"
`include "TT_define.vh"
`define MEM_DEPTH 6400
`define log2_DEPTH 13
module Transpose_testbench();

    reg clk;
    reg rst_n;
//    input rank_mode, ��slice of r���
    reg [`log2_DEPTH-1:0] num_of_dat;
    reg [`log_b-1:0] block_x;
    reg [`log_b-1:0] block_y;
    //block_addr = block_y * bx_max + block_x
    reg [`log_i-1:0] i_max;
    reg [`log_j-1:0] j_max;
    reg [`log_b-1:0] bx_max;
    reg [`log_b-1:0] by_max;
    reg [`log2_slice_of_r-1:0] slice_of_r;
    reg wr_vld;
    reg wr_rdy;
    wire [`log2_DEPTH-1:0]waddr1;
    wire [`log2_DEPTH-1:0] waddr2;
    wire [1:0] word_addr; //word_addr1 == word_addr2
    wire done;


MEM_transpose#
(
	6400,
	13
)mem_trans(
    clk,
    rst_n,
//    input rank_mode, ��slice of r���
    num_of_dat,
    block_x,
    block_y,
    //block_addr = block_y * bx_max + block_x
    i_max,
    j_max,
    bx_max,
    by_max,
    slice_of_r,
    wr_vld,
    wr_rdy,
    waddr1,
    waddr2,
    word_addr, //word_addr1 == word_addr2
    done
);
    
endmodule
