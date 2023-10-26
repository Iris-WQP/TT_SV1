`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Wu Qiuping
// 
// Create Date: 2023/08/16 23:13:42
// Design Name: 
// Module Name: TT_tb
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
`include "TT_define.vh"
`include "basic_tasks.vh"

module TT_tb();

/*---------- software resize tasks -----------*/

task shape_hard_feature_memory(
       input bit [`Dw-1:0] In_Feature [`m_4-1:0][`m_3-1:0][`m_2-1:0][`m_1-1:0],
       output bit [`Tin_f*`Dw-1:0] hard_feature_memory [`Depth_input-1:0] 
);
int L2, L3; //inter_PE index
int k_sum, k_bro;  //intra_PE index
int sys1,sys2,sys3,sys4; //systolic turn index
begin
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int i2=0;i2<`m_2;i2++)
                for(int i1=0;i1<`m_1;i1++)
                begin
                L2 = i2%`M2;
                L3 = (i3/`size)%(`M3);
                k_sum = i1%`size;
                k_bro = i3%`size;
                sys1 = i1/`size;
                sys2 = i2/`M2;
                sys3 = (i3+i4*`m_3)/(`M3*`size);
                hard_feature_memory[sys1+sys2*`sys1_num+sys3*`sys1_num*`sys2_num][(L3*`M2*`size*`size+L2*`size*`size+k_sum*`size+k_bro)*`DW+:`DW] = In_Feature[i4][i3][i2][i1];
                end   
end
endtask

task shape_hard_weight_memory(
        input bit [`Dw-1:0] weight [`r-1:0][`n-1:0][`m_1-1:0],
        output bit [`Tin_w*`Dw-1:0] hard_weight_memory [`Depth_weight-1:0] 
);
int k_sum;  //intra_PE index
int sys1; //systolic turn index
begin
        for(int rr=0;rr<`r;rr++) //k_bro
            for(int j=0;j<`n;j++) //L1
                for(int i=0;i<`m_1;i++)
                begin
                k_sum = i%`size;
                sys1 = i/`size;
                hard_weight_memory[sys1][(j*`size*`size+k_sum*`size+rr)*`DW+:`DW] = weight[rr][j][i];
                end
end
endtask

task shape_feature(
        input bit [`Dw-1:0] In_Buffer [`m_4*`m_3*`m_2*`m_1-1:0],
        output bit [`Dw-1:0] In_Feature [`m_4-1:0][`m_3-1:0][`m_2-1:0][`m_1-1:0]
        );
begin
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int i2=0;i2<`m_2;i2++)
                for(int i1=0;i1<`m_1;i1++)
                begin
                In_Feature[i4][i3][i2][i1] = In_Buffer[i4*`m_3*`m_2*`m_1+i3*`m_2*`m_1+i2*`m_1+i1];
                end        
end
endtask

task shape_weight1(
        input bit [`Dw-1:0] weight1_buff [`r*`n*`m_1-1:0],
        output bit [`Dw-1:0] weight [`r-1:0][`n-1:0][`m_1-1:0]
        );
begin
        for(int rr=0;rr<`r;rr++)
            for(int j=0;j<`n;j++)
                for(int i=0;i<`m_1;i++)
                begin
                weight[rr][j][i] = weight1_buff[rr*`n*`m_1+j*`m_1+i];
                end        
end
endtask

task shape_weight2(
        input bit [`Dw-1:0] In_Buffer [`r*`n*`m_2*`r-1:0],
        output bit [`Dw-1:0] weight [`r-1:0][`n-1:0][`m_2-1:0][`r-1:0]
        );
begin
        for(int rr=0;rr<`r;rr++)
            for(int j=0;j<`n;j++)
                for(int i=0;i<`m_2;i++)
                    for(int r=0; r<`r; r++)
                begin
                weight[rr][j][i][r] = In_Buffer[rr*`n*`m_2*`r+j*`m_2*`r+i*`r+r];
                end        
end
endtask

task shape_weight3(
        input bit [`Dw-1:0] In_Buffer [`m_4*`m_3*`m_2*`m_1-1:0],
        output bit [`Dw-1:0] weight [`r-1:0][`n-1:0][`m_3-1:0][`r-1:0]
        );
begin
        for(int rr=0;rr<`r;rr++)
            for(int j=0;j<`n;j++)
                for(int i=0;i<`m_3;i++)
                    for(int r=0; r<`r; r++)
                begin
                weight[rr][j][i][r] = In_Buffer[rr*`n*`m_3*`r+j*`m_3*`r+i*`r+r];
                end        
end
endtask

task shape_weight4(
        input bit [`Dw-1:0] In_Buffer [`m_4*`m_3*`m_2*`m_1-1:0],
        output bit [`Dw-1:0] weight [`n-1:0][`m_4-1:0][`r-1:0]
        );
begin
        for(int j=0;j<`n;j++)
            for(int i=0;i<`m_4;i++)
                for(int r=0; r<`r; r++)
                begin
                weight[j][i][r] = In_Buffer[j*`m_4*`r+i*`r+r];
                end        
end
endtask

task verify_result(
        input [`Dw_m-1:0] y_buff [`n*`n*`n*`n-1:0],
        output [`Dw_m-1:0] Out_Y [`n-1:0][`n-1:0][`n-1:0][`n-1:0]
        );
begin
automatic bit flag = 0;
        for(int j4=0;j4<`n;j4++)
            for(int j3=0;j3<`n;j3++)
                for(int j2=0; j2<`n; j2++)
                for(int j1=0; j1<`n; j1++)
                begin
                if(Out_Y[j4][j3][j2][j1] != y_buff[j4*`n*`n*`n+j3*`n*`n+j2*`n+j1]) 
                begin
                    $display("Out_Y[%d][%d][%d][%d] = %d is wrong ",j4,j3,j2,j1,Out_Y[j4][j3][j2][j1]);
                    $display("It should be %d ",y_buff[j4*`n*`n*`n+j3*`n*`n+j2*`n+j1]);
                    flag=1;
                end
          end
          if(flag == 0)   $display("All Out_Y is right.");
                       
end
endtask


task TT_no_trunc(
        input bit [`Dw-1:0] In_Feature [`m_4-1:0][`m_3-1:0][`m_2-1:0][`m_1-1:0],
        input bit [`Dw-1:0] weight1 [`r-1:0][`n-1:0][`m_1-1:0],
        input bit [`Dw-1:0] weight2 [`r-1:0][`n-1:0][`m_2-1:0][`r-1:0],
        input bit [`Dw-1:0] weight3 [`r-1:0][`n-1:0][`m_3-1:0][`r-1:0],
        input bit [`Dw-1:0] weight4 [`n-1:0][`m_4-1:0][`r-1:0],
        output bit [`Dw_1-1:0] p1 [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0],
        output bit [`Dw_m-1:0] p2 [`m_4-1:0][`m_3-1:0][`n-1:0][`n-1:0][`r-1:0],
        output bit [`Dw_m-1:0] p3 [`m_4-1:0][`n-1:0][`n-1:0][`n-1:0][`r-1:0],
        output bit [`Dw_m-1:0] Out_Y [`n-1:0][`n-1:0][`n-1:0][`n-1:0]     //n=4
        );
begin
//// psums
//bit [`Dw_1-1:0] p1 [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];
//bit [`Dw_m-1:0] p2 [`m_4-1:0][`m_3-1:0][`n-1:0][`n-1:0][`r-1:0];
//bit [`Dw_m-1:0] p3 [`m_4-1:0][`n-1:0][`n-1:0][`n-1:0][`r-1:0];

//G1
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int i2=0;i2<`m_2;i2++)
                for(int rr=0;rr<`r;rr++)
                    for(int j1=0; j1<`n; j1++)
                    begin
                        p1[i4][i3][i2][j1][rr] <= 'd0;
                        for(int i1=0;i1<`m_1;i1++)
                        begin
                        p1[i4][i3][i2][j1][rr] += weight1 [rr][j1][i1] * In_Feature [i4][i3][i2][i1];
                        end
                    end         

//G2
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int j1=0; j1<`n; j1++)
                for(int rr=0;rr<`r;rr++)
                     for(int j2=0; j2<`n; j2++)
                     begin
                         p2[i4][i3][j2][j1][rr] <= 'd0;
                         for(int i2=0; i2<`m_2; i2++)
                         for(int r=0; r<`r; r++)
                         begin
                         p2[i4][i3][j2][j1][rr] += weight2 [rr][j2][i2][r] * p1[i4][i3][i2][j1][r];
                         end
                     end
                        
//G3
    for(int i4=0;i4<`m_4;i4++)
        for(int j2=0; j2<`n; j2++)
            for(int j1=0; j1<`n; j1++)
                for(int rr=0;rr<`r;rr++)
                    for(int j3=0; j3<`n; j3++)
                    begin
                        p3[i4][j3][j2][j1][rr] <= 'd0;
                         for(int i3=0; i3<`m_3; i3++)
                         for(int r=0; r<`r; r++)
                         begin
                         p3[i4][j3][j2][j1][rr] += weight3 [rr][j3][i3][r] * p2[i4][i3][j2][j1][r];
                         end
                     end     
                     
//G4
    for(int j3=0;j3<`n; j3++)
        for(int j2=0; j2<`n; j2++)
            for(int j1=0; j1<`n; j1++)
                 for(int j4=0; j4<`n; j4++)
                    begin
                         Out_Y[j4][j3][j2][j1] <= 'd0;
                         for(int i4=0; i4<`m_4; i4++)
                         for(int r=0; r<`r; r++)
                         begin
                         Out_Y[j4][j3][j2][j1] += weight4 [j4][i4][r] * p3[i4][j3][j2][j1][r];
                         end
                     end                       
end
endtask

task TT_trunc(
        input bit [`Dw-1:0] In_Feature [`m_4-1:0][`m_3-1:0][`m_2-1:0][`m_1-1:0],
        input bit [`Dw-1:0] weight1 [`r-1:0][`n-1:0][`m_1-1:0],
        input bit [`Dw-1:0] weight2 [`r-1:0][`n-1:0][`m_2-1:0][`r-1:0],
        input bit [`Dw-1:0] weight3 [`r-1:0][`n-1:0][`m_3-1:0][`r-1:0],
        input bit [`Dw-1:0] weight4 [`n-1:0][`m_4-1:0][`r-1:0],
        output bit [`Dw-1:0] Out_Y [`n-1:0][`n-1:0][`n-1:0][`n-1:0],     //n=4
        output bit [`Dw-1:0] p1 [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0]
        );
begin
//bit [`Dw-1:0] p1 [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];
bit [`Dw-1:0] p2 [`m_4-1:0][`m_3-1:0][`n-1:0][`n-1:0][`r-1:0];
bit [`Dw-1:0] p3 [`m_4-1:0][`n-1:0][`n-1:0][`n-1:0][`r-1:0];
bit [`Dw_s-1:0] p1_s [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];
bit [`Dw_s-1:0] p2_s [`m_4-1:0][`m_3-1:0][`n-1:0][`n-1:0][`r-1:0];
bit [`Dw_s-1:0] p3_s [`m_4-1:0][`n-1:0][`n-1:0][`n-1:0][`r-1:0];
bit [`Dw_s-1:0] Out_Y_s [`n-1:0][`n-1:0][`n-1:0][`n-1:0];     //n=4
//G1
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int i2=0;i2<`m_2;i2++)
                for(int rr=0;rr<`r;rr++)
                    for(int j1=0; j1<`n; j1++)
                    begin
                        p1_s[i4][i3][i2][j1][rr] <= 'd0;
                        for(int i1=0;i1<`m_1;i1++)
                        begin
                        p1_s[i4][i3][i2][j1][rr] += weight1 [rr][j1][i1] * In_Feature [i4][i3][i2][i1];
                        end
                        p1[i4][i3][i2][j1][rr] = p1_s[i4][i3][i2][j1][rr][`Dw_s-4:`Dw_s-11];
     //                   if(p1_s[i4][i3][i2][j1][rr][`Dw_s-3]==1) p1[i4][i3][i2][j1][rr] = 8'b11111111;
                    end                                  
  
//G2
    for(int i4=0;i4<`m_4;i4++)
        for(int i3=0;i3<`m_3;i3++)
            for(int j1=0; j1<`n; j1++)
                for(int rr=0;rr<`r;rr++)
                     for(int j2=0; j2<`n; j2++)
                     begin
                         p2_s[i4][i3][j2][j1][rr] <= 'd0;
                         for(int i2=0; i2<`m_2; i2++)
                         for(int r=0; r<`r; r++)
                         begin
                         p2_s[i4][i3][j2][j1][rr] += weight2 [rr][j2][i2][r] * p1[i4][i3][i2][j1][r];
                         end
                         p2[i4][i3][j2][j1][rr] = p2_s[i4][i3][j2][j1][rr][`Dw_s-2:`Dw_s-9];
     //                    if(p2_s[i4][i3][j2][j1][rr][`Dw_s-1]==1) p2[i4][i3][j2][j1][rr] = 8'b11111111;
                     end            
          
