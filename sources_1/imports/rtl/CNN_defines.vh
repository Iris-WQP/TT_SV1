`define log2_S 5
`define log2_Width_max 10
`define log2_Height_max 10

`define MAX_DW    8               // datawidth
`define MAX_log2DW   3

`define MAX_DW2 (`MAX_DW*2)

`define Tin 16
`define log2_Tin 4

`define Tout 16
`define log2_Tout 3

`define Acc_Delay 4
`define Acc_Height_Num 256
`define Tin_Acc_Delay `log2_Tin


`define Height 1           //��ͷ������256
`define Width_in  256        //�����������
`define Width_out 256         //�����չ����
//TinΪ���벢�жȣ�slice of Win Ϊ����Ĵ���
`define slice_of_Win ((`Width_in+`Tin-1)/`Tin)
`define slice_of_Wout ((`Width_out+`Tout-1)/`Tout)//����Ĵ���

`define in_scale 0
`define wt_scale 0
`define out_scale 0
`define shift (`in_scale+`wt_scale-`out_scale)
`define Pixel_Data_Bytes ((`Tout*`MAX_DAT_DW)>>3)  
`define log2_CH 16
`define MAX_DAT_DW `MAX_DW

`define clk_period 2