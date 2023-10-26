`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/09/03 12:24:07
// Design Name: 
// Module Name: MEM_IN_OUT_transpose
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//	parameter num_block=256,
//	parameter log2_num_block=8
//compute the write addr for ping pong buffers
`include "CNN_defines.vh"
`include "TT_define.vh"
module MEM_transpose#
(
	parameter MEM_DEPTH=16,
	parameter log2_DEPTH=4
)(
    input clk,
    input rst_n,
//    input rank_mode, ��slice of r���
    input [log2_DEPTH-1:0] num_of_dat,
    input [`log_b-1:0] block_x,
    input [`log_b-1:0] block_y,
    //block_addr = block_y * bx_max + block_x
    input [`log_i-1:0] i_max,
    input [`log_j-1:0] j_max,
    input [`log_b-1:0] bx_max,
    input [`log_b-1:0] by_max,
    input [`log2_slice_of_r-1:0] slice_of_r,
    input wr_vld,
    input wr_rdy,
    output wire [log2_DEPTH-1:0]waddr1,
    output wire [log2_DEPTH-1:0] waddr2,
    output wire [1:0] word_addr, //word_addr1 == word_addr2
    output reg done
);

reg [log2_DEPTH-1:0]cnt;
wire[`log_j-1:0] j_f; //first word
wire[`log_j-1:0] j_s; //second word
wire[`log_i-1:0] i;
assign j_f = slice_of_r*(cnt/i_max);
assign j_s = slice_of_r*(cnt/i_max) + 1;
assign i = cnt%i_max;
assign waddr1 =j_f*by_max*(i_max/slice_of_r)*bx_max 
               +  block_y*(i_max/slice_of_r)*bx_max 
               +     (i/slice_of_r)*bx_max + block_x;
assign waddr2 =j_s*by_max*(i_max/slice_of_r)*bx_max 
               +  block_y*(i_max/slice_of_r)*bx_max
               +     (i/slice_of_r)*bx_max + block_x;
assign word_addr = i%slice_of_r;

reg working;
wire cnt_is_max_now=(cnt==num_of_dat);
wire cnt_will_update_now = working & wr_vld & wr_rdy;
wire cnt_done;
wire start;
assign start = wr_vld&wr_rdy;
 

always @(posedge clk or negedge rst_n)
if(~rst_n)
	working<=1'b0;
else
	if(start)
		working<=1'b1;
	else
		if(cnt_done)
			working<=1'b0;


always @(posedge clk or negedge rst_n)
if(~rst_n)
    cnt<='d0;
else
    if(cnt_will_update_now)
    begin
        if(cnt_is_max_now)
            cnt<='d0;
        else
            cnt<=cnt+'d1;
    end

assign cnt_done=cnt_is_max_now&cnt_will_update_now;

always @(posedge clk or negedge rst_n)
if(~rst_n)
	done<=0;
else
    done<=cnt_done;

endmodule
