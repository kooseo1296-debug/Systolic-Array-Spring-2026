`include "./param.v"


module dffq #(parameter WIDTH=`BIT_DATA) (
input CLK,
input RST,
input [WIDTH-1:0] D,
output reg [WIDTH-1:0] Q
);
always @(posedge CLK) begin
    if (RST) Q <= {WIDTH{1'b0}};
    else Q <= D;
end
endmodule