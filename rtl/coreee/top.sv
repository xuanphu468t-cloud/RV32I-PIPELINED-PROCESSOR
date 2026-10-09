module top(input logic clk, reset,
            output logic [31:0] WriteData, DataAdr,
            output logic MemWrite);
        logic [31:0] PCF, Instr, ReadData;

    processor processor(.clk(clk), 
                        .reset(reset),
                        .Instr(Instr),
                        .MemWrite(MemWrite),
                        .ReadData(ReadData),
                        .PCF(PCF),
                        .WriteData(WriteData),
                        .ALUResult(DataAdr));
    imem imem(.a(PCF), .rd(Instr));
    dmem dmem(.clk(clk), .we(MemWrite), .a(DataAdr), .wd(WriteData), .rd(ReadData));
endmodule

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

module controller(input logic [6:0] op,
                    input logic [2:0] funct3,
                    input logic funct7b5,
                    
                    output logic RegWriteD,
                    output logic [1:0] ResultSrcD,
                    output logic MemWriteD,
                    output logic JumpD, BranchD,
                    output logic [2:0] ALUControlD,
                    output logic ALUSrcD,
                    output logic [1:0] ImmSrcD);
    logic [1:0] ALUOp;
    logic Branch;
        maindec md(.op(op), .ResultSrc(ResultSrcD), .MemWrite(MemWriteD), .Branch(BranchD), .ALUSrc(ALUSrcD), .RegWrite(RegWriteD), .Jump(JumpD), .ImmSrc(ImmSrcD), .ALUOp(ALUOp));

        aludec ad(.opb5(op[5]), .funct3(funct3), .funct7b5(funct7b5), .ALUOp(ALUOp), .ALUControl(ALUControlD));
endmodule

module maindec(input logic [6:0] op,
                
                output logic [1:0] ResultSrc,
                output logic MemWrite,
                output logic Branch, ALUSrc,
                output logic RegWrite, Jump,
                output logic [1:0] ImmSrc,
                output logic [1:0] ALUOp);
    logic [10:0] controls;
        assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
                ResultSrc, Branch, ALUOp, Jump} = controls;
        always_comb
            case(op)
                7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
                7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
                7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R–type
                7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
                7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I–type ALU
                7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
                default: controls = 11'bx_xx_x_x_xx_x_xx_x; // ???
            endcase
endmodule

module aludec(input logic opb5,
                input logic [2:0] funct3,
                input logic funct7b5,
                input logic [1:0] ALUOp,
                
                output logic [2:0] ALUControl);
    logic RtypeSub;
        assign RtypeSub = funct7b5 & opb5; // TRUE for R–type subtract
        always_comb
            case(ALUOp)
                2'b00: ALUControl = 3'b000; // addition
                2'b01: ALUControl = 3'b001; // subtraction
                default: case(funct3) // R–type or I–type ALU
                    3'b000: if (RtypeSub)
                        ALUControl = 3'b001; // sub
                            else ALUControl = 3'b000; // add, addi
                    3'b010: ALUControl = 3'b101; // slt, slti
                    3'b110: ALUControl = 3'b011; // or, ori
                    3'b111: ALUControl = 3'b010; // and, andi
                    default:ALUControl = 3'bxxx; // ???
                        endcase
            endcase
endmodule

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

module extend(
    input logic [31:7] instr,
    input logic [1:0] immsrc,

    output logic [31:0] immext);

    always @(*) begin
        case(immsrc)
                // I−type
            2'b00: immext = {{20{instr[31]}}, instr[31:20]};
                // S−type (stores)
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                // B−type (branches)
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                // J−type (jal)
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: immext = 32'bx; // undefined
        endcase
    end
endmodule

module flopr #(parameter WIDTH = 8)(
    input logic clk, reset,
    input logic [WIDTH-1:0] d,

    output logic [WIDTH-1:0] q);

    always_ff @(posedge clk, posedge reset)
        if (reset) q <= 0;
        else q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)(
    input logic clk, reset, en,
    input logic [WIDTH-1:0] d,

    output logic [WIDTH-1:0] q);

    always_ff @(posedge clk, posedge reset)
        if (reset) q <= 0;
        else if (en) q <= d;
endmodule

