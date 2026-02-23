`include "param.v"

module ZeroDetect(
    input [`BIT_DATA-1:0] Input,
    output ZeroFlag
    );
    
assign ZeroFlag = (Input == `BIT_DATA'd0);
    
endmodule
