`timescale 1ns / 1ps
module mux8 #(parameter WIDTH=32) (
    input wire [WIDTH-1:0] x0, x1, x2, x3, x4, x5, x6, x7,
    input wire [2:0] sel,

    output wire [WIDTH-1:0] y
);
    assign y = sel[2] ? (sel[1] ? (sel[0] ? x7 : x6):
                                  (sel[0] ? x5 : x4)) :
                        (sel[1] ? (sel[0] ? x3 : x2) :
                                  (sel[0] ? x1 : x0))
                ;

endmodule