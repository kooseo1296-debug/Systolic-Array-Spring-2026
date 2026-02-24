`include "param.v"

module ZeroMask (
    input [`BIT_DATA-1:0] Input,
    input Disable,
    output [`BIT_DATA-1:0] Output
);

assign Output = (Disable) ? Input : `BIT_DATA'd0;

endmodule
