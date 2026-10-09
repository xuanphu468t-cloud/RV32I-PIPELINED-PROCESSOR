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