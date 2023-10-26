//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/08/16 23:13:42
// Design Name: 
// Module Name:
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
`define size 4
`define M2  4     
`define M3  4     //m3 & m4
`define N1  4
`define N2  4     //n1 new
`define log_i 5
`define log_j 2
`define log_b 5 //max(`log_j,`log_i)

`define clk_period 2
`define Dw 8
`define Dw_1 21
`define Dw_s 22
`define Dw_m 58
`define r 4
`define len 4
`define m_1 18
`define m_2 20
`define m_3 20
`define m_4 8
`define n 4
`define Tin_f (`M2*`M3*`size*`size) //feature  bandwidth
`define Tin_w (`N1*`size*`size) //weight  bandwidth
`define Tmid (`N1*`M3*`size*`size) // middle data bandwidth

`define sys1_num ((`m_1/`size)+1) //5
`define sys2_num (`m_2/`M2) // 4
`define sys3_num ((`m_3*`m_4)/(`size*`M3)) //20
`define Depth_input (`sys1_num*`sys2_num*`sys3_num)
`define log_depth_input 8

`define Depth_weight `sys1_num
`define log_depth_weight 3

//hardware size 
`define DW 8
`define DW_l (`DW*2+7)



`define log2_S 5
`define log2_Width_max 10
`define log2_Height_max 10
`define log2_slice_of_r `Tout/`r