//G3
    for(int i4=0;i4<`m_4;i4++)
        for(int j2=0; j2<`n; j2++)
            for(int j1=0; j1<`n; j1++)
                for(int rr=0;rr<`r;rr++)
                    for(int j3=0; j3<`n; j3++)
                    begin
                        p3_s[i4][j3][j2][j1][rr] <= 'd0;
                         for(int i3=0; i3<`m_3; i3++)
                         for(int r=0; r<`r; r++)
                         begin
                         p3_s[i4][j3][j2][j1][rr] += weight3 [rr][j3][i3][r] * p2[i4][i3][j2][j1][r];
                         end
                        p3[i4][j3][j2][j1][rr] = p3_s[i4][j3][j2][j1][rr][`Dw_s-2:`Dw_s-9];
      //                  if(p3_s[i4][j3][j2][j1][rr][`Dw_s-1]==1) p3[i4][j3][j2][j1][rr] = 8'b11111111;
                     end     
                   
                                            
//G4
    for(int j3=0;j3<`n; j3++)
        for(int j2=0; j2<`n; j2++)
            for(int j1=0; j1<`n; j1++)
                 for(int j4=0; j4<`n; j4++)
                    begin
                         Out_Y_s[j4][j3][j2][j1] <= 'd0;
                         for(int i4=0; i4<`m_4; i4++)
                         for(int r=0; r<`r; r++)
                         begin
                         Out_Y_s[j4][j3][j2][j1] += weight4 [j4][i4][r] * p3[i4][j3][j2][j1][r];
                         end
                         Out_Y[j4][j3][j2][j1] = Out_Y_s[j4][j3][j2][j1][`Dw_s-3:`Dw_s-10];
                     end                       
