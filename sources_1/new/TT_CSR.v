`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Huang Mingqiang, Wu Qiuping
// 
// Create Date: 2023/10/22 14:37:14
// Design Name: 
// Module Name: TT_CSR
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
`define  log2CSR_REG_NUM 8

module TT_CSR	(
    input clk,
	input rst_n,
	//AXI lite
	//AW channel
	input S_AXI_AWVALID,
	output S_AXI_AWREADY,
	input [`log2CSR_REG_NUM+2-1:0]S_AXI_AWADDR,
	input [2:0]S_AXI_AWPROT,//ignore
	
	//Wr channel
	input [31:0]S_AXI_WDATA,
	input S_AXI_WVALID,
	output S_AXI_WREADY,
	input [3:0]S_AXI_WSTRB,//ignore
	output [1:0]S_AXI_BRESP,//=2'b0
	output S_AXI_BVALID,
	input S_AXI_BREADY,
	
	//AR channel
	input S_AXI_ARVALID,
	output S_AXI_ARREADY,
	input [`log2CSR_REG_NUM+2-1:0]S_AXI_ARADDR,
	input [2:0]S_AXI_ARPROT,//ignore

    //Rd channel
	output [31:0]S_AXI_RDATA,
	output [1:0]S_AXI_RRESP,//=2'b0
	output S_AXI_RVALID,
	input S_AXI_RREADY,

	//CSB to Conv Path: 0~63
	output csb2cp_csr_req_vld,
	input csb2cp_csr_req_rdy,
	output [(`log2CSR_REG_NUM+32+1):0]csb2cp_csr_req_pd,
	input cp_csr2csb_resp_vld,
	input [31:0]cp_csr2csb_resp_pd,

	//CSB to FC Tensor Train Path: 64~127
	output csb2tt_req_vld,
	input csb2tt_req_rdy,
	output [(`log2CSR_REG_NUM+32+1):0]csb2tt_req_pd,
	input tt2csb_resp_vld,
	input [31:0]tt2csb_resp_pd,

);

reg axi_wready;
reg axi_bvalid;
reg axi_rvalid;
reg [1:0]state;
reg [1:0]w_state;
reg [2:0]r_state;
reg axi_awready;
reg axi_arready;

wire cmd_wr_rd=(state==2'd1);
wire [`log2CSR_REG_NUM:0]cmd_addr_cp=cmd_addr;
wire [`log2CSR_REG_NUM:0]cmd_addr_tt=cmd_addr-64;


reg cmd_vld;
reg [`log2CSR_REG_NUM:0]cmd_addr;
reg [31:0]cmd_wdata;

always @(posedge clk or negedge rst_n)
if(~rst_n)
    begin
	state<=1'b0;
	w_state<='d0;
	r_state<='d0;
	axi_awready<=1'b0;
	axi_arready<=1'b0;
	axi_wready<=1'b0;
	axi_rvalid<=1'b0;
	cmd_vld<=1'b0;
	cmd_wdata<='d0;
	cmd_addr<=0;
    end
else
    case(state)
        'd0://Idle
            begin
                if(S_AXI_AWVALID)
                    begin
                        state<='d1;
                        axi_awready<=1'b1;
                    end
                else
                    if(S_AXI_ARVALID)
                        begin
                            state<='d2;
                            axi_arready<=1'b1;
                        end
            end
        'd1://Writing
            begin
                case(w_state)
                'd0:
                    if(S_AXI_AWVALID)
                    begin
                        w_state<='d1;
                        axi_awready<=1'b0;
                        cmd_addr<=S_AXI_AWADDR[`log2CSR_REG_NUM+2-1:2];
                    end
                'd1:
                    if(S_AXI_WVALID)
                    begin
                        w_state<='d2;
                        cmd_wdata<=S_AXI_WDATA;
                        cmd_vld<=1'b1;
                    end
                'd2:
                    if(cmd_rdy)
                    begin
                        w_state<='d3;
                        cmd_vld<=1'b0;
                        axi_wready<=1'b1;
                    end
                'd3:
                    if(S_AXI_WVALID)
                    begin
                        state<='d0;
                        w_state<='d0;
                        axi_wready<=1'b0;
                    end
               endcase
           end
        'd2://Reading
            begin
                case(r_state)
                'd0:
                    if(S_AXI_ARVALID)
                    begin
                        r_state<='d1;
                        axi_arready<=1'b0;
                        cmd_addr<=S_AXI_ARADDR[`log2CSR_REG_NUM+2-1:2];
                    end
                'd1:
                    begin
                        r_state<='d2;
                        cmd_vld<=1'b1;
                    end
                'd2:
                    if(cmd_rdy)
                    begin
                        r_state<='d3;
                        cmd_vld<=1'b0;
                    end
                'd3:
                    if(rsp_vld)
                    begin
                        r_state<='d4;
                        axi_rvalid<=1'b1;
                    end
                'd4:
                    if(S_AXI_RREADY)
                    begin
                        r_state<='d0;
                        state<='d0;
                        axi_rvalid<=1'b0;
                    end
                endcase
            end
    endcase




endmodule
