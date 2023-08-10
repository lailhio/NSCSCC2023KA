`include "defines2.vh"

module predec(
		input wire[31:0] instrF2,

		output reg branchF2, jumpF2,
        output reg [2:0] branch_judge_control
    );
    //Instruct F2ivide
	reg [5:0] aluop;
	wire [5:0] opF2,functF2;
	wire [4:0] rsF2,rtF2,rdF2,shamtF2;

	assign opF2 = instrF2[31:26];
	assign functF2 = instrF2[5:0];
	assign rsF2 = instrF2[25:21];
	assign rtF2 = instrF2[20:16];
	assign rdF2 = instrF2[15:11];
	assign shamtF2 = instrF2[10:6];

    wire jr, j;
    assign jr = ~(|instrF2[31:26]) & (~|(instrF2[5:1] ^ 5'b00100)); 
    assign j = ~(|(instrF2[31:27] ^ 5'b00001));        
    assign jumpF2 = jr | j; 


    always @(*) begin
		case(opF2)
			`BEQ: begin
                branchF2 = 1;
				branch_judge_control=3'b001;
			end
			`BNE: begin
                branchF2 = 1;
				branch_judge_control=3'b010;
			end
			`BLEZ: begin
                branchF2 = 1;
				branch_judge_control=3'b011;
			end
			`BGTZ: begin
                branchF2 = 1;
				branch_judge_control=3'b100;
			end
			`REGIMM_INST: begin
				case(rtF2)
					`BLTZ,`BLTZAL: begin
                        branchF2 = 1;
						branch_judge_control=3'b101;
					end
					`BGEZ,`BGEZAL: begin
                        branchF2 = 1;
						branch_judge_control=3'b110;
					end
					default:begin
                        branchF2 = 1;
						branch_judge_control=3'b101;
					end
				endcase
				end
			default:begin
                branchF2 = 0;
				branch_judge_control=3'b000;
			end
		endcase
	end
endmodule