end
endtask

bit [4:0] m1; 
bit [4:0] m2;
bit [4:0] m3; 
bit [4:0] m4;
bit [2:0] n;
bit [`Dw-1:0] i_mean_buff [`m_4*`m_3*`m_2*`m_1-1:0];
bit [`Dw_m-1:0] y_buff [`n*`n*`n*`n-1:0];
bit [`Dw-1:0] weight1_buff [`r*`n*`m_1-1:0];
bit [`Dw-1:0] weight2_buff [`r*`n*`m_2*`r-1:0];
//use i_mean_buff as weight3, weight4 buffer
bit [`Dw-1:0] input_buff [`m_4-1:0][`m_3-1:0][`m_2-1:0][`m_1-1:0];
bit [`Dw-1:0] weight1 [`r-1:0][`n-1:0][`m_1-1:0];
bit [`Dw-1:0] weight2 [`r-1:0][`n-1:0][`m_2-1:0][`r-1:0];
bit [`Dw-1:0] weight3 [`r-1:0][`n-1:0][`m_3-1:0][`r-1:0];
bit [`Dw-1:0] weight4 [`n-1:0][`m_4-1:0][`r-1:0];
bit [`Dw_m-1:0] Out_Y [`n-1:0][`n-1:0][`n-1:0][`n-1:0];
bit [`Dw-1:0] Out_Y_8bit [`n-1:0][`n-1:0][`n-1:0][`n-1:0];
bit [`Dw_1-1:0] p1 [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];
bit [`Dw_m-1:0] p2 [`m_4-1:0][`m_3-1:0][`n-1:0][`n-1:0][`r-1:0];
bit [`Dw_m-1:0] p3 [`m_4-1:0][`n-1:0][`n-1:0][`n-1:0][`r-1:0];

bit [`Dw-1:0] soft_p1_trunc [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];
/*-----------hardware signal------------*/
bit [`Dw-1:0] hard_p1_trunc [`m_4-1:0][`m_3-1:0][`m_2-1:0][`n-1:0][`r-1:0];

