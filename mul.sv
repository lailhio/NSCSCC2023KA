module mul(
    input clk,
    input rst, flush,
    input [31:0] opdata1_i,
    input [31:0] opdata2_i,
    input signed_mul_i,
    input start_i,
    output [63:0] result_o,
    output reg ready_o
);

wire a_sign = opdata1_i[31];
wire b_sign = opdata2_i[31];
wire out_sign = a_sign ^ b_sign;

wire [31:0] a_abs = a_sign ? -opdata1_i : opdata1_i;
wire [31:0] b_abs = b_sign ? -opdata2_i : opdata2_i;

wire [31:0] cal_a = signed_mul_i ? a_abs : opdata1_i;
wire [31:0] cal_b = signed_mul_i ? b_abs : opdata2_i;

reg [31:0] part_0;
reg [31:0] part_1;
reg [31:0] part_2;
reg [31:0] part_3;

always @(posedge clk) begin
    if (rst | flush) begin
        ready_o <= 0;
        part_0 <= 0;
        part_1 <= 0;
        part_2 <= 0;
        part_3 <= 0;
    end
    else begin
        if (!ready_o) begin
            if (start_i) begin
                part_0 <= cal_a[15:0 ] * cal_b[15:0 ];
                part_1 <= cal_a[15:0 ] * cal_b[31:16];
                part_2 <= cal_a[31:16] * cal_b[15:0 ];
                part_3 <= cal_a[31:16] * cal_b[31:16];
                ready_o <= 1'b1;
            end
        end
        else ready_o <= 1'b0;
    end
end

wire [63:0] mid_result = {32'd0,part_0} + {16'd0,part_1,16'd0} + {16'd0,part_2,16'd0} + {part_3,32'd0};

assign result_o = signed_mul_i && out_sign ? -mid_result : mid_result;

endmodule