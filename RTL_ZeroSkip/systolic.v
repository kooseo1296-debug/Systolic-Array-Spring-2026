`include "param.v"

module systolic ( CLK, i_Data_I_In, i_Data_W_In, i_EN_W_In, i_EN_ID_In, i_Psum_In, o_Psum_Out,
                  i_Addr_P_In, i_Valid_P_In, o_Addr_P_Out, o_Valid_P_Out,
                  i_ZeroFlag_In);
input CLK;
input [`PE_ROW*`BIT_DATA-1:0] i_Data_I_In;
input [`PE_COL*`BIT_DATA-1:0] i_Data_W_In;
input [`PE_COL-1:0] i_EN_W_In;
input [`BIT_ROW_ID-1:0] i_EN_ID_In;
input [`PE_COL*`BIT_PSUM-1:0] i_Psum_In;
output [`PE_COL*`BIT_PSUM-1:0] o_Psum_Out;

input  [`PE_COL*`BIT_ADDR-1:0] i_Addr_P_In;
input  [`PE_COL*`BIT_VALID-1:0] i_Valid_P_In;
output [`PE_COL*`BIT_ADDR-1:0] o_Addr_P_Out;
output [`PE_COL*`BIT_VALID-1:0] o_Valid_P_Out;
//Zero-Skip-------------------------------------------------------
input [`PE_ROW-1:0] i_ZeroFlag_In;
//----------------------------------------------------------------
wire [`PE_COL*`PE_ROW*`BIT_DATA-1:0] Data_I_In;
wire [`PE_COL*`PE_ROW*`BIT_DATA-1:0] Data_I_Out;
wire [`PE_COL*`PE_ROW*`BIT_DATA-1:0] Data_W_In;
wire [`PE_COL*`PE_ROW*`BIT_DATA-1:0] Data_W_Out;
wire [`PE_COL*`PE_ROW-1:0] EN_W_In;
wire [`PE_COL*`PE_ROW-1:0] EN_W_Out;
wire [`PE_COL*`PE_ROW*`BIT_ROW_ID-1:0] EN_ID_In;
wire [`PE_COL*`PE_ROW*`BIT_ROW_ID-1:0] EN_ID_Out;
wire [`PE_COL*`PE_ROW*`BIT_PSUM-1:0] Psum_In;
wire [`PE_COL*`PE_ROW*`BIT_PSUM-1:0] Psum_Out;

