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

module cp0_reg(
	input wire clk,
	input wire rst,
	input wire stallM2,
	input wire we_i,
	input[4:0] waddr_i,
	input[4:0] raddr_i,
	input[2:0] sel_addr,
	input[`RegBus] data_i,

	input wire[5:0] int_i,

	input wire[`RegBus] excepttype_i,
	input wire[`RegBus] current_inst_addr_i,
	input wire is_in_delayslot_i,
	input wire[`RegBus] bad_addr_i,

	
	output reg[`RegBus] status_o,
	output reg[`RegBus] cause_o,
	output reg[`RegBus] epc_o,
	output reg[`RegBus] data_o,
	output reg         timer_int_o,
	output wire[`RegBus] count_o,
	output wire[`RegBus] random_o,
	output reg[`RegBus] ebase_reg
    );
	reg[`RegBus] compare_o;
	reg[`RegBus] prid_o;
	reg[`RegBus] badvaddr;
	reg[`RegBus] config_o;
	logic [31:0]    prid = 32'h00018003;
	logic [31:0] random_reg;
	logic [31:0] wired_reg;
	reg [32:0] count;
	assign count_o = count[32:1];
	assign random_o = random_reg;


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
			random_reg <= TLB_LINE_NUM - 1;
			wired_reg <= 0;
        	ebase_reg <= 32'h80000000;
		end 
		else begin
			count <= count + 1;
			random_reg <= (random_reg == wired_reg) ? (TLB_LINE_NUM - 1) : (random_reg - 1);
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
						wired_reg <= {{(32-$clog2(TLB_LINE_NUM)){1'b0}},data_i[$clog2(TLB_LINE_NUM)-1:0]};
						random_reg <= TLB_LINE_NUM-1;
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

	always @(*) begin
		if(rst == `RstEnable) begin
			/* code */
			data_o = `ZeroWord;
		end else begin 
			case (raddr_i)
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
