`include "defines2.vh"

module hilo_new(
   input wire        clk,rst,
   input wire        we, //both write lo and hi,若写一半请置零
   input wire [63:0] hilo_in,  //存入hilo的值,若写一半请置零
   output wire [63:0] hilo_out //若读一半请切分
   );
   // hilo寄存器
   reg [31:0] hilo_hi;
   reg [31:0] hilo_lo;

   // 更新
   always @(posedge clk) begin
      if(rst)
         {hilo_hi,hilo_lo} <= 0;
      else if(we)
         {hilo_hi,hilo_lo}<=hilo_in;
   end
   
   assign hilo_out = {hilo_hi, hilo_lo};

endmodule
