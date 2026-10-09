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