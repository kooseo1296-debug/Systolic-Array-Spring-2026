`include "param.v"

module top (
    input                       CLK,
    input                       RSTb,
    input  [`BIT_INSTR-1:0]     Instr,         // [31:0] Instr_in [cite: 4]
    output                      Flag_Finish_Out,  // Out_FinishFlag [cite: 9]
    output                      o_Valid_WB_Out,     // Out_ValidWriteBack [cite: 9]
    output [`BIT_PSUM-1:0]      o_Data_WB_Out/*,       // [31:0] Out_DataWriteBack 
    
    output [17*3-1:0] Debug_FeedBack*/
    );
    // Internal Reset Logic
    wire RST = ~RSTb;
    genvar i;
// --- Wire Declarations Sorted by Number -------------------
    //1
    wire [`PE_COL-1:0]          ena_WeightSRAM;
    wire [`PE_COL-1:0]          wea_WeightSRAM;
    wire [(`BIT_SPSRAM*`PE_COL)-1:0] addra_WeightSRAM;
    wire [(`BIT_DATA*`PE_COL)-1:0] dina_WeightSRAM;
    //1-1 Simplify dina and addra
    wire [`BIT_SPSRAM-1:0] addra_WeightSRAM_1;
    wire [`BIT_DATA-1:0] dina_WeightSRAM_1;
    generate
    for (i=0;i<`PE_COL;i=i+1) begin
        assign addra_WeightSRAM[i*`BIT_SPSRAM+:`BIT_SPSRAM] = addra_WeightSRAM_1;
        assign dina_WeightSRAM[i*`BIT_DATA+:`BIT_DATA] = dina_WeightSRAM_1;
    end
    endgenerate
    
    //2
    wire [`PE_COL-1:0]          ena_PsumSRAM;
    wire [`PE_COL-1:0]          enb_PsumSRAM;
    wire [(`BIT_DPSRAM*`PE_COL)-1:0] addrb_PsumSRAM;
    //2-1:Piplining DFFQs
    wire [`PE_COL-1:0]          enb_PsumSRAM_1;
    wire [(`BIT_DPSRAM*`PE_COL)-1:0] addrb_PsumSRAM_1;
    
    //3
    wire [`PE_COL-1:0]          Valid_SysDffq;
    wire [(`BIT_ADDR*`PE_COL)-1:0] addrP_SysDffq;
    wire [(`BIT_ROW_ID*`PE_COL)-1:0] EnID_SysDffq;
    wire [`PE_COL-1:0]          EnWeight_SysDffq;
    
    //4
    wire [(`BIT_PSUM*`PE_COL)-1:0] doutb_PsumSRAM;
    //4-1: Pipelining DFFQ
    wire [(`BIT_PSUM*`PE_COL)-1:0] doutb_PsumSRAM_1;
    
    //5
    wire [`PE_ROW-1:0]          ena_InputSRAM;
    wire [`PE_ROW-1:0]          wea_InputSRAM;
    wire [(`BIT_DATA*`PE_ROW)-1:0] dina_InputSRAM;
    wire [(`BIT_SPSRAM*`PE_ROW)-1:0] addra_InputSRAM;
    wire [`PE_ROW-1:0]          Disable_ZeroMaskDffq;
    wire [`PE_ROW-1:0]          Disable_ZeroMask;
    wire [`PE_COL-1:0]          enable_PsumLoader;
    //5-1 pipelining DFFQ, Simplify dina and addra
    wire [`PE_COL-1:0]          enable_PsumLoader_1;
    wire [`BIT_DATA-1:0] dina_InputSRAM_1;
    wire [`BIT_SPSRAM-1:0] addra_InputSRAM_1;
    generate
    for(i=0;i<`PE_ROW;i=i+1) begin
        assign dina_InputSRAM[i*`BIT_DATA+:`BIT_DATA] = dina_InputSRAM_1;
        assign addra_InputSRAM[i*`BIT_SPSRAM+:`BIT_SPSRAM] = addra_InputSRAM_1;
    end
    endgenerate
    
    //6
    wire [(`BIT_DATA*`PE_ROW)-1:0] InputSRAM_to_ZeroMask;
    
    //7
    wire [(`BIT_DATA*`PE_ROW)-1:0] ZeroMask_to_InputLoader;
    
    //8
    wire [(`BIT_DATA*`PE_ROW)-1:0] InputLoader_to_SysArr;
    
    //9
    wire [(`PE_COL*`BIT_PSUM)-1:0] SysArr_Psum;
    wire [(`PE_COL*`BIT_ADDR)-1:0] SysArr_Addr;
    wire [`PE_COL-1:0]             SysArr_ValidP;
    
    //10
    wire [(`BIT_DATA*`PE_COL)-1:0]      douta_WeightSRAM;
    wire [(`PE_COL*`BIT_PSUM)-1:0]      PsumLoader_to_SysArr;
    wire [`PE_COL-1:0]                  SysDffq_EnWeight;
    wire [(`PE_COL*`BIT_ROW_ID)-1:0]    SysDffq_EnID;
    wire [(`PE_COL*`BIT_ADDR)-1:0]      SysDffq_addrP;
    wire [`PE_COL-1:0]                  SysDffq_Valid;
    
    //11: 2-stage DFFQs
    wire [`PE_COL*`BIT_ADDR-1:0] addrP_SysDffq_1;
    wire [`PE_COL-1:0] Valid_SysDffq_1;
    
    //0: pipeline_0
    wire [`PE_COL-1:0] wea_WeightSRAM_0;
    wire [`PE_COL-1:0] ena_WeightSRAM_0;
    wire [`BIT_DATA-1:0] dina_WeightSRAM_0;
    wire [`BIT_SPSRAM-1:0] addra_WeightSRAM_0;
    wire [`PE_ROW-1:0] wea_InputSRAM_0;
    wire [`PE_ROW-1:0] ena_InputSRAM_0;
    wire [`BIT_DATA-1:0] dina_InputSRAM_0;
    wire [`BIT_SPSRAM-1:0] addra_InputSRAM_0;
    wire [(`BIT_PSUM*`PE_COL)-1:0] doutb_PsumSRAM_0;
    wire [`PE_ROW-1:0]          Disable_ZeroMask_0;
    wire [`PE_COL-1:0]          enable_PsumLoader_0;
    wire [`PE_COL-1:0]          ena_PsumSRAM_0;
    wire [`PE_COL-1:0]          enb_PsumSRAM_0;
    wire [(`BIT_DPSRAM*`PE_COL)-1:0] addrb_PsumSRAM_0;
    
    wire [`PE_COL*`BIT_ADDR-1:0] addrP_SysDffq_0;
    wire [`PE_COL-1:0] Valid_SysDffq_0;
    wire [`PE_COL-1:0] SysDffq_EnWeight_0;
    wire [(`PE_COL*`BIT_ROW_ID)-1:0] SysDffq_EnID_0;
    
    wire [(`PE_COL*`BIT_PSUM)-1:0] SysArr_Psum_0;
    wire [(`PE_COL*`BIT_ADDR)-1:0] SysArr_Addr_0;
    wire [`PE_COL-1:0]             SysArr_ValidP_0;
//-------------------------------------------------------------------    


//dffq---------------------------------------------------------------    
dffq #(`PE_COL) dffq_EnWeight (//2-stage
    .CLK(CLK),
    .RST(RST),
    .D(EnWeight_SysDffq),
    .Q(SysDffq_EnWeight_0)
);
dffq #(`PE_COL) dffq_EnWeight_0 (
    .CLK(CLK),
    .RST(RST),
    .D(SysDffq_EnWeight_0),
    .Q(SysDffq_EnWeight)
);

