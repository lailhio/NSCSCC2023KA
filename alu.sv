`include "defines2.vh"
`timescale 1ns / 1ps

module alu(
    input wire clk, rst,stallE,flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [7:0] alucontrolE, 
    input wire [4:0] sa, msbd,
    input wire mfhiE, mfloE, flush_exceptionM, DivMulEnE,
    
    output wire alustallE,
    output reg [31:0] aluoutE, 
    output reg overflowE,
    output reg trapE
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
                overflowE =(src_aE[31]^src_bE[31]) & (aluoutE[31]==src_bE[31]);
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
            `CLO_CONTROL:   aluoutE = ~src_aE[31] ? 32'd0 : ~src_aE[30] ? 32'd1 :
                                    ~src_aE[29] ? 32'd2 : ~src_aE[28] ? 32'd3 :
                                    ~src_aE[27] ? 32'd4 : ~src_aE[26] ? 32'd5 :
                                    ~src_aE[25] ? 32'd6 : ~src_aE[24] ? 32'd7 :
                                    ~src_aE[23] ? 32'd8 : ~src_aE[22] ? 32'd9 :
                                    ~src_aE[21] ? 32'd10 : ~src_aE[20] ? 32'd11 :
                                    ~src_aE[19] ? 32'd12 : ~src_aE[18] ? 32'd13 :
                                    ~src_aE[17] ? 32'd14 : ~src_aE[16] ? 32'd15 :
                                    ~src_aE[15] ? 32'd16 : ~src_aE[14] ? 32'd17 :
                                    ~src_aE[13] ? 32'd18 : ~src_aE[12] ? 32'd19 :
                                    ~src_aE[11] ? 32'd20 : ~src_aE[10] ? 32'd21 :
                                    ~src_aE[9] ? 32'd22 : ~src_aE[8] ? 32'd23 :
                                    ~src_aE[7] ? 32'd24 : ~src_aE[6] ? 32'd25 :
                                    ~src_aE[5] ? 32'd26 : ~src_aE[4] ? 32'd27 :
                                    ~src_aE[3] ? 32'd28 : ~src_aE[2] ? 32'd29 :
                                    ~src_aE[1] ? 32'd30 : ~src_aE[0] ? 32'd31 : 32'd32;
            `CLZ_CONTROL:   aluoutE = src_aE[31] ? 32'd0 : src_aE[30] ? 32'd1 :
                                    src_aE[29] ? 32'd2 : src_aE[28] ? 32'd3 :
                                    src_aE[27] ? 32'd4 : src_aE[26] ? 32'd5 :
                                    src_aE[25] ? 32'd6 : src_aE[24] ? 32'd7 :
                                    src_aE[23] ? 32'd8 : src_aE[22] ? 32'd9 :
                                    src_aE[21] ? 32'd10 : src_aE[20] ? 32'd11 :
                                    src_aE[19] ? 32'd12 : src_aE[18] ? 32'd13 :
                                    src_aE[17] ? 32'd14 : src_aE[16] ? 32'd15 :
                                    src_aE[15] ? 32'd16 : src_aE[14] ? 32'd17 :
                                    src_aE[13] ? 32'd18 : src_aE[12] ? 32'd19 :
                                    src_aE[11] ? 32'd20 : src_aE[10] ? 32'd21 :
                                    src_aE[9] ? 32'd22 : src_aE[8] ? 32'd23 :
                                    src_aE[7] ? 32'd24 : src_aE[6] ? 32'd25 :
                                    src_aE[5] ? 32'd26 : src_aE[4] ? 32'd27 :
                                    src_aE[3] ? 32'd28 : src_aE[2] ? 32'd29 :
                                    src_aE[1] ? 32'd30 : src_aE[0] ? 32'd31 : 32'd32;                      
            // // SEB & SEH
            // `SEB_CONTROL:   aluoutE = {{24{src_bE[7]}}, src_bE[7:0]};
            // `SEH_CONTROL:   aluoutE = {{16{src_bE[15]}}, src_bE[15:0]};

            // `ROTR_CONTROL:  aluoutE = src_bE << (32-sa) + src_bE >> sa;
  
            // `ROTRV_CONTROL: aluoutE = src_bE << (32-src_aE[4:0]) + src_bE >> src_aE[4:0];
 
            // `EXT_CONTROL:   begin
            //     // case: lsb(sa) + msbd > 31
            //     aluoutE = (src_aE << (31-sa-msbd)) >> (31-msbd);                 
            // end
            // `INS_CONTROL:   begin
            //     // case1: lsb > msb
            //     // case2: msb > 31
            //     aluoutE = (src_aE << (31-msbd+sa)) >> (31-msbd) + (src_bE >> (msbd+1)) << (msbd+1) + (src_bE << (32-sa)) >> (32-sa);
            // end
            // `WSBH_CONTROL:  begin
            //     aluoutE = {src_bE[23:16], src_bE[31:24], src_bE[7:0], src_bE[15:8]};
            // end
            `MOVN_CONTROL:  begin
                if(|src_bE) begin
                    aluoutE = src_aE;
                end
                else aluoutE = 32'b0;
            end
            `MOVZ_CONTROL:  begin
                if(~(|src_bE)) begin
                    aluoutE = src_aE;
                end
                else aluoutE = 32'b0;
            end
            `MUL_CONTROL:    begin
                aluoutE = 32'b0;
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv = aluout_mul[31:0];
                    hilo_writeE = 1'b1;
                    aluoutE = aluout_mul[31:0];
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
            `TEQ_CONTROL, `TGE_CONTROL, `TGEU_CONTROL, `TNE_CONTROL,
            `TLT_CONTROL, `TLTU_CONTROL : begin
                aluoutE = 32'b0;
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
    always @(*) begin
        case(alucontrolE)
            `TEQ_CONTROL,   `TEQI_CONTROL: begin
                trapE = src_aE == src_bE;
            end
            `TGE_CONTROL,  `TGEI_CONTROL: begin
                trapE = $signed(src_aE) >= $signed(src_bE);
            end
            `TGEU_CONTROL,  `TGEIU_CONTROL: begin
                trapE = $unsigned(src_aE) >= $unsigned(src_bE);
            end
            `TLT_CONTROL,   `TLTI_CONTROL: begin
                trapE = $signed(src_aE) < $signed(src_bE);
            end
            `TLTU_CONTROL,  `TLTIU_CONTROL: begin
                trapE = $unsigned(src_aE) < $unsigned(src_bE);
            end
            `TNE_CONTROL,   `TNEI_CONTROL: begin
                trapE = src_aE != src_bE;
            end
            default: begin
                trapE = 1'b0;
            end
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