wire [`PE_COL*`PE_ROW*`BIT_ADDR-1:0] Addr_P_In;
wire [`PE_COL*`PE_ROW*`BIT_VALID-1:0] Valid_P_In;
wire [`PE_COL*`PE_ROW*`BIT_ADDR-1:0] Addr_P_Out;
wire [`PE_COL*`PE_ROW*`BIT_VALID-1:0] Valid_P_Out;
//Zero-Skip--------------------------------------------------------
wire [`PE_COL*`PE_ROW-1:0] ZeroFlag_In;
wire [`PE_COL*`PE_ROW-1:0] ZeroFlag_Out;
//-----------------------------------------------------------------
genvar i, j;//Col Number i, Row Number j
generate
    for(i=0;i<`PE_COL;i=i+1) begin: loop_pe_col
        assign o_Addr_P_Out[`BIT_ADDR*i+:`BIT_ADDR] = Addr_P_Out[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*(`PE_ROW-1)+:`BIT_ADDR];
        assign o_Valid_P_Out[`BIT_VALID*i+:`BIT_VALID] = Valid_P_Out[`BIT_VALID*i+`BIT_VALID*`PE_COL*(`PE_ROW-1)+:`BIT_VALID];
        assign o_Psum_Out[`BIT_PSUM*i+:`BIT_PSUM] = Psum_Out[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*(`PE_ROW-1)+:`BIT_PSUM];
        for (j=0;j<`PE_ROW;j=j+1) begin: loop_pe_row
            pe pe ( .CLK(CLK),
                    .Row_ID(j),
                    .Data_I_In(Data_I_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA]),
                    .Data_I_Out(Data_I_Out[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA]),
                    .Data_W_In(Data_W_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA]),
                    .Data_W_Out(Data_W_Out[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA]),
                    
                    .EN_W_In(EN_W_In[i+`PE_COL*j]),
                    .EN_W_Out(EN_W_Out[i+`PE_COL*j]),
                    .EN_ID_In(EN_ID_In[`BIT_ROW_ID*i+`BIT_ROW_ID*`PE_COL*j+:`BIT_ROW_ID]),
                    .EN_ID_Out(EN_ID_Out[`BIT_ROW_ID*i+`BIT_ROW_ID*`PE_COL*j+:`BIT_ROW_ID]),
                    .Psum_In(Psum_In[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*j+:`BIT_PSUM]),
                    .Psum_Out(Psum_Out[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*j+:`BIT_PSUM]),
                    .Addr_P_In(Addr_P_In[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*j+:`BIT_ADDR]),
                    .Valid_P_In(Valid_P_In[`BIT_VALID*i+`BIT_VALID*`PE_COL*j+:`BIT_VALID]),
                    .Addr_P_Out(Addr_P_Out[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*j+:`BIT_ADDR]),
                    .Valid_P_Out(Valid_P_Out[`BIT_VALID*i+`BIT_VALID*`PE_COL*j+:`BIT_VALID]),
                    
                    //Zero-Skip--------------------------------------------------------------------------------------------------------------------------
                    .ZeroFlag_In(ZeroFlag_In[i+`PE_COL*j]),
                    .ZeroFlag_Out(ZeroFlag_Out[i+`PE_COL*j])
                    //-----------------------------------------------------------------------------------------------------------------------------------
                );                
                
                if(j>0) begin
                    assign Data_W_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA] = Data_W_Out[`BIT_DATA*i+`BIT_DATA*`PE_COL*(j-1)+:`BIT_DATA];
                    assign EN_W_In[i+`PE_COL*j] = EN_W_Out[i+`PE_COL*(j-1)];
                    assign EN_ID_In[`BIT_ROW_ID*i+`BIT_ROW_ID*`PE_COL*j+:`BIT_ROW_ID] = EN_ID_Out[`BIT_ROW_ID*i+`BIT_ROW_ID*`PE_COL*(j-1)+:`BIT_ROW_ID];
                    assign Psum_In[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*j+:`BIT_PSUM] = Psum_Out[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*(j-1)+:`BIT_PSUM];
                    assign Addr_P_In[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*j+:`BIT_ADDR] = Addr_P_Out[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*(j-1)+:`BIT_ADDR];
                    assign Valid_P_In[`BIT_VALID*i+`BIT_VALID*`PE_COL*j+:`BIT_VALID] = Valid_P_Out[`BIT_VALID*i+`BIT_VALID*`PE_COL*(j-1)+:`BIT_VALID];
                end
                else begin
                    assign Data_W_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA] = i_Data_W_In[`BIT_DATA*i+:`BIT_DATA];
                    assign EN_W_In[i+`PE_COL*j] = i_EN_W_In[i];
                    assign EN_ID_In[`BIT_ROW_ID*i+`BIT_ROW_ID*`PE_COL*j+:`BIT_ROW_ID] = i_EN_ID_In[`BIT_ROW_ID*0+:`BIT_ROW_ID];
                    assign Psum_In[`BIT_PSUM*i+`BIT_PSUM*`PE_COL*j+:`BIT_PSUM] = i_Psum_In[`BIT_PSUM*i+:`BIT_PSUM];
                    assign Addr_P_In[`BIT_ADDR*i+`BIT_ADDR*`PE_COL*j+:`BIT_ADDR] = i_Addr_P_In[`BIT_ADDR*i+:`BIT_ADDR];
                    assign Valid_P_In[`BIT_VALID*i+`BIT_VALID*`PE_COL*j+:`BIT_VALID] = i_Valid_P_In[`BIT_VALID*i+:`BIT_VALID];
                end
                
                if(i>0) begin
                    assign Data_I_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA] = Data_I_Out[`BIT_DATA*(i-1)+`BIT_DATA*`PE_COL*j+:`BIT_DATA];
                    //Zero-Skip----------------------------------------------------------------------------------------------------------------------------
                    assign ZeroFlag_In[i+`PE_COL*j] = ZeroFlag_Out[(i-1)+`PE_COL*j];
                    //-------------------------------------------------------------------------------------------------------------------------------------
                end
                else begin
                    assign Data_I_In[`BIT_DATA*i+`BIT_DATA*`PE_COL*j+:`BIT_DATA] = i_Data_I_In[`BIT_DATA*j+:`BIT_DATA];
                    //Zero-Skip----------------------------------------------------------------------------------------------------------------------------
                    assign ZeroFlag_In[i+`PE_COL*j] = i_ZeroFlag_In[j];
                    //-------------------------------------------------------------------------------------------------------------------------------------
                end
             end
          end
endgenerate

endmodule


