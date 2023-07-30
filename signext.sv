module signext(
    input wire pcsrc,
	input wire[15:0] a,
	output wire[31:0] y
    );

	assign y = pcsrc ? {{16{a[15]}},a}:{{16{1'b0}},a};
endmodule
