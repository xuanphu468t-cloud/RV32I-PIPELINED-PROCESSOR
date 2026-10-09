module datapath(input logic clk, reset,
                input logic RegWriteD,
                input logic [1:0] ResultSrcD,
                input logic ALUSrcD,
                input logic MemWriteD,
                input logic JumpD, BranchD,
                input logic [2:0] ALUControlD,
                input logic [1:0] ImmSrcD,

                input logic [31:0] Instr,
                input logic [31:0] ReadData,

                output logic [31:0] InstrD,
                output logic MemWriteM,
                output logic [31:0] PCF,
                output logic [31:0] ALUResultM, WriteDataM);

        logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E;
        logic PCSrcE;
        logic StallF, StallD, FlushD, FlushE; 
        logic [1:0] ForwardAE, ForwardBE;
        logic [31:0] PCF_n, PCD, PCE, PCPlus4F, PCPlus4D, PCPlus4M, PCPlus4E, PCPlus4W, PCTargetE;
        logic [31:0] ImmExtD, ImmExtE;
        logic [4:0] RdD, RdM, RdW, RdE;
        logic [31:0] RD1E, RD2E;
        logic [31:0] ReadDataW, ReadData1, ReadData2;
        logic ZeroE;
        logic [31:0] SrcAE, SrcBE;
        logic [31:0] ResultW;
        logic [31:0] WriteDataE;
        logic RegWriteE, RegWriteM, RegWriteW;
        logic [1:0] ResultSrcM, ResultSrcW, ResultSrcE;
        logic MemWriteE;
        logic JumpE;
        logic BranchE;
        logic [2:0] ALUControlE;
        logic ALUSrcE;
        logic [31:0] ALUResult, ALUResultW;


    flopenr #(32) pc(.clk(clk), .reset(reset), .en(~StallF), .d(PCF_n), .q(PCF));
    
    flopenr #(32) fd_0(.clk(clk), .reset(reset || FlushD), .en(~StallD), .d(Instr), .q(InstrD));
    flopenr #(32) fd_1(.clk(clk), .reset(reset), .en(~StallD), .d(PCF), .q(PCD));
    flopenr #(32) fd_2(.clk(clk), .reset(reset), .en(~StallD), .d(PCPlus4F), .q(PCPlus4D));

    flopr #(1) de_0(.clk(clk), .reset(reset || FlushE), .d(RegWriteD), .q(RegWriteE));
    flopr #(2) de_1(.clk(clk), .reset(reset || FlushE), .d(ResultSrcD), .q(ResultSrcE));
    flopr #(1) de_2(.clk(clk), .reset(reset || FlushE), .d(MemWriteD), .q(MemWriteE));
    flopr #(1) de_3(.clk(clk), .reset(reset || FlushE), .d(JumpD), .q(JumpE));
    flopr #(1) de_4(.clk(clk), .reset(reset || FlushE), .d(BranchD), .q(BranchE));
    flopr #(3) de_5(.clk(clk), .reset(reset || FlushE), .d(ALUControlD), .q(ALUControlE));
    flopr #(1) de_6(.clk(clk), .reset(reset || FlushE), .d(ALUSrcD), .q(ALUSrcE));
    flopr #(32) de_7(.clk(clk), .reset(reset || FlushE), .d(ReadData1), .q(RD1E));
    flopr #(32) de_8(.clk(clk), .reset(reset || FlushE), .d(ReadData2), .q(RD2E));
    flopr #(32) de_9(.clk(clk), .reset(reset), .d(PCD), .q(PCE));
    flopr #(5) de_10(.clk(clk), .reset(reset || FlushE), .d(Rs1D), .q(Rs1E));
    flopr #(5) de_11(.clk(clk), .reset(reset || FlushE), .d(Rs2D), .q(Rs2E));
    flopr #(5) de_12(.clk(clk), .reset(reset || FlushE), .d(RdD), .q(RdE));
    flopr #(32) de_13(.clk(clk), .reset(reset || FlushE), .d(ImmExtD), .q(ImmExtE));
    flopr #(32) de_14(.clk(clk), .reset(reset), .d(PCPlus4D), .q(PCPlus4E));

    flopr #(1) em_0(.clk(clk), .reset(reset), .d(RegWriteE), .q(RegWriteM));
    flopr #(2) em_1(.clk(clk), .reset(reset), .d(ResultSrcE), .q(ResultSrcM));
    flopr #(32) em_2(.clk(clk), .reset(reset), .d(ALUResult), .q(ALUResultM));
    flopr #(32) em_3(.clk(clk), .reset(reset), .d(WriteDataE), .q(WriteDataM));
    flopr #(5) em_4(.clk(clk), .reset(reset), .d(RdE), .q(RdM));
    flopr #(32) em_5(.clk(clk), .reset(reset), .d(PCPlus4E), .q(PCPlus4M));

    flopr #(1) mw_0(.clk(clk), .reset(reset), .d(RegWriteM), .q(RegWriteW));
    flopr #(2) mw_1(.clk(clk), .reset(reset), .d(ResultSrcM), .q(ResultSrcW));
    flopr #(32) mw_2(.clk(clk), .reset(reset), .d(ALUResultM), .q(ALUResultW));
    flopr #(32) mw_3(.clk(clk), .reset(reset), .d(ReadData), .q(ReadDataW));
    flopr #(5) mw_4(.clk(clk), .reset(reset), .d(RdM), .q(RdW));
    flopr #(32) mw_5(.clk(clk), .reset(reset), .d(PCPlus4M), .q(PCPlus4W));

    alu alu(.SrcAE(SrcAE), .SrcBE(SrcBE), .ALUControl(ALUControlE), .ALUResultM(ALUResult), .ZeroE(ZeroE));
    prefixadder add_F(.a(PCF), .b(32'b100), .cin(1'b0), .s(PCPlus4F));
    prefixadder add_E(.a(PCE), .b(ImmExtE), .cin(1'b0), .s(PCTargetE));
    mux1_2 mux_F(.d1(PCTargetE), .d0(PCPlus4F), .s(PCSrcE), .y(PCF_n));
    mux1_3 mux_A(.d2(ALUResultM), .d1(ResultW), .d0(RD1E), .s(ForwardAE), .y(SrcAE));
    mux1_3 mux_B(.d2(ALUResultM), .d1(ResultW), .d0(RD2E), .s(ForwardBE), .y(WriteDataE));
    mux1_2 mux_B_2(.d1(ImmExtE), .d0(WriteDataE), .s(ALUSrcE), .y(SrcBE));
    mux1_3 mux_W(.d2(PCPlus4W), .d1(ReadDataW), .d0(ALUResultW), .s(ResultSrcW), .y(ResultW));
    assign PCSrcE = (ZeroE & BranchE) | JumpE;
    extend ext(.instr(InstrD[31:7]), .immsrc(ImmSrcD) , .immext(ImmExtD));

    regfile rf(.clk(clk), .a1(Rs1D), .a2(Rs2D), .a3(RdW), .WriteData3(ResultW), .WriteEnable3(RegWriteW), .ReadData1(ReadData1), .ReadData2(ReadData2));

    hazardunit hu(.Rs1D(Rs1D), .Rs1E(Rs1E), .Rs2D(Rs2D), .Rs2E(Rs2E), .RdE(RdE), .RdM(RdM), .RdW(RdW),
                    .PCSrcE(PCSrcE), .ResultSrcE_0(ResultSrcE[0]), .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                    .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE), .ForwardAE(ForwardAE), .ForwardBE(ForwardBE));

    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];
endmodule