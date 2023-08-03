module mux9 #(parameter WIDTH=32) (
    input wire [WIDTH-1:0] x0, x1, x2, x3, x4, x5, x6, x7, x8,
    input wire [3:0] sel,

    output wire [WIDTH-1:0] y
);

    assign y = (sel[3]) ? 
                (sel[2] ? (sel[1] ? (sel[0] ? x8 : x7) : (sel[0] ? x6 : x5)) : 
                          (sel[1] ? (sel[0] ? x4 : x3) : (sel[0] ? x2 : x1))) :
                (sel[2] ? (sel[1] ? (sel[0] ? x0 : x8) : (sel[0] ? x7 : x6)) : 
                          (sel[1] ? (sel[0] ? x5 : x4) : (sel[0] ? x3 : x2)));

endmodule
