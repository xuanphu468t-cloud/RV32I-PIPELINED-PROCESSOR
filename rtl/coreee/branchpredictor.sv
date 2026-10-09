module branchpredictor(
    input logic clk, 
    input logic reset,
    input logic taken,
    
    output logic taken_n);

    typedef enum logic [1:0] {S0, S1, S2, S3} statetype;
    statetype state, next_state;

    always_ff @(posedge clk or posedge reset)
        if (reset)
            state <= S0;
        else 
            state <= next_state;
    always_comb
        case(state)
            S0: if (taken) next_state = S0;
                else next_state = S1;
            S1: if (taken) next_state = S0;
                else next_state = S2;
            S2: if (taken) next_state = S1;
                else next_state = S3;
            S3: if (taken) next_state = S2;
                else next_state = S3;
            default: next_state = S0;
        endcase

    assign taken_n = (state == S1) | (state == S2);
endmodule

