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
			out.regdst <= 0;
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
		end else if(~stall) begin
			out <= in;
		end
	end
endmodule