dffq #(`PE_COL*`BIT_ROW_ID) dffq_EnID (//2-stage
    .CLK(CLK),
    .RST(RST),
    .D(EnID_SysDffq),
    .Q(SysDffq_EnID_0)
);
dffq #(`PE_COL*`BIT_ROW_ID) dffq_EnID_0 (
    .CLK(CLK),
    .RST(RST),
    .D(SysDffq_EnID_0),
    .Q(SysDffq_EnID)
);


dffq #(`PE_COL*`BIT_ADDR) dffq_AddrP (//3-stage
    .CLK(CLK),
    .RST(RST),
    .D(addrP_SysDffq),
    .Q(addrP_SysDffq_0)
);
dffq #(`PE_COL*`BIT_ADDR) dffq_AddrP_0 (
    .CLK(CLK),
    .RST(RST),
    .D(addrP_SysDffq_0),
    .Q(addrP_SysDffq_1)
);
dffq #(`PE_COL*`BIT_ADDR) dffq_AddrP_1 (
    .CLK(CLK),
    .RST(RST),
    .D(addrP_SysDffq_1),
    .Q(SysDffq_addrP)
);

dffq #(`PE_COL) dffq_ValidP (//3-stage
    .CLK(CLK),
    .RST(RST),
    .D(Valid_SysDffq),
    .Q(Valid_SysDffq_0)
);
dffq #(`PE_COL) dffq_ValidP_0 (
    .CLK(CLK),
    .RST(RST),
    .D(Valid_SysDffq_0),
    .Q(Valid_SysDffq_1)
);
dffq #(`PE_COL) dffq_ValidP_1 (
    .CLK(CLK),
    .RST(RST),
    .D(Valid_SysDffq_1),
    .Q(SysDffq_Valid)
);

