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

module mux2_4(
    input logic d3, d2, d1, d0,
    input logic [1:0] s,
    output logic y);
    
    assign y = s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0);
endmodule