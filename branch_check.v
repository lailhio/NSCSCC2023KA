
module branch_check (
    input wire [2:0] branch_judge_controlE,
    input wire [31:0] rs_valueE, rt_valueE,

    output reg actual_takeE
);
    always @(*) begin
        // 根据对应操作计算
        case(branch_judge_controlE)
            3'b001:       actual_takeE = ~(|(rs_valueE ^ rt_valueE));
            3'b010:       actual_takeE = |(rs_valueE ^ rt_valueE);
            3'b100:       actual_takeE = ~rs_valueE[31] & (|rt_valueE);
            3'b110:       actual_takeE = ~rs_valueE[31];
            3'b101:       actual_takeE = rs_valueE[31];
            3'b011:       actual_takeE = rs_valueE[31] | ~(|rt_valueE);
            default:
                actual_takeE = 1'b0;
        endcase
    end
endmodule