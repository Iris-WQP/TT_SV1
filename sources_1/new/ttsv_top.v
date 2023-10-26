`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/10/08 18:40:20
// Design Name: 
// Module Name: ttsv_top
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
`define trans_DEPTH 16
`define trans_log2_DEPTH 4

module ttsv_top#
(
    parameter M_AXI_ID_WIDTH = 4,// 4, Datawith= Feature; for Input image or bias or resadder
    parameter M_AXI_DATA_WIDTH = `Tout*`DW // Width of Data Bus
)                               // 16*8 = 128
(
    input clk,
	input rst_n,
    //Master AXI write addr  д����
    output [M_AXI_ID_WIDTH-1 : 0]M_AXI_AWID,//д��ַID���ڱ�ʶд��ַ��
    output [32-1 : 0]M_AXI_AWADDR,// Master Interface Write Address
    output [7 : 0]M_AXI_AWLEN, // Burst length�����ֵ256��Ŀǰ16
    output [2 : 0]M_AXI_AWSIZE,//Burst type.((M_AXI_DATA_WIDTH/8)-1);
    output [1 : 0]M_AXI_AWBURST,//��������type =2'b01;
    output  M_AXI_AWLOCK,//Lock type.1'b0;
    output [3 : 0]M_AXI_AWCACHE,//// Memory type.=4'b10
    output [2 : 0]M_AXI_AWPROT,//=3'h0;    // the transaction is a data access
    output [3 : 0]M_AXI_AWQOS,//=4'h0;// Quality of Service
    output M_AXI_AWVALID, //signaling valid write address
    input M_AXI_AWREADY,  // Write address ready.
    //д����ͨ��
    output [M_AXI_DATA_WIDTH-1 : 0]M_AXI_WDATA,
    output [M_AXI_DATA_WIDTH/8-1 : 0]M_AXI_WSTRB,
    output M_AXI_WLAST,
    output M_AXI_WVALID,
    input M_AXI_WREADY,
    //д��Ӧͨ����ignore��
    input [M_AXI_ID_WIDTH-1 : 0]M_AXI_BID,//ignore
    input [1 : 0] M_AXI_BRESP,//ignore
    input M_AXI_BVALID,//Bvalid and Bread means a a write response.
    output M_AXI_BREADY,//Bvalid and Bread means a a write response.
    
    //������ͨ��
    output [32-1 : 0]M_AXI_ARADDR,
    output [7 : 0]M_AXI_ARLEN,
    output [2 : 0]M_AXI_ARSIZE,//=clogb2((M_AXI_DATA_WIDTH/8)-1);
    output [1 : 0]M_AXI_ARBURST,//=2'b01;
    output M_AXI_ARLOCK,//=1'b0;
    output [3 : 0]M_AXI_ARCACHE,//=4'b10;
    output [2 : 0]M_AXI_ARPROT,//=3'h0;
    output [3 : 0]M_AXI_ARQOS,//=4'h0;
    output M_AXI_ARVALID,
    input M_AXI_ARREADY,
    
    //����Ӧͨ��
    input [M_AXI_ID_WIDTH-1 : 0]M_AXI_RID,
    input [M_AXI_DATA_WIDTH-1 : 0]M_AXI_RDATA,
    input [1 : 0]M_AXI_RRESP,//ignore
    input M_AXI_RLAST,
    input M_AXI_RVALID,
    output M_AXI_RREADY
    );

//dat to CMAC
wire BUF2MAC_dat_vld;
wire [`Tin*`DW-1:0]BUF2MAC_dat;

//wt to CMAC
wire BUF2MAC_wt_vld;
wire [`Tin-1:0]dat_vld_copy;
wire [`Tin*`DW-1:0]BUF2MAC_wt;

//CSR registers
wire [`log2_Height_max-1:0]height;
wire [`log2_Width_max-`log2_Tin-1:0]Win_div_Tin;
wire [`log2_Width_max-`log2_Tin-1:0]Wout_div_Tout; 

MVM_TOP u_MVM_TOP
(
    .clk(clk), 
    .rst_n(rst_n),
    
    .shift(`shift),
    .height(height),
    .Win_div_Tin(Win_div_Tin),
    .Wout_div_Tout(Wout_div_Tout),
    
    .i_dat(BUF2MAC_dat_vld), 
    .dat_vld(input_feature_vld),
    
    .i_wt(i_weight), 
    .wt_vld(input_weight_vld),

    .dat_out(o_feature),
    .dat_out_vld(output_feature_vld),
    .done()
);


CONV_WDMA CONV_WDMA
(
	.clk(clk),
	.rst_n(rst_n),

	//from CSR
	.wdma_start(wdma_start),
	.w_wdma(Wout),
	.h_wdma(Hout),
    .effect_pixel(effect_pixel),
	.ch_wdma_div_Tout(CH_out_div_Tout),	//ceil(ch_wdma/Tout)
	.feature_wdma_base_addr(dat_out_base_addr),
	.feature_wdma_surface_stride(surface_stride_out),
	.feature_wdma_line_stride(line_stride_out),
	
	//to CSR
	.wdma_done(wdma_done),
    .wdma_cycle_done(wdma_cycle_done),
	
	//from core_nonlinear
	.dat_in_vld(wdma_data_in_vld),
	.dat_in_pd(wdma_data_in),
	.dat_in_rdy(wdma_data_in_rdy),

	//write path to MCIF
	.conv2mcif_wr_req_vld(conv2mcif_wr_req_vld),
	.conv2mcif_wr_req_rdy(conv2mcif_wr_req_rdy),
	.conv2mcif_wr_req_pd(conv2mcif_wr_req_pd),
	.conv2mcif_wr_rsp_complete(conv2mcif_wr_rsp_complete)
);
  
  // �����ź�
  reg wr_vld, wr_rdy;
  reg [log2_DEPTH-1:0] num_of_dat;
  reg [`log_b-1:0] block_x, block_y;
  reg [`log_i-1:0] i_max;
  reg [`log_j-1:0] j_max;
  reg [`log_b-1:0] bx_max, by_max;
  reg [`log2_slice_of_r-1:0] slice_of_r;
  wire [log2_DEPTH-1:0] waddr1, waddr2;
  wire [1:0] word_addr;
  reg done;
  
  // ʵ����MEM_transposeģ��
  MEM_transpose #(
    .MEM_DEPTH(`trans_DEPTH),
    .log2_DEPTH(`trans_log2_DEPTH)
  ) mem_transpose_inst (
    .clk(clk),
    .rst_n(rst_n),
    .num_of_dat(num_of_dat),
    .block_x(block_x),
    .block_y(block_y),
    .i_max(i_max),
    .j_max(j_max),
    .bx_max(bx_max),
    .by_max(by_max),
    .slice_of_r(slice_of_r),
    .wr_vld(wr_vld),
    .wr_rdy(wr_rdy),
    .waddr1(waddr1),
    .waddr2(waddr2),
    .word_addr(word_addr),
    .done(done)
  );

  
    
    
endmodule
