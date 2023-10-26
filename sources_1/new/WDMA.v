`include "CNN_defines.vh"
`define log2_W 5
`define log2_H 11
`define AXI_BURST_LEN 16
`define log2AXI_BURST_LEN 4
`define DW 8

//(* use_dsp = "yes" *)
module CONV_WDMA//write DMA
(
	input clk,
	input rst_n,
    
	//from CSR
	input wdma_start,
	input [`log2_W-1:0]w_wdma,
	input [`log2_H-1:0]h_wdma,
	input [(`log2_W+`log2_H-1):0]effect_pixel,
	input ch_wdma_div_Tout,	//ceil(ch_wdma/Tout) ºãµÈÓÚ1
	input [31:0]feature_wdma_base_addr,
	input [31:0]feature_wdma_surface_stride,
	input [15:0]feature_wdma_line_stride,
	
	//to CSR
	output wdma_done,
	output wdma_cycle_done,

	//from conv_mac_and_acc
	input dat_in_vld,
	input [`Tout*`DW-1:0]dat_in_pd,
	output dat_in_rdy,

	//write path to MCIF
	output conv2mcif_wr_req_vld,
	input conv2mcif_wr_req_rdy,
	output [2+`log2AXI_BURST_LEN+32+`DW *`Tout-1:0]conv2mcif_wr_req_pd,
	input conv2mcif_wr_rsp_complete
);



wire [`log2AXI_BURST_LEN-1:0]cmd_length;
reg cmd_en,dat_en;

reg [`log2AXI_BURST_LEN-1:0]burst_len_cnt;
wire burst_len_cnt_will_update_now=dat_in_vld&dat_in_rdy;
wire burst_len_cnt_is_max_now=(burst_len_cnt==cmd_length);
always @(posedge clk or negedge rst_n)
if(~rst_n)
	burst_len_cnt<=0;
else
	if(burst_len_cnt_will_update_now)
	begin
		if(burst_len_cnt_is_max_now)
			burst_len_cnt<=0;
		else
			burst_len_cnt<=burst_len_cnt+1;
	end
	
reg [`log2_W-`log2AXI_BURST_LEN-1:0]burst_times_cnt;
reg [31:0] burst_times_cnt_bias;
wire burst_times_cnt_will_update_now=burst_len_cnt_will_update_now&burst_len_cnt_is_max_now;
wire burst_times_cnt_is_max_now=(burst_times_cnt==((w_wdma-1)>>`log2AXI_BURST_LEN));
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		burst_times_cnt<=0;
		burst_times_cnt_bias<=0;
	end
	else
		if(burst_times_cnt_will_update_now)
		begin
			if(burst_times_cnt_is_max_now)
			begin
				burst_times_cnt<=0;
				burst_times_cnt_bias<=0;
			end
			else
			begin
				burst_times_cnt<=burst_times_cnt+1;
				burst_times_cnt_bias<=burst_times_cnt_bias+(`AXI_BURST_LEN)*(`Pixel_Data_Bytes);
			end
		end
end

reg [`log2_H-1:0]h_cnt;
reg [(`log2_W+`log2_H-1):0]h_pixel_bias;
reg [31:0] h_cnt_bias;
wire h_cnt_will_update_now=burst_times_cnt_will_update_now&burst_times_cnt_is_max_now;
wire h_cnt_is_max_now=(h_cnt==(h_wdma-1));
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		h_cnt<=0;
		h_pixel_bias<=0;
		h_cnt_bias<=0;
	end
	else
		if(h_cnt_will_update_now)
		begin
			if(h_cnt_is_max_now)
			begin
				h_cnt<=0;
				h_pixel_bias<=0;
				h_cnt_bias<=0;
			end
			else
			begin
				h_cnt<=h_cnt+1;
				h_pixel_bias<=h_pixel_bias+w_wdma;
				h_cnt_bias<=h_cnt_bias+feature_wdma_line_stride;
			end
		end
end

reg [`log2_CH-1:0]ch_cnt;
reg [31:0]ch_cnt_bias;
wire ch_cnt_will_update_now=h_cnt_will_update_now&h_cnt_is_max_now;
wire ch_cnt_is_max_now=(ch_cnt==ch_wdma_div_Tout-1);
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		ch_cnt<=0;
		ch_cnt_bias<=0;
	end
	else
		if(ch_cnt_will_update_now)
		begin
			if(ch_cnt_is_max_now)
			begin
				ch_cnt<=0;
				ch_cnt_bias<=0;
			end
			else
			begin
				ch_cnt<=ch_cnt+1;
				ch_cnt_bias<=ch_cnt_bias+feature_wdma_surface_stride;
			end
		end
