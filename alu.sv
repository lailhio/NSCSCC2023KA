`include "defines2.vh"

module alu(
    input wire clk, rst,stallE,flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [7:0] alucontrolE, 
    input wire [4:0] sa, 
    input wire mfhiE, mfloE, flush_exceptionM,
    output reg alustallE,
    output reg [63:0] aluoutE, 
    output reg overflowE
);
    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    wire [31:0] hilo_outE;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    reg [1:0]hilo_selectE;
    reg hilo_writeE;
   
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
            `AND_CONTROL:       aluoutE = src_aE & src_bE;
            `OR_CONTROL:        aluoutE = src_aE | src_bE;
            `NOR_CONTROL:       aluoutE =~(src_aE | src_bE);
            `XOR_CONTROL:       aluoutE = src_aE ^ src_bE;

            `ADD_CONTROL:begin
                aluoutE = {src_aE[31], src_aE} + {src_bE[31], src_bE};
                overflowE= (src_aE[31] == src_bE[31]) & (aluoutE[31] != src_aE[31]);
            end
            `ADDU_CONTROL:      aluoutE = src_aE + src_bE;
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
            `MFHI_CONTROL, `MFLO_CONTROL:begin
                aluoutE = {32'b0, hilo_outE};
            end
            // CLO & CLZ
            `CLO_CONTROL: begin
                aluoutE = 32;
                for(int i = 31;i >= 0;i--) begin
                    if(!src_aE[i]) begin
                        aluoutE = 31-i;
                        break;
                    end
                end
            end
            `CLZ_CONTROL: begin
                aluoutE = 32;
                for(int i = 31;i >= 0;i--) begin
                    if(src_aE[i]) begin
                        aluoutE = 31-i;
                        break;
                    end
                end
            end

            // SEB & SEH
            `SEB_CONTROL:   aluoutE = {{24{src_bE[7]}}, src_bE[7:0]};
            `SEH_CONTROL:   aluoutE = {{16{src_bE[15]}}, src_bE[15:0]};

            // ROTR
            // `ROTR_CONTROL:  aluoutE = {src_bE[sa-1:0], src_bE[31:sa]};

            8'b00000: aluoutE = src_aE;  // do nothing

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

    // hilo
    hilo hilo(clk,rst, hilo_selectE , hilo_writeE & ~flush_exceptionM , mfhiE ,mfloE , aluoutE , hilo_outE );
endmodule
