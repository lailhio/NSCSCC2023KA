`include "defines2.vh"

module exception(
   input rst,
   input [5:0] ext_int,
   input ri, break, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
   input [31:0] cp0_status, cp0_cause, cp0_epc,
   input [31:0] pcM,
   input [31:0] alu_outM,

   output [31:0] except_type,
   output flush_exception,  //是否有异�?
   output [31:0] pc_exception,  //pc异常处理地址
   output pc_trap,  //是否trap
   output [31:0] badvaddrM  //pc修正
);

   //INTERUPT
   wire int;
   //             //IE             //EXL            
   assign int =   cp0_status[0] && ~cp0_status[1] && (
                     //IM                 //IP
                  ( |(cp0_status[9:8] & cp0_cause[9:8]) ) ||        //软件中断
                  ( |(cp0_status[15:10] & ext_int) )      ||     //硬件中断
                  (|(cp0_status[30] & cp0_cause[30]))            //计时器中�?
   );
   // 全局中断�?�?,且没有例外在处理,识别软件中断或�?�硬件中�?

   assign except_type =    (int)                   ? 32'h00000001 :    //中断
                           (addrErrorLw | pcError) ? 32'h00000004 :   //地址错误例外（lw地址 pc错误
                           (ri)                    ? 32'h0000000a :     //保留指令例外（指令不存在
                           (syscall)               ? 32'h00000008 :    //系统调用例外（syscall指令
                           (break)                 ? 32'h00000009 :     //断点例外（break指令
                           (addrErrorSw)           ? 32'h00000005 :   //地址错误例外（sw地址异常
                           (overflow)              ? 32'h0000000c :     //算数溢出例外
                           (eretM)                 ? 32'h0000000e :   //eret指令
                                                     32'h00000000 ;   //无异�?
   //interupt pc address
   assign pc_exception =      (except_type == 32'h00000000) ? `ZeroWord:
                              (eretM)? cp0_epc :
                              32'hbfc0_0380; //异常处理地址
   assign pc_trap =        |(except_type ^ 32'h00000000); //表示发生异常，需要处理pc
   assign flush_exception =   |(except_type ^ 32'h00000000); //异常时的清空信号
   assign badvaddrM =      ({{32{pcError}} & pcM} |{{32{~pcError}} & alu_outM}) ; //出错时的pc 

endmodule
