`timescale 1ns / 1ps
`include "defines2.vh"

module cp0_reg(
	input wire clk,
	input wire rst,
	input wire stall_masterW,
	input wire we1_i, we2_i,
	input[4:0] waddr1_i, waddr2_i,
	input[4:0] raddr1_i, raddr2_i,	
	input[`RegBus] data1_i, data2_i, 
	// todo
	input wire[5:0] int_i,

	input wire[`RegBus] excepttype1_i, excepttype2_i,
	input wire[`RegBus] current_inst_addr1_i, current_inst_addr2_i,
	input wire is_in_delayslot1_i, is_in_delayslot2_i,
	input wire[`RegBus] bad_addr1_i, bad_addr2_i,

	
	output reg[`RegBus] status_o,
	output reg[`RegBus] cause_o,
	output reg[`RegBus] epc_o,
	output reg[`RegBus] data1_o, data2_o,
	output reg         timer_int_o,
	output wire[`RegBus] count_o
    );
	reg[`RegBus] compare_o;
	reg[`RegBus] config_o;
	reg[`RegBus] prid_o;
	reg[`RegBus] badvaddr;
	reg [32:0] count;
	assign count_o = count[32:1];

	always @(posedge clk) begin
		if(rst == `RstEnable) begin
			count <= 0;
			compare_o <= `ZeroWord;
			status_o <= 32'b00000000010000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			badvaddr <= `ZeroWord;
			config_o <= 32'b00000000000000001000000000000000;
			prid_o <= 32'b00000000010011000000000100000010;
			timer_int_o <= `InterruptNotAssert;
		end 
		else  if (~(stall_masterW & (we1_i | we2_i)))begin
			count <= count + 1;
			cause_o[15:10] <= int_i;
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				/* code */
				timer_int_o <= `InterruptAssert;
			end
			if(we2_i)begin
				case (waddr2_i)
					`CP0_REG_COUNT:begin 
						count[32:1] <= data2_i;
					end
					`CP0_REG_COMPARE:begin 
						compare_o <= data2_i;
					end
					`CP0_REG_STATUS:begin 
						status_o <= data2_i;
					end
					`CP0_REG_CAUSE:begin 
						cause_o[9:8] <= data2_i[9:8];
						cause_o[23] <= data2_i[23];
						cause_o[22] <= data2_i[22];
					end
					`CP0_REG_EPC:begin 
						epc_o <= data2_i;
					end
					default :;
				endcase
			end
			else if(we1_i) begin
				case (waddr1_i)
					`CP0_REG_COUNT:begin 
						count[32:1] <= data1_i;
					end
					`CP0_REG_COMPARE:begin 
						compare_o <= data1_i;
					end
					`CP0_REG_STATUS:begin 
						status_o <= data1_i;
					end
					`CP0_REG_CAUSE:begin 
						cause_o[9:8] <= data1_i[9:8];
						cause_o[23] <= data1_i[23];
						cause_o[22] <= data1_i[22];
					end
					`CP0_REG_EPC:begin 
						epc_o <= data1_i;
					end
					default :;
				endcase
			end
			case (excepttype1_i)
				32'h00000001:begin // 中断（其实写入的cause)
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				32'h00000004:begin // 取指非对齐或Load非对齐
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					badvaddr <= bad_addr1_i;
				end
				32'h00000005:begin // Store非对齐
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					badvaddr <= bad_addr1_i;
				end
				32'h00000008:begin // Syscall异常
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				32'h00000009:begin // BREAK异常
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01001;
				end
				32'h0000000a:begin // 保留指令（译码失败）
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				32'h0000000c:begin // ALU溢出异常
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;
				end
				32'h0000000d:begin // 自陷指令（不在57条中）
					if(is_in_delayslot1_i == `InDelaySlot) begin
						epc_o <= current_inst_addr1_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr1_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				32'h0000000e:begin // eret异常（准确说不叫异常，但通过这个在跳转到epc的同时清零status的EXL?
					status_o[1] <= 1'b0;
				end
				default : begin
					case (excepttype2_i)
						32'h00000001:begin // 中断（其实写入的cause)
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b00000;
						end
						32'h00000004:begin // 取指非对齐或Load非对齐
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b00100;
							badvaddr <= bad_addr2_i;
						end
						32'h00000005:begin // Store非对齐
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b00101;
							badvaddr <= bad_addr2_i;
						end
						32'h00000008:begin // Syscall异常
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b01000;
						end
						32'h00000009:begin // BREAK异常
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b01001;
						end
						32'h0000000a:begin // 保留指令（译码失败）
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b01010;
						end
						32'h0000000c:begin // ALU溢出异常
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
								cause_o[31] <= 1'b0;
							end
							status_o[1] <= 1'b1;
							cause_o[6:2] <= 5'b01100;
						end
						32'h0000000d:begin // 自陷指令（不在57条中）
							if(is_in_delayslot2_i == `InDelaySlot) begin
								epc_o <= current_inst_addr2_i - 4;
								cause_o[31] <= 1'b1;
							end else begin 
								epc_o <= current_inst_addr2_i;
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
			endcase
		end
	end

	always @(*) begin
		if(rst == `RstEnable) begin
			data1_o = `ZeroWord;
			data2_o = `ZeroWord;
		end else begin 
			case (raddr1_i)
				`CP0_REG_COUNT:begin 
					data1_o = count_o;
				end
				`CP0_REG_COMPARE:begin 
					data1_o = compare_o;
				end
				`CP0_REG_STATUS:begin 
					data1_o = status_o;
				end
				`CP0_REG_CAUSE:begin 
					data1_o = cause_o;
				end
				`CP0_REG_EPC:begin 
					data1_o = epc_o;
				end
				`CP0_REG_PRID:begin 
					data1_o = prid_o;
				end
				`CP0_REG_CONFIG:begin 
					data1_o = config_o;
				end
				`CP0_REG_BADVADDR:begin 
					data1_o = badvaddr;
				end
				default : begin 
					data1_o = `ZeroWord;
				end
			endcase
			case (raddr2_i)
				`CP0_REG_COUNT:begin 
					data2_o = count_o;
				end
				`CP0_REG_COMPARE:begin 
					data2_o = compare_o;
				end
				`CP0_REG_STATUS:begin 
					data2_o = status_o;
				end
				`CP0_REG_CAUSE:begin 
					data2_o = cause_o;
				end
				`CP0_REG_EPC:begin 
					data2_o = epc_o;
				end
				`CP0_REG_PRID:begin 
					data2_o = prid_o;
				end
				`CP0_REG_CONFIG:begin 
					data2_o = config_o;
				end
				`CP0_REG_BADVADDR:begin 
					data2_o = badvaddr;
				end
				default : begin 
					data2_o = `ZeroWord;
				end
			endcase
		end
	
	end
endmodule
