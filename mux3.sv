`timescale 1ns / 1ps
module mux3 #(parameter WIDTH = 8)(
	input wire[WIDTH-1:0] d0,d1,d2,
	input wire[1:0] s,
	output wire[WIDTH-1:0] out
    );

    assign out = s[1] ? (s[0] ? d2: d2):
                        (s[0] ? d1: d0);
endmodule