module alu(
    input  logic [31:0] SrcAE,
    input  logic [31:0] SrcBE,
    input  logic [2:0] ALUControl,

    output logic [31:0] ALUResultM,
    output logic        ZeroE);

    logic [31:0] bb;
    logic [31:0] y [2:0];
    logic overflow;
    logic [3:0]p;

    mux1_2 mux1(.d1(~SrcBE), .d0(SrcBE), .s(ALUControl[0]), .y(bb));
    prefixadder adder(.a(SrcAE), .b(bb), .cin(ALUControl[0]), .s(y[0]));
    mux1_2 mux2(.d1(SrcAE | SrcBE), .d0(SrcAE & SrcBE), .s(ALUControl[0]), .y(y[1]));
    mux1_2 mux4(.d1(y[1]), .d0(y[0]), .s(ALUControl[1]), .y(y[2]));

    assign p[3] = ~SrcAE[31] & SrcBE[31];
    assign p[2] = SrcAE[31]  & ~SrcBE[31];
    assign p[1] = ~SrcAE[31] & ~SrcBE[31];
    assign p[0] = SrcAE[31]  & SrcBE[31];

    mux2_4 mux3(.d3(p[3]), .d2(p[2]), .d1(p[1]), .d0(p[0]), .s({ALUControl[0], y[0][31]}), .y(overflow));
    mux1_2 mux5(.d1({31'b0, overflow ^ y[0][31]}), .d0(y[2]), .s(ALUControl[2]), .y(ALUResultM));

    assign ZeroE = ~(|ALUResultM);
endmodule

module prefixadder(
    input logic [31:0] a, b,
    input logic cin,

    output logic [31:0] s);

    localparam WIDTH = 32;
    logic [31:-1] p[5:0], g[5:0];
    logic [31:0] p_sum;
    assign g[0][-1] = cin;
    assign p[0][-1] = 1'b0;
    genvar i;
        generate
    for (i=0; i < WIDTH; i++) begin: gen_pg_init
        assign g[0][i] = a[i] & b[i];
        assign p[0][i] = a[i] | b[i];
        assign p_sum[i] = a[i] ^ b[i];
    end
    endgenerate
    genvar stage, j, k;
        generate
    for (stage = 1; stage <= 5; stage++) begin: gen_stages
        localparam int DIST = 2**(stage-1);//1,2,4,8
        assign g[stage][-1] = g[stage-1][-1];
        assign p[stage][-1] = p[stage-1][-1];
        
        for (j = -1; j < WIDTH; j = j + DIST) begin: gen_bits
            for (k = j;(k < j + DIST) && (k < WIDTH); k++) begin: gen_black_square
                if (((j + 1) % (2 * DIST)) >= DIST) begin: black_square
                    assign g[stage][k] = g[stage-1][k] | (p[stage-1][k] & g[stage-1][j-1]);
                    assign p[stage][k] = p[stage-1][k] & p[stage-1][j-1];
                end else if (k >= 0) begin: buffer 
                    assign g[stage][k] = g[stage-1][k];
                    assign p[stage][k] = p[stage-1][k];
                end
            end 
        end
    end
    endgenerate
        generate
        for (i = 0; i < WIDTH; i++) begin: gen_sum
            assign s[i] = p_sum[i] ^ g[5][i-1];
        end
    endgenerate
endmodule

module mux1_2(
    input logic [31:0] d1, d0,
    input logic s,
    
    output logic [31:0] y);
    assign y = s ? d1 : d0;
endmodule

module mux1_3(
    input logic [31:0] d2, d1, d0,
    input logic [1:0] s,
    
    output logic [31:0] y);
    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule

module mux2_4(
    input logic d3, d2, d1, d0,
    input logic [1:0] s,
    output logic y);
    
    assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);
endmodule

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

module regfile( 
    input logic clk,
    input logic [4:0] a1, a2, a3,
    input logic [31:0] WriteData3,
    input logic WriteEnable3,

    output [31:0] ReadData1, ReadData2);

    logic [31:0] rf [31:0];
    
    assign ReadData1 = (a1 == 5'b0) ? 32'b0 : rf[a1];
    assign ReadData2 = (a2 == 5'b0) ? 32'b0 : rf[a2];

    always_ff @(posedge clk) begin 
        if ((WriteEnable3) && (a3 != 5'b0))
            rf[a3] <= WriteData3;
    end
endmodule

module imem(input logic [31:0] a,
            output logic [31:0] rd);
        logic [31:0] RAM[63:0];
    initial
        $readmemh("test.txt", RAM);
    assign rd = RAM[a[31:2]]; // word aligned
endmodule

module dmem(input logic clk, we,
            input logic [31:0] a, wd,
            output logic [31:0] rd);
        logic [31:0] RAM[63:0];
    assign rd = RAM[a[31:2]]; // word aligned
    always_ff @(posedge clk)
        if (we) RAM[a[31:2]] <= wd;
endmodule


