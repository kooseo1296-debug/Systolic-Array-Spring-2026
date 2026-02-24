`include "param.v"

module systolic_loader_p (
    input [`PE_COL-1:0]enable,   // From Controller: 1 for accumulation, 0 for first tile
    input [`PE_COL*`BIT_PSUM-1:0] doutb_In,
    output [`PE_COL*`BIT_PSUM-1:0] Psum_Out
);


genvar j;
generate for (j=0;j<`PE_COL;j=j+1) begin
    assign Psum_Out[j*`BIT_PSUM +: `BIT_PSUM] = enable[j] ? doutb_In[j*`BIT_PSUM +: `BIT_PSUM] : `BIT_PSUM'd0;
end
endgenerate

endmodule