dffq #(`PE_ROW) dffq_ZeroMask (
    .CLK(CLK),
    .RST(RST),
    .D(Disable_ZeroMaskDffq),
    .Q(Disable_ZeroMask_0)
);

//pipeline WB------------------------------------------
dffq #(`PE_COL) dffq_pipeline_enb (
    .CLK(CLK),
    .RST(RST),
    .D(enb_PsumSRAM),
    .Q(enb_PsumSRAM_0)
);
dffq #(`PE_COL) dffq_pipeline_enb_0 (
    .CLK(CLK),
    .RST(RST),
    .D(enb_PsumSRAM_0),
    .Q(enb_PsumSRAM_1)
);

dffq #(`BIT_DPSRAM*`PE_COL) dffq_pipeline_addrb (
    .CLK(CLK),
    .RST(RST),
    .D(addrb_PsumSRAM),
    .Q(addrb_PsumSRAM_0)
);
dffq #(`BIT_DPSRAM*`PE_COL) dffq_pipeline_addrb_0 (
    .CLK(CLK),
    .RST(RST),
    .D(addrb_PsumSRAM_0),
    .Q(addrb_PsumSRAM_1)
);

dffq #(`BIT_PSUM*`PE_COL) dffq_pipeline_feedback (
    .CLK(CLK),
    .RST(RST),
    .D(doutb_PsumSRAM_0),
    .Q(doutb_PsumSRAM_1)
);

dffq #(`PE_COL) dffq_pipeline_PsumLoader (
    .CLK(CLK),
    .RST(RST),
    .D(enable_PsumLoader),
    .Q(enable_PsumLoader_0)
);
//pipeline InputSRAM-----------------------------------
dffq #(`PE_ROW) dffq_pipeline_wea_I (
    .CLK(CLK),
    .RST(RST),
    .D(wea_InputSRAM_0),
    .Q(wea_InputSRAM)
);
dffq #(`PE_ROW) dffq_pipeline_ena_I (
    .CLK(CLK),
    .RST(RST),
    .D(ena_InputSRAM_0),
    .Q(ena_InputSRAM)
);
dffq #(`BIT_DATA) dffq_pipeline_dina_I (
    .CLK(CLK),
    .RST(RST),
    .D(dina_InputSRAM_0),
    .Q(dina_InputSRAM_1)
);
dffq #(`BIT_SPSRAM) dffq_pipeline_addra_I (
    .CLK(CLK),
    .RST(RST),
    .D(addra_InputSRAM_0),
    .Q(addra_InputSRAM_1)
);
//pipeline WeightSRAM----------------------------------
dffq #(`PE_ROW) dffq_pipeline_wea_W (
    .CLK(CLK),
    .RST(RST),
    .D(wea_WeightSRAM_0),
    .Q(wea_WeightSRAM)
);

