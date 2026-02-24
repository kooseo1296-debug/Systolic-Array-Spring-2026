`include "param.v"

module systolic_ctrl (
    
    //Global Input&Outputs
    input CLK,
    input RST,
    input [`BIT_INSTR-1:0] Instr_In_In,    //[31:0]
    output Out_FinishFlag,
    output reg Out_ValidWriteBack,
    output reg [`BIT_PSUM-1:0] Out_DataWriteBack,   //[23:0]
    
    //Outputs to Weight SRAMs
    output reg [`PE_COL-1:0] Out_ena_WeightSRAM,    //[3:0]
    output reg [`PE_COL-1:0] Out_wea_WeightSRAM,    //[3:0]
    output reg [`BIT_DATA-1:0] Out_dina_WeightSRAM,   //[31:0]
    output reg [`BIT_SPSRAM-1:0] Out_addra_WeightSRAM,
    
    //Outputs to Dffqs in front of Systolic Array
    output reg [`PE_COL-1:0] Out_Valid_SysDffq, //[3:0]
    output reg [`PE_COL*`BIT_ADDR-1:0] Out_addrP_SysDffq,  //[63:0]
    output reg [`PE_COL*`BIT_ROW_ID-1:0] Out_EnID_SysDffq,  //[15:0]
    output reg [`PE_COL-1:0] Out_EnWeight_SysDffq,  //[3:0]
    
    //Outputs to Psum SRAMs (Dual Port)
    output reg [`PE_COL*`BIT_DPSRAM-1:0] Out_addrb_PsumSRAM,  //[27:0]
    output reg [`PE_COL-1:0] Out_ena_PsumSRAM,  //[3:0]
    output reg [`PE_COL-1:0] Out_enb_PsumSRAM,  //[3:0]
    
    //Outputs to Input SRAMs
    output reg [`PE_ROW-1:0] Out_wea_InputSRAM, //[7:0]
    output reg [`PE_ROW-1:0] Out_ena_InputSRAM, //[7:0]
    output reg [`BIT_DATA-1:0] Out_dina_InputSRAM, //[63:0]
    output reg [`BIT_SPSRAM-1:0] Out_addra_InputSRAM, //[119:0]
    //Zero Mask
    output reg [`PE_ROW-1:0] Out_Disable_ZeroMask,  //[7:0]
    
    //Output to PsumLoader
    output reg [`PE_COL-1:0] Out_enable_PsumLoader, //[3:0]
    
    //Feedbacks
    input [`PE_COL*`BIT_PSUM-1:0] PsumSRAM_doutb_In //[95:0]
    );

genvar i;
integer j;

/*Define Internal Components*/
reg [1:0] states; //0 Idle 1 Load InputSRAM, 2 Load WeightSRAM, 3 Run
reg [`BIT_INSTR-1:0] Instr_In;
reg FinishFlag;
assign Out_FinishFlag = FinishFlag;
reg FinishFlagIndicator;

reg [2:0] WriteBackTimer;  //Turns ON when Data-WriteBack Instruction Inserted
reg [`BIT_DATA-1:0] Offset;//Address of Datas after Executing into Psum
reg [`BIT_DATA-1:0] SC;
reg [`BIT_DATA-1:0] IC;
reg [`BIT_DATA-1:0] OC; //Latched Inputs

//Determine enb& addrb when WriteBack.
wire [`PE_ROW-1:0] WriteBackenb_R; //[7:0]
wire [`PE_COL-1:0] WriteBackenb;  //[7:0]
assign WriteBackenb = WriteBackenb_R[0+:`PE_COL];
wire [`PE_COL*`BIT_DPSRAM-1:0] WriteBackaddrb;
wire [`BIT_SPSRAM-1:0] LoadInputAddress;
wire [`BIT_SPSRAM-1:0] LoadWeightAddress;
assign LoadWeightAddress = LoadInputAddress;
wire [`BIT_DATA-1:0] LoadInputData;
generate
for(i=0;i<`PE_ROW;i=i+1) begin
    assign WriteBackenb_R[i]=(Instr_In[(`BIT_DATA+`BIT_ADDR)+:`BIT_SEL]==i) ? 1'b1:1'b0;
