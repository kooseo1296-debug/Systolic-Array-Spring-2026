`include "param.v"

module systolic_loader_i(
    input CLK,
    input  [`PE_ROW*`BIT_DATA-1:0] i_Data_I_In,
    output [`PE_ROW*`BIT_DATA-1:0] o_Data_I_In
);

    genvar i, j;
    generate
        for (i = 0; i < `PE_ROW; i = i + 1) begin : Delay_Row
            reg [`BIT_DATA-1:0] delay_regs [i:0];

            always @(posedge CLK) begin
                delay_regs[i] <= i_Data_I_In[i*`BIT_DATA +: `BIT_DATA];
            end

            if (i > 0) begin
                for (j = 0; j < i; j = j + 1) begin : Shift
                    always @(posedge CLK) begin
                        delay_regs[j] <= delay_regs[j+1];
                    end
                end
            end

            assign o_Data_I_In[i*`BIT_DATA +: `BIT_DATA] = delay_regs[0];
        end
    endgenerate

endmodule