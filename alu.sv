`include "defines2.vh"

module alu(
    input wire clk, rst,stallE,flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [7:0] alucontrolE, 
    input wire [4:0] sa, msbd,
    input wire mfhiE, mfloE, flush_exceptionM, DivMulEnE,
    
    output wire alustallE,
    output reg [31:0] aluoutE, 
    output reg overflowE
);
    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    reg [63:0] hilo_in_muldiv;
    wire [63:0] hilo_outE;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    reg [1:0]hilo_selectE;
    reg hilo_writeE;
   
    assign alustallE = DivMulEnE & ~ready_div & ~ready_mul;

    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
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
                aluoutE = 32'b0;
                mul_sign = 1'b1;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MULTU_CONTROL  : begin
                aluoutE = 32'b0;
                mul_sign = 1'b0;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `DIV_CONTROL :begin
                aluoutE = 32'b0;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    // hilo_in_muldiv = aluout_div;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_sign = 1'b1;
                    div_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `DIVU_CONTROL :begin
                aluoutE = 32'b0;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    // hilo_in_muldiv = aluout_div;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_sign = 1'b0;
                    div_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MTHI_CONTROL: begin
                aluoutE = 32'b0;
                // hilo_in_muldiv = {src_aE, 32'b0};
                hilo_selectE = 2'b11;
                hilo_writeE = 1'b1;
            end
            `MTLO_CONTROL: begin
                aluoutE = 32'b0;
                // hilo_in_muldiv = {32'b0, src_aE};
                hilo_selectE = 2'b10;
                hilo_writeE = 1'b1;
            end
            `MFHI_CONTROL, `MFLO_CONTROL:begin
                // aluoutE = {32'b0, hilo_outE};
                aluoutE = ({32{mfhiE}} & hilo_outE[63:32]) | ({32{mfloE}} & hilo_outE[31:0]);
            end
            // // CLO & CLZ
            // `CLO_CONTROL: begin
            //     aluoutE = 32;
            //     for(int i = 31;i >= 0;i--) begin
            //         if(!src_aE[i]) begin
            //             aluoutE = 31-i;
            //             break;
            //         end
            //     end
            // end
            // `CLZ_CONTROL: begin
            //     aluoutE = 32;
            //     for(int i = 31;i >= 0;i--) begin
            //         if(src_aE[i]) begin
            //             aluoutE = 31-i;
            //             break;
            //         end
            //     end
            // end

            // SEB & SEH
            `SEB_CONTROL:   aluoutE = {{24{src_bE[7]}}, src_bE[7:0]};
            `SEH_CONTROL:   aluoutE = {{16{src_bE[15]}}, src_bE[15:0]};

            // `ROTR_CONTROL:  aluoutE = src_bE << (32-sa) + src_bE >> sa;
            // `ROTR_CONTROL:  begin
            //     // exception?
            //     for(int i = 0;i <= 31;i++) begin
            //         if(i < sa) begin
            //             aluoutE[32-sa+i] = src_bE[i];
            //         end
            //         else begin
            //             aluoutE[i-sa] = src_bE[i]; 
            //         end
            //     end
            // end
            // // `ROTRV_CONTROL: aluoutE = src_bE << (32-src_aE[4:0]) + src_bE >> src_aE[4:0];
            // `ROTRV_CONTROL:  begin
            //     // exception?
            //     for(int i = 0;i <= 31;i++) begin
            //         if(i < src_aE[4:0]) begin
            //             aluoutE[32-src_aE[4:0]+i] = src_bE[i];
            //         end
            //         else begin
            //             aluoutE[i-src_aE[4:0]] = src_bE[i];
            //         end
            //     end
            // end

            // `EXT_CONTROL:   begin
            //     // case: sa + msbd > 31
            //     aluoutE = 0;
            //     for(int i = sa;i <= sa + msbd;i++) begin
            //         aluoutE[i-sa] = src_aE[i];
            //     end
            // end
            // `INS_CONTROL:   begin
            //     // case1: lsb > msb
            //     // case2: msb > 31
            //     aluoutE = src_bE;
            //     for(int i = sa;i <= msbd;i++) begin
            //         aluoutE[i] = src_aE[i-sa];
            //     end
            // end
            `WSBH_CONTROL:  begin
                aluoutE = {src_bE[23:16], src_bE[31:24], src_bE[7:0], src_bE[15:8]};
            end
            // `MOVN_CONTROL:  begin
            //     if(src_bE) begin
            //         aluoutE = src_aE;
            //     end
            // end
            // `MOVZ_CONTROL:  begin
            //     if(!src_bE) begin
            //         aluoutE = src_aE;
            //     end
            // end
            `MUL_CONTROL:    begin
                aluoutE = 32'b0;
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = aluout_mul[31:0];
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MADD_CONTROL:  begin
                aluoutE = 32'b0;
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = hilo_outE + aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MADDU_CONTROL: begin
                aluoutE = 32'b0;
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = hilo_outE + aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MSUB_CONTROL:  begin
                aluoutE = 32'b0;
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = hilo_outE - aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end
            `MSUBU_CONTROL:  begin
                aluoutE = 32'b0;
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = hilo_outE - aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv = 64'b0;
                end
            end

            8'b00000: aluoutE = src_aE;  // do nothing

            default:    aluoutE = 32'b0;
        endcase
    end
    always @(*) begin
        case(alucontrolE)
            `MULT_CONTROL, `MULTU_CONTROL, `MUL_CONTROL  : begin
                hilo_in_muldiv = aluout_mul;
            end
            `DIV_CONTROL, `DIVU_CONTROL :begin
                hilo_in_muldiv = aluout_div;
            end
            `MTHI_CONTROL: begin
                hilo_in_muldiv = {src_aE, 32'b0};
            end
            `MTLO_CONTROL: begin
                hilo_in_muldiv = {32'b0, src_aE};
            end
            `MADD_CONTROL:  begin
                hilo_in_muldiv = hilo_outE + aluout_mul;
            end
            `MADDU_CONTROL: begin
                hilo_in_muldiv = hilo_outE + aluout_mul;
            end
            `MSUB_CONTROL:  begin
                hilo_in_muldiv = hilo_outE - aluout_mul;
            end
            `MSUBU_CONTROL:  begin
                hilo_in_muldiv = hilo_outE - aluout_mul;
            end
            default:    hilo_in_muldiv = 64'b0;
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
    hilo hilo(clk,rst, hilo_selectE , hilo_writeE & ~flush_exceptionM , mfhiE ,mfloE , hilo_in_muldiv , hilo_outE );

endmodule