end
endgenerate
assign LoadInputAddress = Instr_In[`BIT_DATA+:`BIT_SPSRAM];
assign LoadInputData = Instr_In[0+:`BIT_DATA];

wire [`BIT_DATA-1:0] LoadWeightData;
assign LoadWeightData = LoadInputData;
generate
for (i=0;i<`PE_COL;i=i+1) begin
    assign WriteBackaddrb[i*`BIT_DPSRAM+:`BIT_DPSRAM]=(Instr_In[(`BIT_DATA+`BIT_ADDR)+:`BIT_SEL]==i) ? Instr_In[`BIT_DATA+:`BIT_DPSRAM]:`BIT_DPSRAM'd0;
end
endgenerate

//Additionally defined For WriteBack Instructions
reg [`PE_COL-1:0] WriteBackFilter, WriteBackFilter_1, WriteBackFilter_2, WriteBackFilter_3, WriteBackFilter_4;

//Defined Exclusively For RUN state
reg [`BIT_DATA-1:0] S_Count, IC_Count, OC_Count; //Matrix Tiling Parameters
reg RunState; //    0:    Load Weight, 1:    Load Input
reg [`BIT_ROW_ID-1:0] RowCount;
reg [4:0] FinishCount;
reg ValidOffCount;


/*Sequential Logic*/
always @(posedge CLK) begin
    if(~RST) begin
        //WriteBackFilter FIFO
        WriteBackFilter_1 <= WriteBackFilter;
        WriteBackFilter_2 <= WriteBackFilter_1;
        WriteBackFilter_3 <= WriteBackFilter_2;
        WriteBackFilter_4 <= WriteBackFilter_3;
        
        Instr_In <= Instr_In_In;
        
        //~RUN
        if(states != 2'd3) begin
            S_Count <= `BIT_DATA'd0; IC_Count <= `BIT_DATA'd0; OC_Count <= `BIT_DATA'd0; RunState <= 1'b0; 
            RowCount <= `BIT_ROW_ID'd0; FinishFlagIndicator <= 1'b0; FinishCount <= 5'd0; ValidOffCount <= 1'b0;//Default RUN parameters
        end
        
        //~Idle
        if(states != 2'd0) WriteBackTimer <= 3'b0;
        
        if(states == 2'd0) begin : IDLE
        
        // Weight SRAMs
        Out_ena_WeightSRAM   <= `PE_COL'd0;
        Out_wea_WeightSRAM   <= `PE_COL'd0;
        Out_dina_WeightSRAM  <= {(`BIT_DATA){1'b0}};
        Out_addra_WeightSRAM <= {(`BIT_SPSRAM){1'b0}};
    
        // Input SRAMs
        Out_ena_InputSRAM    <= `PE_ROW'd0;
        Out_wea_InputSRAM    <= `PE_ROW'd0;
        Out_dina_InputSRAM   <= {(`BIT_DATA){1'b0}};
        Out_addra_InputSRAM  <= {(`BIT_SPSRAM){1'b0}};
    
        // Psum SRAMs (Write Port)
        Out_ena_PsumSRAM     <= `PE_COL'd0;
    
        // Systolic Array DFFQs
        Out_Valid_SysDffq    <= `PE_COL'd0;
        Out_EnWeight_SysDffq <= `PE_COL'd0;
        Out_addrP_SysDffq    <= {(`PE_COL*`BIT_ADDR){1'b0}};
        Out_EnID_SysDffq     <= {(`PE_COL*`BIT_ROW_ID){1'b0}};
    
        // Others
        Out_enable_PsumLoader <= `PE_COL'd0;
        Out_Disable_ZeroMask  <= `PE_ROW'd0;
        
        //Used Outputs: Out_enb_PsumSRAM, Out_addrb_PsumSRAM
        
        /*Functions*/
        //1. Set Parameters
        case (Instr_In[`BIT_DATA+:(`BIT_INSTR-`BIT_DATA)])
            {`OPVALID, `OPCODE_PARAM, `PARAM_S}: begin
                SC <= Instr_In[0+:`BIT_DATA];
                FinishFlag <= 1'b0;
            end
            {`OPVALID, `OPCODE_PARAM, `PARAM_IC}: begin
                IC <= Instr_In[0+:`BIT_DATA];
                FinishFlag <= 1'b0;
            end
            {`OPVALID, `OPCODE_PARAM, `PARAM_OC}: begin
                OC <= Instr_In[0+:`BIT_DATA];
                FinishFlag <= 1'b0;
            end
            {`OPVALID, `OPCODE_PARAM, `PARAM_BASE_WSRAM}: begin
                Offset <= Instr_In[0+:`BIT_DATA];
            end
        endcase
        
        //2. Shift State
        if (Instr_In == {`OPVALID, `OPCODE_PARAM, `PARAM_TRG, `TRG_ISRAM}) begin
            states <= 2'd1;
        end 
        else if (Instr_In == {`OPVALID, `OPCODE_PARAM, `PARAM_TRG, `TRG_WSRAM}) begin
            states <= 2'd2;
        end
        else if (Instr_In[(`BIT_DATA+`BIT_PARAM)+:(1+`BIT_OPCODE)] == {`OPVALID, `OPCODE_EX}) begin
            states <= 2'd3;
        end
        
        //3. WriteBack
        //Parameters
        case (Instr_In[`BIT_DATA +: (`BIT_INSTR - `BIT_DATA)])
            {`OPVALID, `OPCODE_WBPARAM, `PARAM_S}: begin
                Out_DataWriteBack[0+:`BIT_DATA] <= SC;
                Out_ValidWriteBack <= (SC != `BIT_DATA'd0);
            end
            {`OPVALID, `OPCODE_WBPARAM, `PARAM_IC}: begin
                Out_DataWriteBack[0+:`BIT_DATA] <= IC;
                Out_ValidWriteBack <= (IC != `BIT_DATA'd0);
            end
            {`OPVALID, `OPCODE_WBPARAM, `PARAM_OC}: begin
                Out_DataWriteBack[0+:`BIT_DATA] <= OC;
                Out_ValidWriteBack <= (OC != `BIT_DATA'd0);
            end
        endcase
        //Data
        if(Instr_In[(`BIT_DATA+`BIT_PARAM)+:(`BIT_OPCODE+1)] == {`OPVALID, `OPCODE_WBPSRAM}) begin
            Out_enb_PsumSRAM <= WriteBackenb;   
            Out_addrb_PsumSRAM <= WriteBackaddrb;
            WriteBackTimer <= 3'd7;
        end
        else Out_enb_PsumSRAM <= `PE_COL'd0;
        
        
        if (FinishFlag & (WriteBackTimer != 3'd0)) begin
            WriteBackFilter <= Out_enb_PsumSRAM;
            if (WriteBackFilter_4 != `PE_COL'd0) Out_ValidWriteBack <= 1'b1;
            else Out_ValidWriteBack <= 1'b0;
            for(j=0;j<`PE_COL;j=j+1) begin
                if(WriteBackFilter_4[j]) Out_DataWriteBack <= PsumSRAM_doutb_In[j*`BIT_PSUM+:`BIT_PSUM];
            end
        end
        
        if((Instr_In[(`BIT_DATA+`BIT_PARAM)+:(`BIT_OPCODE+1)] != {`OPVALID, `OPCODE_WBPSRAM}) && (Instr_In[(`BIT_DATA+`BIT_PARAM)+:(`BIT_OPCODE+1)] != {`OPVALID, `OPCODE_WBPARAM})) begin
            if (WriteBackTimer != 3'd0) WriteBackTimer <= WriteBackTimer - 3'd1;
            else Out_ValidWriteBack <= 1'b0;
        end
        
        end//...Idle

        if(states == 2'd1) begin: LDINPUT //Load Input SRAMs
        
        
        /*Outputs Not in Use*/
        //Global Outputs
        Out_ValidWriteBack <= 1'b0;
        Out_DataWriteBack <= `BIT_PSUM'd0;
        
        //Weight SRAM
        Out_ena_WeightSRAM <= `PE_COL'd0;
        Out_wea_WeightSRAM <= `PE_COL'd0;
        
        //Psum SRAMs
        Out_ena_PsumSRAM <= `PE_COL'd0;
        Out_enb_PsumSRAM <= `PE_COL'd0;
        
        //Dffqs
        Out_Valid_SysDffq <= `PE_COL'd0;
        Out_EnWeight_SysDffq <= `PE_COL'd0;
        
        //Psum Loader
        Out_enable_PsumLoader <= `PE_COL'd0;
        
        //ZeroMasks
        Out_Disable_ZeroMask <= `PE_ROW'd0;
        
        /*Function*/
        if(Instr_In[(`BIT_DATA+`BIT_PARAM)+:(`BIT_OPCODE+1)] == {`OPVALID, `OPCODE_LDSRAM}) begin
            Out_wea_InputSRAM <= WriteBackenb_R; 
            Out_addra_InputSRAM <= LoadInputAddress; 
            Out_dina_InputSRAM <= LoadInputData;
            FinishFlag <= 1'b0; //Loading Data turns Off FinishFlag
        end
        else begin  //Not Loading Data
            Out_wea_InputSRAM <= `PE_ROW'd0;
        end
        
        /*Shift to Other States*/
        //to Load Weight
        if (Instr_In == {`OPVALID, `OPCODE_PARAM, `PARAM_TRG, `TRG_WSRAM}) begin
            states <= 2'd2;
            Out_ena_InputSRAM <= `PE_ROW'd0; //Disable InputSRAM Enables
        end
        
        //to Idle
        else if(Instr_In[(`BIT_PARAM+`BIT_DATA)+:(`BIT_OPCODE+1)] == {`OPVALID, `OPCODE_NOP}) begin
            states <= 2'd0;
            Out_ena_InputSRAM <= `PE_ROW'd0;
        end
        
        //To Execute
        else if (Instr_In[(`BIT_DATA+`BIT_PARAM)+:(1+`BIT_OPCODE)] == {`OPVALID, `OPCODE_EX}) begin
            states <= 2'd3;
            Out_ena_InputSRAM <= `PE_ROW'd0;
        end
        
        //Enable InputSRAM If there's no State Shift
        else Out_ena_InputSRAM <= {`PE_ROW{1'b1}};
        
        end//...Load Input SRAMs


        if(states == 2'd2) begin   //Load Weight SRAMs
        
        /*Outputs Not in Use*/
        //Global Outputs
        Out_ValidWriteBack <= 1'b0;
        Out_DataWriteBack <= `BIT_PSUM'd0;
        
        //Psum SRAMs
        Out_ena_PsumSRAM <= `PE_COL'd0;
        Out_enb_PsumSRAM <= `PE_COL'd0;
        
        //Psum Loader
        Out_enable_PsumLoader <= `PE_COL'd0;
        
        //InputSRAM
        Out_wea_InputSRAM <= `PE_ROW'd0;
        Out_ena_InputSRAM <= `PE_ROW'd0;
        //ZeroMasks
        Out_Disable_ZeroMask <= `PE_ROW'd0;
        
        //Dffqs
        Out_Valid_SysDffq <= `PE_COL'd0;
        Out_EnWeight_SysDffq <= `PE_COL'd0;
        
        /*Function*/ //Load Data
        if(Instr_In[(`BIT_DATA+`BIT_PARAM)+:(`BIT_OPCODE+1)] == {`OPVALID, `OPCODE_LDSRAM}) begin
            Out_wea_WeightSRAM <= WriteBackenb;
            Out_addra_WeightSRAM <= LoadWeightAddress; 
            Out_dina_WeightSRAM <= LoadWeightData;
            FinishFlag <= 1'b0; //Loading Data turns Off FinishFlag
        end
        else begin //Not Loading Data
            Out_wea_WeightSRAM <= `PE_COL'd0;
        end
        
        /*Shift to Other States*/
        //To Load Input
        if (Instr_In == {`OPVALID, `OPCODE_PARAM, `PARAM_TRG, `TRG_ISRAM}) begin 
            states <= 2'd1;
            Out_ena_WeightSRAM <= `PE_COL'd0; //Disable WeightSRAM Enables
        end
        
        //To Idle
        else if(Instr_In[(`BIT_PARAM+`BIT_DATA)+:(`BIT_OPCODE+1)] == {`OPVALID, `OPCODE_NOP}) begin 
            states <= 2'd0;
            Out_ena_WeightSRAM <= `PE_COL'd0; //Disable WeightSRAM Enables
        end
        
        //To Execute
        else if (Instr_In[(`BIT_DATA+`BIT_PARAM)+:(1+`BIT_OPCODE)] == {`OPVALID, `OPCODE_EX}) begin
            states <= 2'd3;
            Out_ena_InputSRAM <= `PE_ROW'd0;
        end
        //Enable InputSRAM If there's no State Shift
        else Out_ena_WeightSRAM <= {`PE_COL{1'b1}};
        
        end//...Load Weight SRAMs

        if(states == 2'd3) begin   //Run
            /*Writing Input/Weight Data is Prohibited*/
            Out_wea_InputSRAM <= `PE_ROW'd0; 
            Out_wea_WeightSRAM <=`PE_COL'd0;
            
            /*Always Turn On SRAM enables to Access Data*/
            Out_ena_PsumSRAM <= {`PE_COL{1'b1}};            
            Out_ena_WeightSRAM <= {`PE_COL{1'b1}};
            Out_ena_InputSRAM <= {`PE_ROW{1'b1}};
            Out_enb_PsumSRAM <= {`PE_COL{1'b1}};
            /*Function*/
            //Parameters should be Valid and FinishFlag LOW to execute MMULT
            if((SC != `BIT_DATA'd0) & (IC != `BIT_DATA'd0) & (OC != `BIT_DATA'd0) & (~FinishFlagIndicator)) begin
                
                if(~RunState) begin //Weight Load Mode
                    /*Outputs Not Used*/
                    //ZeroMask
                    Out_Disable_ZeroMask <= `PE_ROW'd0;
                    //PsumLoader
                    Out_enable_PsumLoader <= `PE_COL'd0;

                    //Dffq
                    Out_Valid_SysDffq <= `PE_COL'd0;
                
                    if(RowCount <`PE_ROW) begin
                        RowCount <= RowCount+1;
                        
                        //Systolic Array
                        for(j=0;j<`PE_COL;j=j+1) begin
                            Out_EnID_SysDffq[j*`BIT_ROW_ID+:`BIT_ROW_ID] <= RowCount; //Apply RowCount
                            
                            if(((OC_Count+j) < OC)&&((IC_Count+RowCount) < IC)) Out_EnWeight_SysDffq[j] <= 1'b1; //Enable Loading Weights Only if the Two Conditions Met
                            else Out_EnWeight_SysDffq[j] <= 1'b0;
                            
                            Out_addra_WeightSRAM <= (IC*OC_Count[3+:(`BIT_DATA-3)] + IC_Count + RowCount); //Weight SRAM's Address Representation Applied
                        end
                    end
                    
                    else begin
                        RowCount <= `BIT_ROW_ID'd0;
                        Out_EnWeight_SysDffq <= `PE_COL'd0;
                        RunState <= 1'b1;
                    end
                end
                
                
                else begin// "if (RunState)" Input Load Mode
                    //Delay RunState --> ~Runstate process
                    if(Out_Valid_SysDffq == `PE_COL'd0) ValidOffCount <= 1'b1;
                    else ValidOffCount <= 1'b0;
                    
                    //Outputs Not Used
                    Out_EnWeight_SysDffq <= `PE_COL'd0;
                    RowCount <= `BIT_ROW_ID'd0;
                    
                    //Systolic FIFO
                    for(j=1;j<`PE_COL;j=j+1) begin
                        //Valid
                        if((OC_Count + j) < OC) Out_Valid_SysDffq[j] <= Out_Valid_SysDffq[j-1];
                        else Out_Valid_SysDffq[j] <= 1'b0;
                        //address
                        Out_addrP_SysDffq[j*`BIT_ADDR+:`BIT_ADDR] <= Out_addrP_SysDffq[(j-1)*`BIT_ADDR+:`BIT_ADDR];
                        Out_addrb_PsumSRAM[j*`BIT_DPSRAM+:`BIT_DPSRAM] <= Out_addrb_PsumSRAM[(j-1)*`BIT_DPSRAM+:`BIT_DPSRAM];
                    end
                    
                    //if Valid Sign Goes Off, Count for it
                    
                    
                    //PsumLoader Enable Follows Valid Signal When IC_Count > 0
                    if (IC_Count > 0) Out_enable_PsumLoader <= Out_Valid_SysDffq;
                    else Out_enable_PsumLoader <= `PE_COL'd0;
                                        
                    
                    if (S_Count < SC) begin //Load Input
                        S_Count <= S_Count+1;
                        
                        //Input SRAM&ZeroMask
                        for(j=0;j<`PE_ROW;j=j+1) begin
                            if((IC_Count+j) < IC) Out_Disable_ZeroMask[j] <= 1'b1;
                            else Out_Disable_ZeroMask[j] <= 1'b0;
                        end
                        Out_addra_InputSRAM <= (IC_Count[3+:(`BIT_DATA-3)]*SC + S_Count);
                        
                        //Systolic Array - Determine Valid & Address's Column[0]
                        if(OC_Count < OC) begin
                            Out_Valid_SysDffq[0] <= 1'b1;
                            Out_addrP_SysDffq[0+:`BIT_ADDR] <= (OC_Count[3+:(`BIT_DATA-3)]*SC + S_Count + Offset);
                            Out_addrb_PsumSRAM[0+:`BIT_DPSRAM] <= (OC_Count[3+:(`BIT_DATA-3)]*SC + S_Count + Offset);
                        end
                        else Out_Valid_SysDffq <= 1'b0;
                                                
                    end
                    
                    
                    else begin //Increment and Shift
                    
                        //Turn Off Valid[0]
                        Out_Valid_SysDffq[0] <= 1'b0;
                        //Wait Until Valid Signal Completely become Zero
                        if((Out_Valid_SysDffq == `PE_COL'd0) && ValidOffCount) begin
                            S_Count <= 0;
                            RunState <= 1'b0;
                            //Increment OC, IC
                            if(OC_Count+`PE_COL < OC) OC_Count <= OC_Count+`PE_COL;
                            else begin
                                OC_Count <= `BIT_DATA'd0;
                                if(IC_Count+`PE_ROW < IC) IC_Count <= IC_Count+`PE_ROW;
                                else FinishFlagIndicator <= 1'd1;
                            end
                        end
                    end
                
                
                end
            end
            
            //One or more Conditions(Parameters, FinishFlagIndicator) Corrupted
            else begin
                if(FinishCount < 5'd24) FinishCount <= FinishCount + 5'd1; //Count for 20, and then Go Back to IDLE
                else begin
                    states <= 2'd0;
                    if (FinishFlagIndicator) FinishFlag <= 2'b1;
                end
            end
        end//...Run
        
    end
    else begin //RST == 1
        states <= 2'd0; //To Idle
        SC <= `BIT_DATA'd0; IC <= `BIT_DATA'd0; OC <= `BIT_DATA'd0; //Reset Parameters
        FinishFlag <= 1'd0; //Reset Flag
        Out_ValidWriteBack <= 1'b0; Out_DataWriteBack <= `BIT_PSUM'd0;
        Offset <= `BIT_DATA'd0;
        WriteBackTimer <= 3'd0;
        Out_enable_PsumLoader <= `PE_COL'd0;
    end
end

endmodule




