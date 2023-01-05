module mul(
    input [31:0]        a,
    input [31:0]        b,
    input               sign,
    output [63:0]       result
);
    
    wire [15:0] a_low, a_low_abs, a_high, a_high_abs, 
                b_low, b_low_abs, b_high, b_high_abs;
    wire [63:0] p1, p1_abs, p2, p2_abs, p3, p3_abs, p4, p4_abs;
    wire sign_a = a[31];
    wire sign_b = b[31];

    wire [31:0] abs_a = sign_a ? ((~a)+1) : a;
    wire [31:0] abs_b = sign_b ? ((~b)+1) : b;

    assign a_low_abs = abs_a[15:0];
    assign a_high_abs = abs_a[31:16];
    assign b_low_abs = abs_b[15:0];
    assign b_high_abs = abs_b[31:16];

    assign p1_abs = a_low_abs * b_low_abs;
    assign p2_abs = a_low_abs * b_high_abs;
    assign p3_abs = a_high_abs * b_low_abs;
    assign p4_abs = a_high_abs * b_high_abs;

    assign a_low = a[15:0];
    assign a_high = a[31:16];
    assign b_low = b[15:0];
    assign b_high = b[31:16];

    assign p1 = a_low * b_low;
    assign p2 = a_low * b_high;
    assign p3 = a_high * b_low;
    assign p4 = a_high * b_high;

    wire [63:0] abs_result = (p4_abs<<32)+((p3_abs + p2_abs)<<16)+p1_abs;

    wire [63:0] signed_result = (sign_a ^ sign_b) ? ((~abs_result)+1) : abs_result;


    assign result = sign ? signed_result : ((p4<<32)+((p3 + p2)<<16)+p1);

endmodule
