`timescale 1ns / 1ps



module datapath(


	input wire clk,rst,
	
	input wire[31:0] instrF,
	
	
	output wire flushE,
	
	output wire[31:0] aluoutM,writedataM,
	//debug interface
//    output wire[31:0] debug_wb_pc,
//    output wire[3:0] debug_wb_rf_wen,
//    output wire[4:0] debug_wb_rf_wnum,
//    output wire[31:0] debug_wb_rf_wdata
    );
	
	//fetch stage
	wire stallF;
	wire[31:0] pcF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	//decode stage
	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;
	wire[2:0] fcD;
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
	//execute stage
	wire memtoregE;
	wire alusrcE,regdstE;
	wire regwriteE;
	wire memwriteE;
	wire[2:0] fcE;
	wire[4:0] alucontrolE;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	//mem stage
	wire [4:0] writeregM;
	wire memtoregM,memwriteM;
	wire[31:0] readdataM;
	wire[2:0] fcM;
	wire regwriteM;
	//writeback stage
	wire memtoregW;
	wire [4:0] writeregW;
	wire regwriteW;
	wire [2:0] fcW;
	wire [31:0] aluoutW,readdataW,resultW;

	maindec md(
		opD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD,
		fcD
		);
	aludec ad(opD,functD,alucontrolD);
	assign pcsrcD = branchD & equalD;

	//pipeline registers
	floprc #(13) regE(
		clk,
		rst,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,fcD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,fcE}
		);
	flopr #(6) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE,fcE},
		{memtoregM,memwriteM,regwriteM,fcM}
		);
	flopr #(5) regW(
		clk,rst,
		{memtoregM,regwriteM,fcM},
		{memtoregW,regwriteW,fcW}
		);
	
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

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	//decode stage
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	signext se(alusrcE,instrD[15:0],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	//execute stage
	floprc #(32) r1E(clk,rst,flushE,srcaD,srcaE);
	floprc #(32) r2E(clk,rst,flushE,srcbD,srcbE);
	floprc #(32) r3E(clk,rst,flushE,signimmD,signimmE);
	floprc #(5) r4E(clk,rst,flushE,rsD,rsE);
	floprc #(5) r5E(clk,rst,flushE,rtD,rtE);
	floprc #(5) r6E(clk,rst,flushE,rdD,rdE);
	floprc #(5) r7E(clk,rst,flushE,saD,saE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,saE,alucontrolE,aluoutE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);

	//mem stage
	wire [31:0] writedataM2;
	reg [31:0] writetempM = 32'b0;
	flopr #(32) r1M(clk,rst,srcb2E,writedataM2);
	flopr #(32) r2M(clk,rst,aluoutE,aluoutM);
	flopr #(5) r3M(clk,rst,writeregE,writeregM);
    
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
    
	//writeback stage
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,readdataM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	
	wire [31:0] readdataWB;
	reg[31:0] readtempW = 32'b0;
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
