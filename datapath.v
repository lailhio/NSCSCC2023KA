`timescale 1ns / 1ps



module datapath(

	input wire clk,rst,
	
	input wire[31:0] instrF,
	
	
	output wire flushE,
	
	output wire[31:0] aluoutM,writedataM
	//debug interface
//    output wire[31:0] debug_wb_pc,
//    output wire[3:0] debug_wb_rf_wen,
//    output wire[4:0] debug_wb_rf_wnum,
//    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------fetch stage----------
	wire stallF;
    wire [31:0] pcF, pcnextFD,pcnextbrFD, pcplus4F;
	wire [31:0] pcbranchD;
	wire pc_reg_ceF;
    wire [2:0] pc_sel;
    wire [31:0] instrF_temp;
    wire is_in_delayslot_iF;
// wire pcerrorD, pcerrorE, pcerrorM; 
	//----------decode stage---------
	wire[3:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD;
	wire [31:0] rd1D, rd2D;
	wire [31:0] pcD, pc_plus4D;
	wire is_in_delayslot_iD;
	wire[4:0] alucontrolD;
	wire jump_conflictD;
	wire pred_takeD;
	wire pcsrcD,branchD;
	wire jumpD;
	wire equalD;
	wire[5:0] opD,functD;
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire [31:0] immD;
    wire sign_exD;
    wire [31:0] pc_branchD;
    wire flush_pred_failedM;
    wire [31:0] pc_jumpD;
    wire [4:0] branch_judge_controlD;
	//-------execute stage----------

	wire [31:0] pcE;
    wire [31:0] rd1E, rd2E, mem_wdataE;
    wire [4:0] rsE, rtE, rdE, saE;
    wire [31:0] immE;
    wire [31:0] pc_plus4E;
    wire pred_takeE;
    wire [31:0] src_aE, src_bE;
    wire [63:0] alu_outE;
    wire alu_imm_selE;
    wire [31:0] instrE;
    wire branchE;
    wire [31:0] pc_branchE;
    wire [31:0] pc_jumpE;
    wire jump_conflictE;
    wire div_stallE;
    wire [31:0] rs_valueE, rt_valueE;
    wire flush_jump_confilctE;
    wire is_in_delayslot_iE;
    wire overflowE;
    wire jumpE;
    wire actual_takeE;
    wire [4:0] branch_judge_controlE;
	wire memtoregE;
	wire alusrcE;
	wire [1:0] reg_dstE;
	wire regwriteE;
	wire memwriteE;
	wire[4:0] alucontrolE;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	//----------mem stage--------
	 wire [31:0] pcM;
    wire [31:0] alu_outM;
    wire [31:0] instrM;
    wire mem_read_enM;
    wire [31:0] resultM;
    wire actual_takeM;
    wire succM;
    wire pred_takeM;
    wire branchM;
    wire [31:0] pc_branchM;

    wire [31:0] mem_ctrl_rdataM;
    wire [31:0] mem_wdataM_temp;
    wire [31:0] mem_ctrl_rdataM;

    wire hilo_wenE;
    wire [63:0] hilo_oM;
    wire hilo_to_regM;
    wire riM;
    wire breakM;
    wire syscallM;
    wire eretM;
    wire overflowM;
    wire addrErrorLwM, addrErrorSwM;
    wire pcErrorM;

    wire [31:0] except_typeM;
    wire [31:0] cp0_statusM;
    wire [31:0] cp0_causeM;
    wire [31:0] cp0_epcM;

    wire flush_exceptionM;
    wire [31:0] pc_exceptionM;
    wire pc_trapM;
    wire [31:0] badvaddrM;
    wire is_in_delayslot_iM;
    wire [4:0] rdM;
    wire cp0_to_regM;
    wire mem_error_enM;
    wire cp0_wenM;
    
	//------writeback stage----------
	wire memtoregW;
	wire [4:0] writeregW;
	wire regwriteW;
	wire [31:0] aluoutW,readdataW,resultW;
	wire [31:0] pcW;
    wire [31:0] alu_outW;

    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_data_oW;
//-----------------Data--------------------

	

	//-----------Decode----------------
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	maindec md(
		instrD,
		//Instruct decode
		sign_exD,
		//Execute
		reg_dstD,is_immD,
		reg_write_enD,
		hilo_wenD,
		//Mem
		mem_readD, mem_writeD,
		reg_write_enD,mem_to_regD,
		hilo_to_regD,riD,
		breakD, syscallD, eretD, 
		cp0_wenD,
		cp0_to_regD,
		aluopD
		);
	aludec ad(funct,aluopD,alucontrol);

	assign pcsrcD = branchD & equalD;
	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	Fetch_Decode Fe_De(clk,rst,stallD,flushD,
				pcplus4F,instrF,
				pcplus4D,instrD);
	//-----------Execute----------------
	Decode_Execute De_Ex(
		clk,rst,flushE,
		srcaD,srcbD,signimmD,rsD,rtD,rdD,saD,
		memtoregD,memwriteD,alusrcD,regdstD,regwriteD,
		alucontrolD,fcD,
		srcaE,srcbE,signimmE,rsE,rtE,rdE,saE,
		memtoregE,memwriteE,alusrcE,regdstE,regwriteE,
		alucontrolE,fcE
    );
	//----------Mem---------------------
	Execute_Mem Ex_Me(
		clk,rst,
		srcb2E,aluoutE,writeregE,
		memtoregE,memwriteE,regwriteE,
		fcE,
		writedataM2,aluoutM,writeregM,
		memtoregM,memwriteM,regwriteM,
    	fcM
    );
	//---------Write_Back----------------
	Mem_WriteBack Me_Wr(
		clk,rst,
		aluoutM,readdataM,writeregM,
		memtoregM,regwriteM,
		fcM,
		aluoutW,readdataW,writeregW,
		memtoregW,regwriteW,
		fcW
    );
	
	wire [31:0] readdataWB;
	reg[31:0] readtempW = 32'b0;
	//mem stage
	wire [31:0] writedataM2;
	reg [31:0] writetempM = 32'b0;
	
	
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		//write back stage
		writeregW,
		regwriteW
		);
	//--------------------debug---------------------
//    assign debug_wb_pc          = pcplus4D;
//    assign debug_wb_rf_wen      = {4{regwriteM & ~flushE }};
//    assign debug_wb_rf_wnum     = regwriteM;
//    assign debug_wb_rf_wdata    = resultW;


	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD);

	

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	signext se(alusrcE,instrD[15:0],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,equalD);


	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,saE,alucontrolE,aluoutE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);

	
    
    assign writedataM = writetempM;
    always @(*) begin
        case(fcM)
            //SW
            3'b111: 
            begin 
                writetempM  = writedataM2;
            end
            //SH
            3'b110: 
            begin
                writetempM  = {16'b0,{writedataM2[15:0]}};
            end
            //SB
            3'b101: 
            begin
                writetempM  = {24'b0,{writedataM2[7:0]}};
            end
            
            default: 
            begin
                writetempM  = writedataM2;
            end
        endcase
    end
    
	
	always @(*) begin
	   case(fcW)
	       //LB
	       3'b000: begin
	           readtempW  = {{24{readdataW[7]}},readdataW[7:0]};
	       end
	       //LBU
	       3'b001: begin
	       	   readtempW  = {24'b0,readdataW[7:0]};
	       end
	       //LH
	       3'b010: begin
	       	   readtempW  = {{16{readdataW[7]}},readdataW[15:0]};
	       end
	       //LHU
	       3'b011: begin
	           readtempW  = {16'b0,readdataW[15:0]};
	       end
	       //LW
	       3'b100: begin
	           readtempW  = readdataW;
	       end
	       default: begin
	           readtempW  = readdataW;
	       end
	   endcase
	end
    assign readdataWB = readtempW;
	mux2 #(32) resmux(aluoutW,readdataWB,memtoregW,resultW);
endmodule
