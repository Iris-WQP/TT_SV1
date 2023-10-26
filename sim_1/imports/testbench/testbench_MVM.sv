`include "CNN_defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: SUSTech
// Engineer: Huang Mingqiang
// 
// Create Date: 2023/08/16 23:13:42
// Design Name: 
// Module Name: testbench_MVM
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
////////////////////////////////////////////////////////////////////////////////
//`define Height 512
//`define Width_in  128
//`define Width_out 64
//`define Height 18//5//
//`define Width_in  256//4//3200
//`define Width_out (4*4)//3//
module testbench_MVM;


bit clk;
bit rst_n;

////////////////////////////////////////

`include "basic_tasks.vh"


integer flag0=1;
integer flag1=1;
integer flag2=1;

bit [31:0]rdata;
bit [31:0]DDR_input_feature_addr;
bit [31:0]DDR_wt_addr;
bit [31:0]DDR_output_feature_addr;
bit input_start;
bit wt_start;

bit [`MAX_DW*`Tin-1:0]i_feature;      //һ�������feature
bit input_feature_vld;
bit [`MAX_DW*`Tin*`Tout-1:0]i_weight;   //һ�������weight
bit input_weight_vld;
bit [`MAX_DW*`Tout-1:0]o_feature;     //һ�������feature
bit output_feature_vld;

bit [`log2_Height_max-1:0]height;
bit [`log2_Width_max-`log2_Tin-1:0]Win_div_Tin;
bit [`log2_Width_max-`log2_Tin-1:0]Wout_div_Tout;

bit [`MAX_DW-1:0]       In_Feature [`Height][`Width_in]; //ԭʼ�������ݽṹ
bit [`MAX_DW*`Tin-1:0]  In_Feature_Expand [`Height][`slice_of_Win]; 
bit [`MAX_DW*`Tin-1:0]  In_Feature_Expand_in_DDR [`slice_of_Win][`Height]; //�洢��DDR�е����ݽṹ

bit [`MAX_DW-1:0]       Weight     [`Width_in][`Width_out]; 
bit [`MAX_DW*`Tin-1:0]  Weight_Expand_Tin [`slice_of_Win][`Width_out];
bit [`MAX_DW*`Tin*`Tout-1:0]  Weight_Expand_TinTout [`slice_of_Win][`slice_of_Wout];
bit [`MAX_DW*`Tin*`Tout-1:0]  Weight_Expand_TinTout_in_DDR [`slice_of_Wout][`slice_of_Win];

bit [`MAX_DW-1:0]       Out_Feature_soft[`Height][`Width_out];
bit [`MAX_DW-1:0]       Out_Feature_Tin_soft[`Height][`Width_out];
bit [`MAX_DW*`Tout-1:0] Out_Feature_TinTout_soft[`Height][`slice_of_Wout];
bit [`MAX_DW*`Tout-1:0] Out_Feature_hardware[`slice_of_Wout][`Height];



initial
begin

    for(int i=0;i<`Height;i++)
        for(int j=0;j<`Width_in;j++)
        begin
            In_Feature[i][j]=$random();//i*`Width_in+j+1;//
        end
      
    for(int i=0;i<`Width_in;i++)
        for(int j=0;j<`Width_out;j++)
        begin
            Weight[i][j]=$random();//0?i*`Width_out+j+1:0;//
        end
        
    Run_MVM_Soft(In_Feature, Weight, `shift, Out_Feature_soft);
    ReMap_Feature_Data(In_Feature, In_Feature_Expand);
    ReMap_Weight_Data_Tin(Weight, Weight_Expand_Tin);
    Run_MVM_Soft_Tin(In_Feature_Expand, Weight_Expand_Tin,`shift, Out_Feature_Tin_soft);
    
    ReMap_Weight_Data_TinTout(Weight, Weight_Expand_TinTout);
    Run_MVM_Soft_TinTout(In_Feature_Expand, Weight_Expand_TinTout,`shift, Out_Feature_TinTout_soft);
        
                
    for(int i=0;i<`Height;i++)
        for(int j=0;j<`Width_out;j++)
        begin
            $display("dat_out_software[%0d][%0d]=%0d",i,j,$signed(Out_Feature_soft[i][j]));
            if(Out_Feature_soft[i][j]!=Out_Feature_Tin_soft[i][j])
            begin
                flag0=0;
                $display("error! dat_out_software_Tin[%0d][%0d]=%0d, dat_out_software=%0d",i,j,$signed(Out_Feature_soft[i][j]), $signed(Out_Feature_Tin_soft[i][j]));
            end
        end
    


    for(int i=0;i<`Height;i++)
        for(int j=0;j<`slice_of_Wout;j++)
            for(int k=0;k<`Tout;k++)
            begin
//                $display("dat_out_software[%0d][%0d]=%0d",i,j*`Tout+k,$signed(Out_Feature_soft[i][j*`Tout+k]));
                if(Out_Feature_soft[i][j*`Tout+k]!=Out_Feature_TinTout_soft[i][j][k*`MAX_DW+:`MAX_DW])
                begin
                    flag1=0;
                    $display("error! dat_out_software_Tin[%0d][%0d]=%0d, dat_out_software=%0d",i,j,
                                $signed(Out_Feature_soft[i][j*`Tout+k]), $signed(Out_Feature_TinTout_soft[i][j][k*`MAX_DW+:`MAX_DW]));
                end
            end
            
            
    if(flag0==1)
        $display("\n==================================\n\t software_Tin result match \n==================================");
    else
        $display("\n==================================\n\t software_Tin result mismatch \n==================================");

    if(flag1==1)
        $display("\n==================================\n\t software_TinTout result match \n==================================");
    else
        $display("\n==================================\n\t software_TinTout result mismatch \n==================================");
    
