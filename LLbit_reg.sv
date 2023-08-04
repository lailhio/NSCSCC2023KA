module LLbit_reg(
    input wire clk, rst,
    // input wire flush,
    input wire we,
    input wire LLbit_in,
    output wire LLbit_out 
    );

    reg LLbit;

    always @(posedge clk) begin
        // if(rst | flush) LLbit <= 1'b0;
        if(rst) LLbit <= 1'b0;
        else if(we) 
            LLbit <= LLbit_in;
        else LLbit <= LLbit;
    end

    assign LLbit_out = LLbit;

endmodule    