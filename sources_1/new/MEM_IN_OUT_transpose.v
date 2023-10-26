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
`include "CNN_defines.vh"
`include "TT_define.vh"
//compute the write addr for ping pong buffers
module MEM_IN_OUT_transpose#
(
	parameter DAT_WIDTH=16,
	parameter MEM_DEPTH=16,
	parameter log2_DEPTH=4
)(
    input clk,
    input rst_n,
    input wr_vld,
    input wr_rdy,
    input rank_mode,
    input [log2_DEPTH-1:0] num_of_dat,
//    input [`log2_slice_of_r-1:0] slice_of_r,
    output [log2_DEPTH-1:0]waddr,
    output reg [1:0]word_addr,
    output reg done
);

reg [log2_DEPTH-1:0]cnt;
reg working;
wire cnt_is_max_now=(cnt==num_of_dat);
wire cnt_will_update_now=working;
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