bit flag = 0;
integer error;
integer sum;
/*-----basic definitions-----*/
initial begin
m1 = 5'd18;
m2 = 5'd20;
m3 = 5'd20;
m4 = 5'd8;
n = 3'd4;
$readmemb("D:/tt_LSTM_8bit_bi/x.txt",i_mean_buff);
shape_feature(i_mean_buff, input_buff);
$display("input_bufflast = %d ",input_buff[`m_4-1][`m_3-1][`m_2-1][`m_1-1]);
$readmemb("D:/TT_LSTM_8bit_bi/c4_3.txt",weight1_buff);
shape_weight1(weight1_buff, weight1);

$readmemb("D:/tt_LSTM_8bit_bi/c4_2.txt",weight2_buff);
shape_weight2(weight2_buff, weight2);

$readmemb("D:/tt_LSTM_8bit_bi/c4_1.txt",i_mean_buff);
shape_weight3(i_mean_buff, weight3);

$readmemb("D:/tt_LSTM_8bit_bi/c4_0.txt",i_mean_buff);
shape_weight4(i_mean_buff, weight4);


TT_no_trunc(input_buff, weight1, weight2, weight3, weight4,p1,p2,p3, Out_Y);
TT_trunc(input_buff, weight1, weight2, weight3, weight4, Out_Y_8bit, soft_p1_trunc);

