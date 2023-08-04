`include "defines2.vh"

module alu1(
    input wire clk, rst,
    input wire [31:0] src_aE, src_bE,
    input wire [7:0] alucontrolE, 
    input wire [63:0] hilo_out,
    output reg [31:0] aluoutE, 
    output reg overflowE,
    output reg trapE
);

    always @(*) begin
        overflowE = 1'b0;
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
            `SLLV_CONTROL:       aluoutE = src_bE << src_aE[4:0]; 
            `SRLV_CONTROL:       aluoutE = src_bE >> src_aE[4:0];
            `SRAV_CONTROL:       aluoutE = $signed(src_bE) >>> src_aE[4:0];

            `SLL_CONTROL:    aluoutE = src_bE << sa; 
            `SRL_CONTROL:    aluoutE = src_bE >> sa;
            `SRA_CONTROL:    aluoutE = $signed(src_bE) >>> sa;
            `LUI_CONTROL:       aluoutE = {src_bE[15:0], 16'b0};
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
            `MFHI_CONTROL:begin
                aluoutE = hilo_outE[63:32];
            end
            `MFLO_CONTROL:begin
                aluoutE = hilo_outE[31:0];
            end
            // `TEQ_CONTROL, `TGE_CONTROL, `TGEU_CONTROL, `TNE_CONTROL,
            // `TLT_CONTROL, `TLTU_CONTROL : begin
            //     aluoutE = 32'b0;
            // end

            8'b00000000: aluoutE = src_aE;  // do nothing

            default:    aluoutE = 32'b0;
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
endmodule
