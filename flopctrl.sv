`timescale 1ns / 1ps
//flip-flop with enable,rst,clear
module flopctrl(
	input wire clk,rst,stall,flush,
	input ctrl_sign in,
	output ctrl_sign out
    );
	always @(posedge clk) begin
		if(rst | flush) begin
			out.sign_ex <= 0;
			out.regdst <= 2'b0;
			out.is_imm <= 0;
			out.regwrite <= 0;
			out.read_rs <= 0;
			out.read_rt <= 0;
			out.mem_read <= 0;
			out.mem_write <= 0;
			out.memtoreg <= 0;
			out.hilo_write <= 0;
			out.hilo_read <= 0;
			out.ri <= 0;
			out.breaks <= 0;
			out.syscall <= 0;
			out.eret <= 0;
			out.cp0_write <= 0;
			out.cp0_read <= 0;
			out.DivMulEn <= 0;
			out.is_mfc <= 0;
			out.writereg <= 5'b0;
			out.alucontrol <= 8'b0;
			out.branch_judge_control <= 3'b0;
		end 
		else if(~stall) begin
			out.sign_ex <= in.sign_ex;
			out.regdst <= in.regdst;
			out.is_imm <= in.is_imm;
			out.regwrite <= in.regwrite;
			out.read_rs <= in.read_rs;
			out.read_rt <= in.read_rt;
			out.mem_read <= in.mem_read;
			out.mem_write <= in.mem_write;
			out.memtoreg <= in.memtoreg;
			out.hilo_write <= in.hilo_write;
			out.hilo_read <= in.hilo_read;
			out.ri <= in.ri;
			out.breaks <= in.breaks;
			out.syscall <= in.syscall;
			out.eret <= in.eret;
			out.cp0_write <= in.cp0_write;
			out.cp0_read <= in.cp0_read;
			out.DivMulEn <= in.DivMulEn;
			out.is_mfc <= in.is_mfc;
			out.writereg <= in.writereg;
			out.alucontrol <= in.alucontrol;
			out.branch_judge_control <= in.branch_judge_control;
		end
	end
endmodule