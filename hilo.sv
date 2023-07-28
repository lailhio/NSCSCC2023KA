`include "defines2.vh"

module hilo(
   input wire        clk,rst,
   input wire [1:0] hilo_selectE,
   input wire        we, //both write lo and hi
   input wire  mfhiE,mfloE,
   input wire [63:0] hilo_in,  //存入hilo的值
   
   output wire [31:0] hilo_out
   );
   // hilo寄存器
   reg [31:0] hilo_hi;
   reg [31:0] hilo_lo;

   // 更新
   always @(posedge clk) begin
      if(rst)
         {hilo_hi,hilo_lo} <= 0;
      else if(we)begin
         case(hilo_selectE)
            2'b01, 2'b00: {hilo_hi,hilo_lo}<=hilo_in;
            2'b11:   {hilo_hi,hilo_lo}<={hilo_in[63:32],hilo_lo};
            2'b10:    {hilo_hi,hilo_lo}<={hilo_hi,hilo_in[31:0]};
            default :  {hilo_hi,hilo_lo}<={hilo_hi,hilo_lo};
         endcase
      end
      else
         {hilo_hi,hilo_lo}<={hilo_hi,hilo_lo};
   end
   

   // 若为mfhi指令 读hilo高32位  若为mflo指令读hilo低32位
   

   assign hilo_out = ({32{mfhiE}} & hilo_hi) | ({32{mfloE}} & hilo_lo);
endmodule
