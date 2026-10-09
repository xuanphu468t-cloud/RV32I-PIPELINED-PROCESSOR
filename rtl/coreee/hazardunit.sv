module hazardunit(
    input logic [4:0] Rs1D, Rs1E, Rs2D, Rs2E, RdE, RdM, RdW,
    input logic PCSrcE, ResultSrcE_0, RegWriteM, RegWriteW,

    output logic StallF, StallD, FlushD, FlushE, 
    output logic [1:0] ForwardAE, ForwardBE);

    logic lwStall;

    assign ForwardAE[1] = ((Rs1E == RdM) & RegWriteM) & (Rs1E != 0);
    assign ForwardAE[0] = ((Rs1E == RdW) & RegWriteW) & (Rs1E != 0);
    assign ForwardBE[1] = ((Rs2E == RdM) & RegWriteM) & (Rs2E != 0);
    assign ForwardBE[0] = ((Rs2E == RdW) & RegWriteW) & (Rs2E != 0);

    assign lwStall = ResultSrcE_0 & ((Rs1D == RdE) | (Rs2D == RdE)) & (RdE != 5'b0);
    assign StallF = lwStall;
    assign StallD = lwStall;

    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;
endmodule