end

reg wdma_working;
always @(posedge clk or negedge rst_n)
if(~rst_n)
	wdma_working<=1'b0;
else
	if(wdma_start)
		wdma_working<=1'b1;
	else
		if(ch_cnt_will_update_now&ch_cnt_is_max_now)
			wdma_working<=1'b0;


always @(posedge clk or negedge rst_n)
if(~rst_n)
	{cmd_en,dat_en}<=2'b10;
else
	if(cmd_en & conv2mcif_wr_req_vld & conv2mcif_wr_req_rdy)
		{cmd_en,dat_en}<=2'b01;
	else
		if(burst_len_cnt_will_update_now&burst_len_cnt_is_max_now)
			{cmd_en,dat_en}<=2'b10;

//wire [31:0]burst_times_cnt_bias = (burst_times_cnt<<`log2AXI_BURST_LEN)*(`Tout*(`MAX_log2DAT_DW-2));
//wire [31:0]h_cnt_bias = feature_wdma_line_stride*h_cnt;
//wire [31:0]ch_cnt_bias = feature_wdma_surface_stride*ch_cnt;
assign dat_in_rdy=dat_en&conv2mcif_wr_req_rdy;

assign cmd_length=(burst_times_cnt_is_max_now?(w_wdma[`log2AXI_BURST_LEN-1:0]-1):(`AXI_BURST_LEN-1));
//wire [31:0]cmd_addr=feature_wdma_base_addr+ch_cnt_bias+h_cnt_bias+burst_times_cnt_bias;

//
wire [31:0]cmd_addr=burst_times_cnt_bias+ch_cnt_bias+h_cnt_bias;
					
wire cmd_nonposted=ch_cnt_is_max_now&h_cnt_is_max_now&burst_times_cnt_is_max_now;

wire [(`log2_W+`log2_H-1):0]current_pixel=(burst_times_cnt<<`log2AXI_BURST_LEN)+(h_pixel_bias+burst_len_cnt);
wire out_of_pixel=current_pixel>=effect_pixel?1'b1:1'b0;
wire [`MAX_DAT_DW *`Tout-1:0] tp_dat=(current_pixel>=effect_pixel)?{(`MAX_DAT_DW *`Tout){1'b0}}:dat_in_pd;

wire [2+`log2AXI_BURST_LEN+32+`MAX_DAT_DW *`Tout-1:0] cmd_req_pd={1'b1,{(`MAX_DAT_DW *`Tout-32){1'b0}},feature_wdma_base_addr,cmd_nonposted,cmd_length,cmd_addr};
wire [2+`log2AXI_BURST_LEN+32+`MAX_DAT_DW *`Tout-1:0] dat_req_pd={{(2+`log2AXI_BURST_LEN+32){1'b0}},tp_dat};

assign conv2mcif_wr_req_vld=(dat_en&dat_in_vld) | (wdma_working&cmd_en);
assign conv2mcif_wr_req_pd=cmd_en?cmd_req_pd:dat_req_pd;

assign wdma_done=conv2mcif_wr_rsp_complete;

generate_vld_shift #
(
   .DATA_WIDTH(1),
   .DEPTH(`AXI_BURST_LEN)
)done_shift
(
   .clk(clk),
   .rst_n(rst_n),
   .data_in(ch_cnt_will_update_now&ch_cnt_is_max_now),
   .data_out(wdma_cycle_done)
);

endmodule