dffq #(`PE_ROW) dffq_pipeline_ena_W (
    .CLK(CLK),
    .RST(RST),
    .D(ena_WeightSRAM_0),
    .Q(ena_WeightSRAM)
);

dffq #(`BIT_DATA) dffq_pipeline_dina_W (
    .CLK(CLK),
    .RST(RST),
    .D(dina_WeightSRAM_0),
    .Q(dina_WeightSRAM_1)
);

dffq #(`BIT_SPSRAM) dffq_pipeline_addra_W (
    .CLK(CLK),
    .RST(RST),
    .D(addra_WeightSRAM_0),
    .Q(addra_WeightSRAM_1)
);
//pipeline ZeroMask_disable, feedback, psumloader_enable
dffq #(`PE_ROW) dffq_ZeroMask_0 (
    .CLK(CLK),
    .RST(RST),
    .D(Disable_ZeroMask_0),
    .Q(Disable_ZeroMask)
);

dffq #(`BIT_PSUM*`PE_COL) dffq_pipeline_feedback_0 (
    .CLK(CLK),
    .RST(RST),
    .D(doutb_PsumSRAM),
    .Q(doutb_PsumSRAM_0)
);

dffq #(`PE_COL) dffq_pipeline_PsumLoader_0 (
    .CLK(CLK),
    .RST(RST),
    .D(enable_PsumLoader_0),
    .Q(enable_PsumLoader_1)
);
//pipeline PsumSRAM_ena------------------------------------
dffq #(`PE_COL) dffq_pipeline_ena_P (
    .CLK(CLK),
    .RST(RST),
    .D(ena_PsumSRAM_0),
    .Q(ena_PsumSRAM)
);
//pipeline PsumSRAM----------------------------------------
dffq #(`PE_COL*`BIT_PSUM) dffq_pipeline_SysArrPsum (
    .CLK(CLK),
    .RST(RST),
    .D(SysArr_Psum_0),
    .Q(SysArr_Psum)
);

dffq #(`PE_COL*`BIT_ADDR) dffq_pipeline_SysArrAddr (
    .CLK(CLK),
    .RST(RST),
    .D(SysArr_Addr_0),
    .Q(SysArr_Addr)
);

dffq #(`PE_COL*`BIT_ADDR) dffq_pipeline_SysArrValid (
    .CLK(CLK),
    .RST(RST),
    .D(SysArr_ValidP_0),
    .Q(SysArr_ValidP)
);
//-------------------------------------------------------------------

systolic_ctrl systolic_ctrl (
    //Global Input&Outputs
    .CLK(CLK),
    .RST(RST),
    .Instr_In_In(Instr),    //[31:0]
    .Out_FinishFlag(Flag_Finish_Out),
    .Out_ValidWriteBack(o_Valid_WB_Out),
    .Out_DataWriteBack(o_Data_WB_Out),   //[23:0]
    //Outputs to Weight SRAMs
    .Out_ena_WeightSRAM(ena_WeightSRAM_0),    //[3:0]
    .Out_wea_WeightSRAM(wea_WeightSRAM_0),    //[3:0]
    .Out_dina_WeightSRAM(dina_WeightSRAM_0),   //[31:0]
    .Out_addra_WeightSRAM(addra_WeightSRAM_0),    //[59:0]
    //Outputs to Dffqs in front of Systolic Array
    .Out_Valid_SysDffq(Valid_SysDffq), //[3:0]
    .Out_addrP_SysDffq(addrP_SysDffq),  //[63:0]
    .Out_EnID_SysDffq(EnID_SysDffq),  //[15:0]
    .Out_EnWeight_SysDffq(EnWeight_SysDffq),  //[3:0]
    //Outputs to Psum SRAMs (Dual Port)
    .Out_addrb_PsumSRAM(addrb_PsumSRAM),  //[27:0]
    .Out_ena_PsumSRAM(ena_PsumSRAM_0),  //[3:0]
    .Out_enb_PsumSRAM(enb_PsumSRAM),  //[3:0]
    //Outputs to Input SRAMs
    .Out_wea_InputSRAM(wea_InputSRAM_0), //[7:0]
    .Out_ena_InputSRAM(ena_InputSRAM_0), //[7:0]
    .Out_dina_InputSRAM(dina_InputSRAM_0), //[63:0]
    .Out_addra_InputSRAM(addra_InputSRAM_0), //[119:0]
    //Zero Mask
    .Out_Disable_ZeroMask(Disable_ZeroMaskDffq),    //[7:0]
    //Output to PsumLoader
    .Out_enable_PsumLoader(enable_PsumLoader), //[3:0]
    //Feedbacks
    .PsumSRAM_doutb_In(doutb_PsumSRAM_1) //[95:0]
    );