end

`ifdef FSDB
initial begin
    $fsdbDumpfile("new.fsdb");
    $fsdbDumpvars;
end
`endif

initial
begin
    height=`Height;
    Win_div_Tin=`slice_of_Win;
    Wout_div_Tout=`slice_of_Wout;
end


initial
begin

    for(int k=0;k<`slice_of_Wout;k=k+1)
        for(int j=0;j<`slice_of_Win;j=j+1)
            for(int i=0;i<`Height;i=i+1)
            begin
                In_Feature_Expand_in_DDR[j][i]=In_Feature_Expand[i][j];
                u_Input_Memory.memory[DDR_input_feature_addr]=In_Feature_Expand_in_DDR[j][i];
                DDR_input_feature_addr = DDR_input_feature_addr + 1;
            end 
            
    DDR_wt_addr=0;
    for(int j=0;j<`slice_of_Wout;j=j+1)
        for(int i=0;i<`slice_of_Win;i=i+1)
            for(int k=0;k<`Height;k=k+1)
            begin
                Weight_Expand_TinTout_in_DDR[j][i]=Weight_Expand_TinTout[i][j];
                u_Weight_Memory.memory[DDR_wt_addr]=Weight_Expand_TinTout_in_DDR[j][i];
                DDR_wt_addr = DDR_wt_addr + 1;
            end 
end

always #(`clk_period/2) clk=~clk;
initial begin

    #(`clk_period) rst_n=0;clk=0;input_start=0;wt_start=0;
    #(`clk_period+`clk_period/2) rst_n=1;
repeat(1) begin
    #(`clk_period) wt_start=1;input_start=1;
    #(`clk_period) wt_start=0;input_start=0;
    
    #(`clk_period*`Height*`slice_of_Win*`slice_of_Wout + 200)
    begin
    DDR_output_feature_addr=0;
    for(int i=0;i<`slice_of_Wout;i=i+1)
        for(int j=0;j<`Height;j=j+1)
        begin
            Out_Feature_hardware[i][j]=u_Output_Memory.memory[DDR_output_feature_addr];
            DDR_output_feature_addr = DDR_output_feature_addr + 1;
        end 



    for(int i=0;i<`Height;i++)
        for(int j=0;j<`slice_of_Wout;j++)
            for(int k=0;k<`Tout;k++)
            begin
                $display("dat_out_software[%0d][%0d]=%0d",i,j*`Tout+k,$signed(Out_Feature_soft[i][j*`Tout+k]));
                if(Out_Feature_soft[i][j*`Tout+k]!=Out_Feature_hardware[j][i][k*`MAX_DW+:`MAX_DW])
                begin
                    flag2=0;
                    $display("error! dat_out_software[%0d][%0d]=%0d, Out_Feature_hardware=%0d",i,j,
                                $signed(Out_Feature_soft[i][j*`Tout+k]), $signed(Out_Feature_hardware[j][i][k*`MAX_DW+:`MAX_DW]));
                end
            end
            
            
    if(flag2==1)
        $display("\n==================================\n\t hardware result match \n==================================");
    else
        $display("\n==================================\n\t hardware result mismatch \n==================================");
end
    if(flag2==1)
        #(`clk_period) $finish;
    else
        #(`clk_period) $finish;
end
end

initial
begin
    if(`Acc_Height_Num<`Width_in)
    begin
        $display("Width_in too large, should be smaller than `Acc_Height_Num! \n");
        #1 $finish;
    end

#100000000 $finish;
end


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


Memory_IN #
(
    .WIDTH( `MAX_DW*`Tin ),
    .DEPTH( `Height*`slice_of_Win*`slice_of_Wout ),         //Ϊ����memory_out����һ�£�
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


endmodule