$display("out[0][0][0][0] = %d, standard_8bit = %d, out_8bit[0][0][0][0] = %d, ratio = %d",Out_Y[0][0][0][0], Out_Y[0][0][0][0][57:49], Out_Y_8bit[0][0][0][0], (Out_Y[0][0][0][0]/Out_Y_8bit[0][0][0][0]));
$display("out[0][0][0][1] = %d, standard_8bit = %d, out_8bit[0][0][0][1] = %d, ratio = %d",Out_Y[0][0][0][1], Out_Y[0][0][0][1][57:49], Out_Y_8bit[0][0][0][1], (Out_Y[0][0][0][1]/Out_Y_8bit[0][0][0][1]));
$display("out[0][0][0][2] = %d, standard_8bit = %d, out_8bit[0][0][0][2] = %d, ratio = %d",Out_Y[0][0][0][2], Out_Y[0][0][0][2][57:49], Out_Y_8bit[0][0][0][2], (Out_Y[0][0][0][2]/Out_Y_8bit[0][0][0][2]));
$display("out[0][0][1][0] = %d, standard_8bit = %d, out_8bit[0][0][1][0] = %d, ratio = %d",Out_Y[0][0][1][0], Out_Y[0][0][1][0][57:49], Out_Y_8bit[0][0][1][0], (Out_Y[0][0][1][0]/Out_Y_8bit[0][0][1][0]));
$display("out[0][1][2][0] = %d, standard_8bit = %d, out_8bit[0][1][2][0] = %d, ratio = %d",Out_Y[0][1][2][0], Out_Y[0][1][2][0][57:49], Out_Y_8bit[0][1][2][0], (Out_Y[0][1][2][0]/Out_Y_8bit[0][1][2][0]));


$readmemb("D:/tt_LSTM_8bit_bi/y4.txt", y_buff);
        for(int j4=0; j4<`n; j4++)
            for(int j3=0;j3<`n;j3++)
                for(int j2=0; j2<`n; j2++)
                for(int j1=0; j1<`n; j1++)
                begin
                if(Out_Y[0][j3][j2][j1] != y_buff[j3*`n*`n+j2*`n+j1]) 
                begin
                    $display("Out_Y[%d][%d][%d][%d] = %d is wrong ",0,j3,j2,j1,Out_Y[0][j3][j2][j1]);
                    $display("It should be %d ",y_buff[j3*`n*`n+j2*`n+j1]);
                    flag=1;
                end
          end
          if(flag == 0)   $display("All Out_Y is right.");
