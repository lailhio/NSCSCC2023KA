`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/03 13:12:32
// Design Name: 
// Module Name: mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// partial product generator for booth algorithm
module booth_gen #(
    parameter integer width = 32
)
(
    input [width-1:0] opdata1_i,
    input [2:0] opdata2_i,  // {opdata2_i[i+1], opdata2_i[i], opdata2_i[i-1]}
    output [width-1:0] p,
    output c
);

  wire [width:0] x_ = {opdata1_i, 1'b0};
  generate
    genvar i;
    for (i=0; i<width; i=i+1) begin
      assign p[i] = (opdata2_i == 3'b001 || opdata2_i == 3'b010) & x_[i+1]
                  | (opdata2_i == 3'b101 || opdata2_i == 3'b110) & ~x_[i+1]
                  | (opdata2_i == 3'b011) & x_[i]
                  | (opdata2_i == 3'b100) & ~x_[i];
    end
  endgenerate
  assign c = opdata2_i == 3'b100 || opdata2_i == 3'b101 || opdata2_i == 3'b110;

endmodule

// 17-bit wallace tree unit
module wallace_unit_17(
    input [16:0] in,
    input [14:0] cin,
    output c,
    output out,
    output [14:0] cout
);

  wire [14:0] s;
  assign {cout[0], s[0]} = in[16] + in[15] + in[14];
  assign {cout[1], s[1]} = in[13] + in[12] + in[11];
  assign {cout[2], s[2]} = in[10] + in[9] + in[8];
  assign {cout[3], s[3]} = in[7] + in[6] + in[5];
  assign {cout[4], s[4]} = in[4] + in[3] + in[2];
  assign {cout[5], s[5]} = in[1] + in[0];
  assign {cout[6], s[6]} = s[0] + s[1] + s[2];
  assign {cout[7], s[7]} = s[3] + s[4] + s[5];
  assign {cout[8], s[8]} = cin[0] + cin[1] + cin[2];
  assign {cout[9], s[9]} = cin[3] + cin[4] + cin[5];
  assign {cout[10], s[10]} = s[6] + s[7] + s[8];
  assign {cout[11], s[11]} = s[9] + cin[6] + cin[7];
  assign {cout[12], s[12]} = s[10] + s[11] + cin[8];
  assign {cout[13], s[13]} = cin[9] + cin[10] + cin[11];
  assign {cout[14], s[14]} = s[12] + s[13] + cin[12];
  assign {c, out} = s[14] + cin[13] + cin[14];

endmodule

module mul(
    input clk,
    input rst, flush, 
    input signed_mul_i,
    input [31:0] opdata1_i,
    input [31:0] opdata2_i,
    input start_i,
    output [63:0] result_o,
    output reg ready_o
);

  wire [63:0] x_ext = {{32{opdata1_i[31] & signed_mul_i}}, opdata1_i};
  wire [34:0] y_ext = {{2{opdata2_i[31] & signed_mul_i}}, opdata2_i, 1'b0};
  wire [63:0] part_prod [16:0];     // partial product
  wire [16:0] part_switch [63:0];   // switched partial product
  wire [16:0] part_carry;

  genvar i, j;
  generate
    for (i=0; i<17; i=i+1) begin
      booth_gen #(.width(64))
      part_mul(
        .opdata1_i(x_ext << 2*i),
        .opdata2_i(y_ext[(i+1)*2:i*2]),
        .p(part_prod[i]),
        .c(part_carry[i])
      );
      for (j=0; j<64; j=j+1) begin
        assign part_switch[j][i] = part_prod[i][j];
      end
    end
  endgenerate

  reg [16:0] part_switch_reg [63:0];
  reg [16:0] part_carry_reg;
  integer k;
  always @(posedge clk) begin
    for (k=0; k<64; k=k+1) begin
      part_switch_reg[k] <= part_switch[k];
    end
    part_carry_reg <= part_carry;
  end

  wire [14:0] wallace_carry [64:0];
  assign wallace_carry[0] = part_carry_reg[14:0];
  wire [63:0] out_carry, out_sum;
  generate
    for (i=0; i<64; i=i+1) begin
      wallace_unit_17 u_wallace(
        .in(part_switch_reg[i]),
        .cin(wallace_carry[i]),
        .c(out_carry[i]),
        .out(out_sum[i]),
        .cout(wallace_carry[i+1])
      );
    end
  endgenerate

  reg [63:0] add_a_reg, add_b_reg;
  reg add_cin_reg;
  reg res_ok1;
  
  always @(posedge clk) begin
    if (rst | flush) begin
        add_a_reg <= 0;
        add_b_reg <= 0;
        add_cin_reg <= 0;
        ready_o <= 0;
        res_ok1 <= 1'b0;
    end
    else begin
        case({start_i, res_ok1, ready_o})
            3'b100:begin
                res_ok1 <= 1'b1;
            end
            3'b110:begin
                add_a_reg <= {out_carry[62:0], part_carry_reg[15]};
                add_b_reg <= out_sum;
                add_cin_reg <= part_carry_reg[16];
                ready_o <= 1'b1;
            end
            3'b111:begin
                ready_o <= 1'b0;
                res_ok1 <= 1'b0;
            end
            default:begin
                add_a_reg <= 0;
                add_b_reg <= 0;
                add_cin_reg <= 0;
                ready_o <= 0;
                res_ok1 <= 1'b0;
            end
        endcase
    end
  end
  
  assign result_o = add_a_reg + add_b_reg + add_cin_reg;

endmodule
