module processor(input logic clk, reset,
                input logic [31:0] Instr,
                input logic [31:0] ReadData,
                    
                output logic [31:0] PCF,
                output logic MemWrite,
                output logic [31:0] ALUResult, WriteData);
    
    logic ALUSrcD, RegWriteD, JumpD, BranchD, MemWriteD;
    logic [1:0] ResultSrcD, ImmSrcD;  
    logic [2:0] ALUControlD;
    logic [31:0] InstrD;
        controller c(.op(InstrD[6:0]), 
                    .funct3(InstrD[14:12]), 
                    .funct7b5(InstrD[30]), 
                    .ResultSrcD(ResultSrcD), 
                    .MemWriteD(MemWriteD), 
                    .ALUSrcD(ALUSrcD), 
                    .RegWriteD(RegWriteD), 
                    .JumpD(JumpD),
                    .BranchD(BranchD),
                    .ImmSrcD(ImmSrcD), 
                    .ALUControlD(ALUControlD));
        datapath dp(.clk(clk), 
                    .reset(reset),
                    .RegWriteD(RegWriteD),
                    .ResultSrcD(ResultSrcD),
                    .ALUSrcD(ALUSrcD),
                    .MemWriteD(MemWriteD),
                    .JumpD(JumpD),
                    .BranchD(BranchD),
                    .ALUControlD(ALUControlD),
                    .ImmSrcD(ImmSrcD),
                    .Instr(Instr),
                    .InstrD(InstrD),
                    .ReadData(ReadData),
                    .MemWriteM(MemWrite),
                    .PCF(PCF),
                    .ALUResultM(ALUResult),
                    .WriteDataM(WriteData));
endmodule