error = 0;
sum = 0;
        for(int j4=0; j4<`n; j4++)
            for(int j3=0;j3<`n;j3++)
                for(int j2=0; j2<`n; j2++)
                for(int j1=0; j1<`n; j1++)
                begin
                sum = sum + Out_Y[j4][j3][j2][j1][57:49];
                error = error + (Out_Y[j4][j3][j2][j1][57:49]-Out_Y_8bit[j4][j3][j2][j1]);
          end
          $display("average error value = %d;\n average standard value = %d;\n average error rate = %f", (error/256), (sum/256), (error/sum));
          $display();
          $display();
                        
end

/*-------------------- hardware control ------------------------*/
bit clk;
bit rst_n;
bit start;
bit start_in;
bit done_input;
bit done_weight;
bit [1:0] init_en2;
bit valid1;
bit ready1;
bit [`Tin_f*`DW-1:0] hard_features;
bit hard_features_vld;
bit [`Tin_w*`DW-1:0] hard_weights;
bit hard_weights_vld;
bit [`Tmid*`DW-1:0] hard_middle_data;
bit [7:0] num_of_dat;
bit finish;

always #(`clk_period/2) clk=~clk;
initial begin
    #(`clk_period) rst_n=0;clk=0; valid1=1; finish=0;start=0;
    #(`clk_period) rst_n=1;
repeat(4*20) begin    
    #(`clk_period) start=1;finish=0;
    #(`clk_period) start=0; 
    #(3*`clk_period)finish=1;
end
end

initial begin
    #(`clk_period) 
    #(`clk_period)
   
    #(`clk_period) start_in=1;
    #(`clk_period) start_in=0;

end

Memory_IN #
(
    .WIDTH( `MAX_DW*`Tin ),
    .DEPTH( `Height*`slice_of_Win*`slice_of_Wout ),
    .log2_DEPTH( `log2_Height_max + `log2_Width_max +`log2_Width_max-`log2_Tout- `log2_Tin  )
) u_Input_Memory
(
    .clk(clk),
    .rst_n(rst_n),
    .start(input_start),
    .num_of_dat(`Height*`slice_of_Win*`slice_of_Wout-1),
    
    .dat_out(i_feature),
    .dat_out_vld(input_feature_vld),
    .done()
);

Memory_IN #
(
    .WIDTH( `MAX_DW*`Tin*`Tout ),
    .DEPTH( `Height*`slice_of_Win*`slice_of_Wout),
    .log2_DEPTH( `log2_Height_max + `log2_Width_max +`log2_Width_max-`log2_Tout- `log2_Tin  )
) u_Weight_Memory
(
    .clk(clk),
    .rst_n(rst_n),
    .start(wt_start),
    .num_of_dat(`Height*`slice_of_Win*`slice_of_Wout-1),
    
    .dat_out(i_weight),
    .dat_out_vld(input_weight_vld),
    .done()
);


Memory_OUT#
(
    .WIDTH( `MAX_DW*`Tout ),
    .DEPTH( `Height*`slice_of_Wout ),
    .log2_DEPTH( `log2_Height_max + `log2_Width_max - `log2_Tout )
) u_Output_Memory
(
    .clk(clk),
    .rst_n(rst_n),
    .dat_num(`Height*`slice_of_Wout-1),
    .dat(o_feature),
    .dat_vld(output_feature_vld),
    .done()
);

MVM_TOP u_MVM_TOP
(
    .clk(clk), 
    .rst_n(rst_n),
    
    .shift(`shift),
    .height(height),
    .Win_div_Tin(Win_div_Tin),
    .Wout_div_Tout(Wout_div_Tout),
    
    .i_dat(i_feature), 
    .dat_vld(input_feature_vld),
    
    .i_wt(i_weight), 
    .wt_vld(input_weight_vld),

    .dat_out(o_feature),
    .dat_out_vld(output_feature_vld),
    .done()
);


endmodule
