module alu_tb();
    logic clk;
    logic [31:0] SrcAE, SrcBE;
    logic [2:0] ALUControl;
    logic [31:0] ALUResultM, ALUResultM_ex;
    logic ZeroE, ZeroE_ex;
    logic [31:0] vectornum, errors;
    logic [99:0] testvector [10000:0]; 

    alu dut(.SrcAE(SrcAE), .SrcBE(SrcBE), .ALUControl(ALUControl), .ALUResultM(ALUResultM), .ZeroE(ZeroE));

    always begin
    clk = 1; #2; clk = 0; #2;
    end

    initial begin   
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end

    initial begin
        $readmemh("alu_tv.tv", testvector);
            vectornum = 0;
            errors = 0;
    end

    always @(posedge clk)
        begin
            #1; {SrcAE, SrcBE, ALUControl, ALUResultM_ex, ZeroE_ex} = testvector[vectornum];
        end
    always @(negedge clk)
        begin
            #2;
            if (ALUResultM !== ALUResultM_ex || ZeroE !== ZeroE_ex) begin
                $display("Error at vector %d: SrcAE=%h, SrcBE=%h, ALUControl=%h",vectornum, SrcAE, SrcBE, ALUControl);
                $display("output: %h (%h expected)", ALUResultM, ALUResultM_ex);
                $display("ZeroE: %b (%b expected)", ZeroE, ZeroE_ex);
                errors = errors + 1;
            end
            
            vectornum = vectornum + 1;

            if (testvector[vectornum] === 100'bx) begin
                $display("Test completed. %d vectors run, Total errors: %d", vectornum, errors);           
                $finish;
            end
        end
endmodule

