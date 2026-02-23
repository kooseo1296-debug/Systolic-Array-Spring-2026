`include "param.v"

module pe(
    input CLK,
    input [`BIT_ROW_ID-1:0] Row_ID,
    input signed [`BIT_DATA-1:0] Data_I_In, Data_W_In,
    output reg signed [`BIT_DATA-1:0] Data_I_Out, Data_W_Out,
    input EN_W_In,
    output reg EN_W_Out,
    input [`BIT_ROW_ID-1:0] EN_ID_In,
    output reg [`BIT_ROW_ID-1:0] EN_ID_Out,
    input signed [`BIT_PSUM-1:0] Psum_In,
    output signed [`BIT_PSUM-1:0] Psum_Out,

    input [`BIT_ADDR-1:0]   Addr_P_In,
    input [`BIT_VALID-1:0]  Valid_P_In,
    output reg [`BIT_ADDR-1:0]   Addr_P_Out,
    output reg [`BIT_VALID-1:0]  Valid_P_Out,
    
    input ZeroFlag_In,
    output reg ZeroFlag_Out
    );


reg signed [`BIT_DATA-1:0] Data_W_Buf;

wire Do_Compute;
wire Do_Compute_1;
reg signed [`BIT_PSUM-1:0] Psum_Uncomputed;
reg signed [`BIT_DATA-1:0] Data_I_Compute;
wire signed [`BIT_PSUM-1:0] Psum_Computed;

assign Do_Compute = (~ZeroFlag_In) & Valid_P_In & (Data_W_Buf != `BIT_DATA'd0);
assign Do_Compute_1 = (~ZeroFlag_Out) & Valid_P_Out & (Data_W_Buf != `BIT_DATA'd0);
assign Psum_Computed = Data_I_Compute*Data_W_Buf + Psum_Uncomputed;
assign Psum_Out = (Do_Compute_1)? Psum_Computed : Psum_Uncomputed;


always @(posedge CLK) begin
    Data_I_Out <= Data_I_In;
    Data_W_Out <= Data_W_In;
    EN_W_Out <= EN_W_In;
    EN_ID_Out <= EN_ID_In;
    Addr_P_Out <= Addr_P_In;
    Valid_P_Out <= Valid_P_In;
    
    ZeroFlag_Out <= ZeroFlag_In;
    
    if (Do_Compute) Data_I_Compute <= Data_I_In;
    if (Valid_P_In) Psum_Uncomputed <= Psum_In;
    
    if (EN_W_In & (EN_ID_In == Row_ID)) Data_W_Buf <= Data_W_In;
    

end

endmodule


