module mul(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire sign,
    output [63:0] result
);
    reg[63:0] result;
    wire [15:0] a_low, a_high, b_low, b_high;
    wire [31:0] p1, p2, p3, p4;

    assign a_low = a[15:0];
    assign a_high = a[31:16];
    assign b_low = b[15:0];
    assign b_high = b[31:16];

    assign p1 = a_low * b_low;
    assign p2 = a_low * b_high;
    assign p3 = a_high * b_low;
    assign p4 = a_high * b_high;

    always @(*) begin
        if (sign) begin
            result = {p4, p3 + p2, p1};
        end 
        else begin
            result = {p4[30:0], p3[30:0] + p2[30:0], p1[30:0]};
        end
    end
endmodule