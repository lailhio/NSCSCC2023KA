`include "defines2.vh"
`timescale 1ns / 1ps

//cp0 status
`define IE_BIT 0              //
`define EXL_BIT 1
`define BEV_BIT 22
`define IM7_IM0_BITS  15:8
//cp0 cause
`define BD_BIT 31             //延迟槽
`define TI_BIT 30             //计时器中断指示
`define IP1_IP0_BITS 9:8      //软件中断位
`define IP7_IP2_BITS 15:10      //软件中断位
`define EXC_CODE_BITS 6:2     //异常编码

module cp0_exception(
    input wire clk,
	input wire rst,
	input wire stallM2,
	input wire we_i,
	input[4:0] waddr_i,
	input[4:0] raddr_i,
	input[2:0] sel_addr,
	input[`RegBus] data_i,

	input wire[5:0] int_i,

	input wire[`RegBus] current_inst_addr_i,
	input wire is_in_delayslot_i,

    input ri, break_exception, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
    input trap,
   //tlb exception
   input wire mem_read_enM,
   input wire mem_write_enM,
   input wire inst_tlb_refill,
   input wire inst_tlb_invalid,
   input wire data_tlb_refill,
   input wire data_tlb_invalid,
   input wire data_tlb_modify,
    input [31:0] aluoutM,

	// tlb处理
      input wire [3:0] tlb_typeM,                 //tlb写cp0使能
      input wire [31:0] entry_lo0_in,
      input wire [31:0] entry_lo1_in,
      input wire [31:0] page_mask_in,
      input wire [31:0] entry_hi_in,
      input wire [31:0] index_in,

      //cp0寄存器输出
      output wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_ebaseW,
      output wire [31:0] entry_hi_W, 
      output wire [31:0] page_mask_W,
      output wire [31:0] entry_lo0_W,
      output wire [31:0] entry_lo1_W,
      output wire [31:0] index_W,
	output reg[`RegBus] cause_o,
	output reg[`RegBus] data_o,
	output wire[`RegBus] count_o,
	output wire[`RegBus] random_o,

    output flush_exception,  //是否有异常?
    output [31:0] pc_exception,  //pc异常处理地址
    output pc_trap, interupt //是否trap
);

    reg[`RegBus] status_o;
    reg[`RegBus] epc_o;
    reg[`RegBus] ebase_reg;
    wire [`RegBus] excepttype_i;
    wire [`RegBus] bad_addr_i;

    reg timer_int_o;

    reg[`RegBus] compare_o;
	reg[`RegBus] prid_o;
	reg[`RegBus] badvaddr;
	reg[`RegBus] config_o;
	logic [31:0]    prid = 32'h00018003;
	logic [31:0] random_reg;
	logic [31:0] wired_reg;
	reg [32:0] count;
   reg [31:0] index_reg;
