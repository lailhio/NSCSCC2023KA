`include "defines2.vh"

module alu_new(
    input wire clk, rst,stallE,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [7:0] alucontrolE, 
    input wire [4:0] sa, 
    
    output reg hilo_writeE,
    output reg [1:0]hilo_selectE,
    output reg alustallE,
    output reg [63:0] aluoutE, 
    output reg overflowE
);
    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;

   
    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
        alustallE = 1'b0;
        overflowE = 1'b0;
        hilo_writeE = 1'b0;
        hilo_selectE = 2'b00;
        case(alucontrolE)
            `ALU_ADD:begin
                aluoutE = {src_aE[31], src_aE} + {src_bE[31], src_bE};
                overflowE= (src_aE[31] == src_bE[31]) & (aluoutE[31] != src_aE[31]);
            end
            `ALU_ADDU:      aluoutE = src_aE + src_bE;
            `ALU_AND:       aluoutE = src_aE & src_bE;
            `ALU_CLO: begin
                y = 32;
                for(i=31;i>=0;i--) begin // FIXME: 可以直接写for循环吗
                    if(!a[i]) begin
                        y = 31-i;
                        break;
                    end
                end
                aluoutE = y;
            end
            `ALU_CLZ: begin
                y = 32;
                for(i=31;i>=0;i--) begin
                    if(a[i]) begin
                        y = 31-i;
                        break;
                    end
                end
                aluoutE = y;
            end
            `ALU_DIV:begin
                div_sign = 1'b1;
                div_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    alustallE = 1'b0;
                    aluoutE = aluout_div;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end
            `ALU_DIVU :begin
                div_sign = 1'b0;
                div_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    alustallE = 1'b0;
                    aluoutE = aluout_div;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end

            `OR_CONTROL:        aluoutE = src_aE | src_bE;
            `NOR_CONTROL:       aluoutE =~(src_aE | src_bE);
            `XOR_CONTROL:       aluoutE = src_aE ^ src_bE;


            `SUB_CONTROL:begin
                aluoutE= {src_aE[31], src_aE} - {src_bE[31], src_bE};
                overflowE =(src_aE[31]^src_bE[31]) & (aluoutE[31]==src_bE[31]);;
            end
            `SUBU_CONTROL:      aluoutE = src_aE - src_bE;

            `SLT_CONTROL:       aluoutE = $signed(src_aE) < $signed(src_bE); 
            `SLTU_CONTROL:      aluoutE = src_aE < src_bE; 
            //Mov Cmd
            `SLLV_CONTROL:       aluoutE = src_bE << src_aE[4:0]; 
            `SRLV_CONTROL:       aluoutE = src_bE >> src_aE[4:0];
            `SRAV_CONTROL:       aluoutE = $signed(src_bE) >>> src_aE[4:0];

            `SLL_CONTROL:    aluoutE = src_bE << sa; 
            `SRL_CONTROL:    aluoutE = src_bE >> sa;
            `SRA_CONTROL:    aluoutE = $signed(src_bE) >>> sa;

            `LUI_CONTROL:       aluoutE = {src_bE[15:0], 16'b0};
            `MULT_CONTROL  : begin
                mul_sign = 1'b1;
                mul_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_mul) begin 
                    alustallE = 1'b0;
                    mul_startE = 1'b0;
                    aluoutE = aluout_mul;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end
            `MULTU_CONTROL  : begin
                mul_sign = 1'b0;
                mul_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    alustallE = 1'b0;
                    aluoutE = aluout_mul;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end
            `DIV_CONTROL :begin
                div_sign = 1'b1;
                div_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    alustallE = 1'b0;
                    aluoutE = aluout_div;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end
            `DIVU_CONTROL :begin
                div_sign = 1'b0;
                div_startE = 1'b1;
                alustallE = 1'b1;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    alustallE = 1'b0;
                    aluoutE = aluout_div;
                    if(~stallE) hilo_writeE = 1'b1;
                end
            end
            `MTHI_CONTROL: begin
                aluoutE = {src_aE, 32'b0};
                hilo_selectE = 2'b11;
                if(~stallE) hilo_writeE = 1'b1;
            end
            `MTLO_CONTROL: begin
                aluoutE = {32'b0, src_aE};
                hilo_selectE = 2'b10;
                if(~stallE) hilo_writeE = 1'b1;
            end
            5'b00000: aluoutE = src_aE;  // do nothing

            default:    aluoutE = 32'b0;
        endcase
    end


    mul mul(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  
		.opdata2_i(src_bE),  
		.start_i(mul_startE),
		.signed_mul_i(mul_sign),   

		.ready_o(ready_mul),
		.result_o(aluout_mul)
	);
    

	div div(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  //divident
		.opdata2_i(src_bE),  //divisor
		.start_i(div_startE),
        .annul_i(0),
		.signed_div_i(div_sign),   //1 signed

		// .ready_div(ready_div),
		.ready_o(ready_div),
		.result_o(aluout_div)
	);

endmodule