systolic systolic ( 
    .CLK(CLK), 
    .i_Data_I_In(InputLoader_to_SysArr), 
    .i_Data_W_In(douta_WeightSRAM), 
    .i_EN_W_In(SysDffq_EnWeight), 
    .i_EN_ID_In(SysDffq_EnID), 
    .i_Psum_In(PsumLoader_to_SysArr), 
    .o_Psum_Out(SysArr_Psum_0),
    .i_Addr_P_In(SysDffq_addrP), 
    .i_Valid_P_In(SysDffq_Valid), 
    .o_Addr_P_Out(SysArr_Addr_0), 
    .o_Valid_P_Out(SysArr_ValidP_0)
    );

generate for (i=0;i<`PE_ROW;i=i+1) begin: Loop_I
    blk_mem_gen_0_sp   InputSRAM (
        .addra(addra_InputSRAM[i*`BIT_SPSRAM+:`BIT_SPSRAM]),
        .clka(CLK),
        .dina(dina_InputSRAM[i*`BIT_DATA+:`BIT_DATA]),
        .douta(InputSRAM_to_ZeroMask[i*`BIT_DATA+:`BIT_DATA]),
        .ena(ena_InputSRAM[i]),
        .wea(wea_InputSRAM[i])
        );
    ZeroMask ZeroMask(
        .Input(InputSRAM_to_ZeroMask[i*`BIT_DATA+:`BIT_DATA]),
        .Disable(Disable_ZeroMask[i]),
        .Output(ZeroMask_to_InputLoader[i*`BIT_DATA+:`BIT_DATA])
        );
end
endgenerate

generate for (i=0;i<`PE_COL;i=i+1) begin: Loop_W
    blk_mem_gen_0_sp   WeightSRAM (
        .addra(addra_WeightSRAM[i*`BIT_SPSRAM+:`BIT_SPSRAM]),
        .clka(CLK),
        .dina(dina_WeightSRAM[i*`BIT_DATA+:`BIT_DATA]),
        .douta(douta_WeightSRAM[i*`BIT_DATA+:`BIT_DATA]),
        .ena(ena_WeightSRAM[i]),
        .wea(wea_WeightSRAM[i])
        );
    blk_mem_gen_1_dp PsumSRAM (
        .addra(SysArr_Addr[i*`BIT_ADDR+:`BIT_DPSRAM]),
        .clka(CLK),
        .dina(SysArr_Psum[i*`BIT_PSUM+:`BIT_PSUM]),
        .ena(ena_PsumSRAM[i]),
        .wea(SysArr_ValidP[i]),
        
        .addrb(addrb_PsumSRAM_1[i*`BIT_DPSRAM+:`BIT_DPSRAM]),
        .clkb(CLK),
        .doutb(doutb_PsumSRAM[i*`BIT_PSUM+:`BIT_PSUM]),
        .enb(enb_PsumSRAM_1[i])
        );
end
endgenerate

systolic_loader_p PsumLoader (
    .enable(enable_PsumLoader_1),
    .doutb_In(doutb_PsumSRAM),
    .Psum_Out(PsumLoader_to_SysArr)
    );

systolic_loader_i InputLoader (
    .CLK(CLK),
    .i_Data_I_In(ZeroMask_to_InputLoader),
    .o_Data_I_In(InputLoader_to_SysArr)
    );

endmodule




