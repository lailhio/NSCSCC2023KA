
module branch_check (
    input wire [2:0] branch_judge_controlE,
    input wire [31:0] src_aE, src_bE,

    output reg actual_takeE
);
    always @(*) begin
        // 根据对应操作计算
        case(branch_judge_controlE)
            3'b001:        actual_takeE = ~(|(src_aE ^ src_bE));
            3'b010:       actual_takeE = |(src_aE ^ src_bE);
            3'b100:       actual_takeE = ~src_aE[31] & (|src_aE);
            3'b110:       actual_takeE = ~src_aE[31];
            3'b101:       actual_takeE = src_aE[31];
            3'b011:       actual_takeE = src_aE[31] | ~(|src_aE);
            default:
                actual_takeE = 1'b0;
        endcase
    end
endmodule