reg [31:0] entry_hi_reg;
   reg [31:0] entry_lo0_reg;
   reg [31:0] entry_lo1_reg;
   reg [31:0] page_mask_reg;

	// reg [31:0] EntryHi;
	// reg [31:0] PageMask;
	// reg [31:0] EntryLo0;
	// reg [31:0] EntryLo1;
	// reg [31:0] Index;
	//TLB
   wire tlb_mod, tlb_tlbl, tlb_tlbs;
   assign tlb_mod = data_tlb_modify;
   assign tlb_tlbl = inst_tlb_refill | inst_tlb_invalid | mem_read_enM & (data_tlb_refill | data_tlb_invalid);
   assign tlb_tlbs = mem_write_enM & (data_tlb_refill | data_tlb_invalid);
	assign count_o = count[32:1];
	assign random_o = random_reg;
	assign entry_hi_W    =  entry_hi_reg;
   assign page_mask_W   =  page_mask_reg;
   assign entry_lo0_W   =  entry_lo0_reg;
   assign entry_lo1_W   =  entry_lo1_reg;
   assign index_W       =  index_reg;
       //             //IE             //EXL            
	assign interupt =   status_o[0] && ~status_o[1] && (
						//IM                 //IP
					( |(status_o[9:8] & cause_o[9:8]) ) ||        //soft interupt
					( |(status_o[15:10] & cause_o[15:10]) )||     //硬件中断
					(|(status_o[30] & cause_o[30]))            //计时器中断?
	);

	assign excepttype_i =    (interupt)                   ? 32'h00000001 :    //中断
	inst_tlb_refill | inst_tlb_invalid ? 32'h00000002 :
	mem_read_enM & (data_tlb_refill | data_tlb_invalid) ? 32'h00000002 :
	mem_write_enM & (data_tlb_refill | data_tlb_invalid)? 32'h00000003 :
                           data_tlb_modify ? 32'h00000006 :
							(addrErrorLw | pcError) ? 32'h00000004 :   //地址错误例外（lw地址 pc错误
							(ri)                    ? 32'h0000000a :     //保留指令例外（指令不存在
							(syscall)               ? 32'h00000008 :    //系统调用例外（syscall指令
							(break_exception)       ? 32'h00000009 :     //断点例外（break指令
							(addrErrorSw)           ? 32'h00000005 :   //地址错误例外（sw地址异常
							(overflow)              ? 32'h0000000c :     //算数溢出例外
							(trap)                  ? 32'h0000000d :     //自陷异常
							(eretM)                 ? 32'h0000000e :   //eret指令
														32'h00000000 ;   //无异常?
	//interupt pc address
	   wire BEV;
   assign BEV = status_o[22];

   wire tlb_refill;
   assign tlb_refill = inst_tlb_refill | data_tlb_refill;

   wire [31:0] base, offset;

   assign base   = BEV ? 32'hbfc0_0200 : ebase_reg;
   assign offset = tlb_refill ? 32'b0 : 32'h180;

   assign pc_exception = eretM ? epc_o : base + offset;
	// assign pc_exception =      ((excepttype_i == 32'h00000000)) ? `ZeroWord:
	// 													(eretM)  ? epc_o :
	// 												~status_o[22] ? ebase_reg+32'h180:
	// 															32'hbfc0_0380; //异常处理地址
	assign pc_trap =        (excepttype_i != 32'h00000000); //表示发生异常，需要处理pc
	assign flush_exception =   (excepttype_i != 32'h00000000); //无异常时，为0
	assign bad_addr_i =    (pcError | inst_tlb_invalid | inst_tlb_refill) ? current_inst_addr_i : aluoutM;  //出错时的pc 


    always @(posedge clk) begin
		if(rst == `RstEnable) begin
			count <= 0;
			compare_o <= `ZeroWord;
			status_o <= 32'b00000000010000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			config_o <= 32'b00000000000000001000000000000000;
			prid_o <= 32'h00018003;
			timer_int_o <= `InterruptNotAssert;
			random_reg <= `TLB_LINE_NUM - 1;
			wired_reg <= 0;
        	ebase_reg <= 32'h80000000;
		end 
		else begin
			count <= count + 1;
			random_reg <= (random_reg == wired_reg) ? (`TLB_LINE_NUM - 1) : (random_reg - 1);
			cause_o[`IP7_IP2_BITS] <= ~stallM2 ? int_i : 0;
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				/* code */
				timer_int_o <= `InterruptAssert;
			end
			if(~stallM2 & we_i) begin
				/* code */
				case (waddr_i)
					`CP0_REG_COUNT:begin 
						count[32:1] <= data_i;
					end
					`CP0_REG_COMPARE:begin 
						compare_o <= data_i;
					end
					`CP0_REG_STATUS:begin 
						status_o <= data_i;
					end
					`CP0_REG_CAUSE:begin 
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_WIRED: begin
						wired_reg <= {{(32-$clog2(`TLB_LINE_NUM)){1'b0}},data_i[$clog2(`TLB_LINE_NUM)-1:0]};
						random_reg <= `TLB_LINE_NUM-1;
					end
					`CP0_REG_PRID: begin
						if (sel_addr == 1) begin
							ebase_reg[29:0] <= data_i[29:0];
						end
					end
					`CP0_REG_EPC:begin 
						epc_o <= data_i;
					end
					default : /* default */;
				endcase
			end
			case (excepttype_i)
				32'h00000001:begin // 中断（其实写入的cause)
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				32'h00000002:begin // TLBL
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00010;
					badvaddr <= bad_addr_i;
				end
				32'h00000003:begin // TLBS
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00011;
					badvaddr <= bad_addr_i;
				end
				32'h00000004:begin // 取指非对齐或Load非对齐
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					badvaddr <= bad_addr_i;
				end
				32'h00000005:begin // Store非对齐
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					badvaddr <= bad_addr_i;
				end
				32'h00000008:begin // Syscall异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				32'h00000009:begin // BREAK异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01001;
				end
				32'h0000000a:begin // 保留指令（译码失败）
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				32'h0000000c:begin // ALU溢出异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;
				end
				32'h0000000d:begin // 自陷指令（不在57条中）
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				32'h0000000e:begin // eret异常（准确说不叫异常，但通过这个在跳转到epc的同时清零status的EXL?
					status_o[1] <= 1'b0;
				end
				default : /* default */;
			endcase
		end
	end
   //index, entry_hi/lo, page_mask
   wire mtc0_index, mtc0_entry_lo0, mtc0_entry_lo1, mtc0_entry_hi, mtc0_page_mask;
      //1. mtc0写
   assign mtc0_index     = we_i & (waddr_i == `CP0_REG_INDEX);
   assign mtc0_entry_hi  = we_i & (waddr_i == `CP0_REG_ENTRYHI);
   assign mtc0_entry_lo0 = we_i & (waddr_i == `CP0_REG_ENTRYLO0);
   assign mtc0_entry_lo1 = we_i & (waddr_i == `CP0_REG_ENTRYLO1);
   assign mtc0_page_mask = we_i & (waddr_i == `CP0_REG_PAGEMASK);
      //2. tlb指令写
   wire tlbr, tlbp, tlbwi, tlbwr;
   assign {tlbwr, tlbwi, tlbr, tlbp} = tlb_typeM;
      //3. 异常更新 entry_hi
   wire tlb_exception;
   assign tlb_exception = excepttype_i==2 | excepttype_i == 3 | excepttype_i == 6; //EXC_CODE_MOD, EXC_CODE_TLBL, EXC_CODE_TLBS

   always@(posedge clk) begin
      if(rst) begin
         index_reg <= 0;
         entry_lo0_reg <= 0;
         entry_lo1_reg <= 0;
         entry_hi_reg <= 0;
         page_mask_reg <= 0;
      end
      else begin
         index_reg[31]              <= tlbp           ? index_in[31] : index_reg[31];

         index_reg[`INDEX_BITS]     <= tlbp           ? index_in[`INDEX_BITS] :
                                       mtc0_index     ? data_i[`INDEX_BITS] : index_reg[`INDEX_BITS];

         entry_lo0_reg[`PFN_BITS]   <= tlbr           ? entry_lo0_in[`PFN_BITS] & ~page_mask_in[`MASK_BITS]:
                                       mtc0_entry_lo0 ? data_i[`PFN_BITS] : entry_lo0_reg[`PFN_BITS];
         entry_lo0_reg[`FLAG_BITS]  <= tlbr           ? entry_lo0_in[`FLAG_BITS] :
                                       mtc0_entry_lo0 ? data_i[`FLAG_BITS] : entry_lo0_reg[`FLAG_BITS];

         entry_lo1_reg[`PFN_BITS]   <= tlbr           ? entry_lo1_in[`PFN_BITS] & ~page_mask_in[`MASK_BITS]:
                                       mtc0_entry_lo1 ? data_i[`PFN_BITS] : entry_lo1_reg[`PFN_BITS];
         entry_lo1_reg[`FLAG_BITS]  <= tlbr           ? entry_lo1_in[`FLAG_BITS] :
                                       mtc0_entry_lo1 ? data_i[`FLAG_BITS] : entry_lo1_reg[`FLAG_BITS];

         entry_hi_reg[`VPN2_BITS]   <= tlbr           ? entry_hi_in[`VPN2_BITS] & ~page_mask_in[`MASK_BITS]:
                                       mtc0_entry_hi  ? data_i[`VPN2_BITS] :
                                       tlb_exception  ? badvaddr[`VPN2_BITS] : entry_hi_reg[`VPN2_BITS];
         
         entry_hi_reg[`ASID_BITS]   <= tlbr           ? entry_hi_in[`ASID_BITS] :
                                       mtc0_entry_hi  ? data_i[`ASID_BITS] : entry_hi_reg[`ASID_BITS];

         page_mask_reg[`MASK_BITS]  <= tlbr           ? page_mask_in[`MASK_BITS] :
                                       mtc0_page_mask ? data_i[`MASK_BITS] : page_mask_reg[`MASK_BITS];
      end
   end
	always @(*) begin
		if(rst == `RstEnable) begin
			/* code */
			data_o = `ZeroWord;
		end else begin 
			case (raddr_i)
				 `CP0_REG_INDEX    : begin
					data_o = index_reg;
				end
				`CP0_REG_ENTRYLO0: begin
					data_o = entry_lo0_reg;
				end
				`CP0_REG_ENTRYLO1: begin
					data_o = entry_lo1_reg;
				end
				`CP0_REG_PAGEMASK: begin
					data_o = page_mask_reg;            
				end
				`CP0_REG_ENTRYHI : begin
					data_o = entry_hi_reg;            
				end
				`CP0_REG_COUNT:begin 
					data_o = count_o;
				end
				`CP0_REG_COMPARE:begin 
					data_o = compare_o;
				end
				`CP0_REG_STATUS:begin 
					data_o = status_o;
				end
				`CP0_REG_CAUSE:begin 
					data_o = cause_o;
				end
				`CP0_REG_RANDOM:begin
					data_o = random_reg;
				end
				`CP0_REG_EPC:begin 
					data_o = epc_o;
				end
				`CP0_REG_PRID: begin 
					data_o = prid_o;
				end
				`CP0_REG_CONFIG:begin 
					data_o = config_o;
				end
				`CP0_REG_BADVADDR:begin 
					data_o = badvaddr;
				end
				`CP0_REG_PRID: begin
					case (sel_addr)
						0:  data_o	=	prid_o;
						1:	data_o 	= 	ebase_reg;
						default:
							data_o = 0;
            		endcase 
				end
				default : begin 
					data_o = `ZeroWord;
				end
			endcase
		end
	
	end
endmodule