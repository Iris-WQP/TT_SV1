`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/09/03 15:13:30
// Design Name: 
// Module Name: trans_pingpong
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
module trans_pingpong#
(
	parameter DAT_WIDTH=16,
	parameter MEM_DEPTH=16,
	parameter log2_MEM_DEPTH=4
)
(
	input clk,
    input rst_n,
    
	input wr_vld,  //start
	input [log2_MEM_DEPTH-1:0]waddr,
	input [DAT_WIDTH-1:0]wdata,
	input [log2_MEM_DEPTH:0]waddr_max,
	input rank_mode, //0--r=8; 1--r=4�����rank�̶�������ź���Ч
	input [1:0]word_addr, //��rank=8ʱ����λû���ã������Ż���
	output wr_rdy,
	
	input rd_vld,
	output rd_rdy,
	input [log2_MEM_DEPTH-1:0]raddr,
	output reg [DAT_WIDTH-1:0]rdata,
	input [log2_MEM_DEPTH+2:0]raddr_max,
	output reg rd_dat_out_vld
);

reg [DAT_WIDTH-1:0]mem[MEM_DEPTH-1:0];

reg wr_mode;
wire rd_mode=!wr_mode;
reg [log2_MEM_DEPTH+2:0]raddr_cnt;
wire rd_last=((raddr_cnt==raddr_max-1))&(rd_vld&rd_rdy);

always @(posedge clk or negedge rst_n)
if(~rst_n)
    wr_mode<=1;
else
	if(rd_last)
		wr_mode<=1;
    else
		if((waddr==waddr_max-1)&(wr_vld&wr_rdy))
			wr_mode<=0;


always @(posedge clk or negedge rst_n)
if(~rst_n)
    raddr_cnt<=0;
else
begin
    if(wr_mode)
        raddr_cnt<=0;
    else
        if(rd_vld&rd_rdy)
            raddr_cnt<=raddr_cnt+1;
end

assign rd_rdy=rd_mode;
assign wr_rdy=wr_mode;


always @(posedge clk or negedge rst_n)
if(~rst_n)
    mem[waddr]<='b0;
else
    if(wr_mode&wr_vld&wr_rdy)
	   mem[waddr]<=wdata;

always @(posedge clk or negedge rst_n)
if(~rst_n)
    rdata<='b0;
else
    if(rd_mode&rd_vld&rd_rdy)
    begin
        rdata<=mem[raddr[log2_MEM_DEPTH-1:0]];
    end
           
wire tp_rd_dat_out_vld=rd_mode&rd_vld&rd_rdy;  

always @(posedge clk or negedge rst_n)
if(~rst_n)
    rd_dat_out_vld<='b0;
else
    rd_dat_out_vld<=tp_rd_dat_out_vld;
              
endmodule

