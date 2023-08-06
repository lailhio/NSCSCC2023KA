`include "defines2.vh"
`timescale 1ns / 1ps

module div(
	input wire clk,
	input wire rst,
	input wire flush,
	input wire signed_div_i,
	input wire[31:0] opdata1_i,
	input wire[31:0] opdata2_i,
	input wire start_i,
	input wire annul_i,
	
	output reg[63:0] result_o,
	output reg ready_o
);
	wire[32:0] div_temp;
	reg[5:0] cnt;
	reg[64:0] dividend;
	reg[1:0] state;
	reg[31:0] divisor;	 
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	reg[31:0] save_op_1;
	reg[31:0] save_op_2;

	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if ((rst == `RstEnable )|flush) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
		end else begin
		  case (state)
		  	`DivFree:begin               //DivFree״̬
		  		if(start_i == `DivStart && annul_i == 1'b0) begin
		  			if(opdata2_i == `ZeroWord) begin
		  				state <= `DivByZero;
		  			end 
					else begin
		  				state <= `DivOn;
		  				cnt <= 6'b000000;
		  				if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
		  					temp_op1 = ~opdata1_i + 1;
		  				end else begin
		  					temp_op1 = opdata1_i;
		  				end
		  				if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
		  					temp_op2 = ~opdata2_i + 1;
		  				end else begin
		  					temp_op2 = opdata2_i;
		  				end
		  				save_op_1<=opdata1_i;
		  				save_op_2<=opdata2_i;
		  				dividend <= {`ZeroWord,`ZeroWord};
              			dividend[32:1] <= temp_op1;
              			divisor <= temp_op2;
             		end
          		end 
				else begin
					ready_o <= `DivResultNotReady;
					result_o <= {`ZeroWord,`ZeroWord};
				end          	
		  	end
		  	`DivByZero:		begin               //DivByZero״̬
	         	dividend <= {`ZeroWord,`ZeroWord};
	          	state <= `DivEnd; 		
		  	end
		  	`DivOn:	begin               //DivOn״̬
		  		if(annul_i == 1'b0) begin
		  			if(cnt != 6'b100000) begin
                		if(div_temp[32] == 1'b1) begin
                  			dividend <= {dividend[63:0] , 1'b0};
               			end 
						else begin
                    	dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
               			end
               			cnt <= cnt + 1;
             		end 
					else begin
                		if((signed_div_i) & ((save_op_1[31] ^ save_op_2[31]))) begin
                  			dividend[31:0] <= (~dividend[31:0] + 1);
               			end
               			if((signed_div_i) & ((save_op_1[31] ^ dividend[64]))) begin              
                  			dividend[64:33] <= (~dividend[64:33] + 1);
               			end
                		state <= `DivEnd;
                		cnt <= 6'b000000;            	
            		end
		  		end 
				else begin
		  			state <= `DivFree;
		  		end	
		  	end
		  	`DivEnd:begin               //DivEnd״̬
        		result_o <= {dividend[64:33], dividend[31:0]};  
          		ready_o <= `DivResultReady;
          		if(start_i == `DivStop) begin
          			state <= `DivFree;
					ready_o <= `DivResultNotReady;
					result_o <= {`ZeroWord,`ZeroWord};       	
          		end		  	
		  	end
		  endcase
		end
	end

endmodule