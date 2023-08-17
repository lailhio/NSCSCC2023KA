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
`define EXC_CODE_BITS 6:2     //异常编码

module cp0_exception(
    input wire clk,
	input wire rst,
	input wire stallM, stallD,
	input wire we_i,
	input[4:0] waddr_i,
	input[4:0] raddr_i,
	input[2:0] sel_addr,
	input[`RegBus] data_i,

	input wire[5:0] int_i,

	input wire[`RegBus] PcCur,
	input wire is_in_delayslot_i,

    input ri, break_exception, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretE,
    input trap,

    input [31:0] aluoutE,

	output reg[`RegBus] cause_o,
	output reg[`RegBus] data_o,
	output wire[`RegBus] count_o,
	output wire[`RegBus] random_o,

    output flush_exception,  //是否有异常?
    output [31:0] pc_exception,  //pc异常处理地址
    output pc_trap, interuptE //是否trap
);

    reg[`RegBus] status_o;
    reg[`RegBus] epc_o;
    reg[`RegBus] ebase_reg;
    wire [4:0] excepttype_i;
    wire [`RegBus] bad_addr_i;

    reg timer_int_o;

    reg[`RegBus] compare_o;
	reg[`RegBus] prid_o;
	reg[`RegBus] badvaddr;
	reg[`RegBus] config_o;
	reg[`RegBus] config1_o;
	logic [31:0]    prid = 32'h00018003;
	logic [31:0] random_reg;
	logic [31:0] wired_reg;
	reg [32:0] count;
	reg[`RegBus] tag_hi_reg;
	reg[`RegBus] tag_lo_reg;

	reg [31:0] index_reg;


	assign count_o = count[32:1];
	assign random_o = random_reg;
       //             //IE             //EXL            
	assign interuptE =   status_o[0] & ~status_o[1] & ~status_o[2]  & (PcCur != 0) & (
						//IM                 //IP
					( |(status_o[9:8] & cause_o[9:8]) ) ||        //soft interuptE
					( |(status_o[15:10] & cause_o[15:10]) )     //硬件中断
	);

	assign excepttype_i =  (interuptE)				? `EXC_CODE_INT   :
                           (addrErrorLw | pcError) ? `EXC_CODE_ADEL  :
                           (addrErrorSw)           ? `EXC_CODE_ADES  :
                           (syscall)               ? `EXC_CODE_SYS   :
                           (break_exception)		? `EXC_CODE_BP    :
                           (ri)                    ? `EXC_CODE_RI    :
                           (overflow)              ? `EXC_CODE_OV    :
                           (trap)                  ? `EXC_CODE_TR    :
                           (eretE)                 ? `EXC_CODE_ERET  :
                                                     `EXC_CODE_NOEXC;
	//interuptE pc address

   assign pc_exception =      ((excepttype_i == `EXC_CODE_NOEXC)) ? `ZeroWord:
														(eretE)  ? epc_o :
													~status_o[22] ? ebase_reg+32'h180:
																32'hbfc0_0380; //异常处理地址
	
	assign pc_trap =        (excepttype_i != `EXC_CODE_NOEXC); //表示发生异常，需要处理pc
	assign flush_exception =   (excepttype_i != `EXC_CODE_NOEXC); //无异常时，为0
	assign bad_addr_i =    (pcError) ? PcCur : aluoutE;  //出错时的pc


    wire [31:0] Pc_Minus4;
   assign Pc_Minus4 = PcCur - 4;

   // mtc0 (只与mtc0有关，与异常，tlb指令无关)
   always @(posedge clk) begin
      if(rst) begin
         config_o     <= `CONFIG_INIT;
         config1_o    <= `CONFIG1_INIT;
         prid_o       <= `PRID_INIT;
         ebase_reg      <= 32'h8000_0000; //初始化最高位为1

         wired_reg      <= 32'b0;

         tag_hi_reg     <= 32'b0;
         tag_lo_reg     <= 32'b0;
      end
      else if(~stallM & we_i) begin
         case (waddr_i)
            `CP0_COMPARE: begin 
               compare_o <= data_i;
            end
            `CP0_EBASE: begin
               ebase_reg[`EXCEPTION_BASE_BITS] <= data_i[`EXCEPTION_BASE_BITS];
            end
            `CP0_CONFIG: begin   //不会写config1
               config_o[`K23_BITS] <= data_i[`K23_BITS];
               config_o[`KU_BITS ] <= data_i[`KU_BITS ];
               config_o[`K0_BITS ] <= data_i[`K0_BITS ];
            end
            `CP0_WIRED: begin
               wired_reg[`WIRED_BITS] <= data_i[`WIRED_BITS];
            end
            `CP0_TAG_HI: begin
               tag_hi_reg <= data_i;
            end
            `CP0_TAG_LO: begin
               tag_lo_reg <= data_i;
            end
            default: begin
               /**/
            end
         endcase
      end
   end

   //timer int
   wire compare_wen;
   assign compare_wen = ~stallM & we_i & (waddr_i == `CP0_COMPARE);
   always @(posedge clk) begin
      if(rst | compare_wen) begin
         timer_int_o <= 1'b0;
      end
      else begin
         //计时器中断
         timer_int_o <= (compare_o != 32'b0) && (count == compare_o) ? 1'b1 : 1'b0;
      end
   end

//与异常有关
   //status
   wire status_wen;
   assign status_wen = ~stallM & we_i & (waddr_i == `CP0_STATUS);

   always @(posedge clk) begin
      if(rst) begin
         status_o    <= `STATUS_INIT;  //BEV置为1
      end
      else if(flush_exception) begin
         status_o[`EXL_BIT] <= &excepttype_i ? //eret
                                 1'b0 : 1'b1;   
      end
      else if(status_wen) begin
         status_o <= data_i;
      end
   end

   //cause
   wire cause_wen;
   assign cause_wen = ~stallM & we_i & (waddr_i == `CP0_CAUSE);

   always @(posedge clk) begin
      if(rst) begin
         cause_o     <= `CAUSE_INIT;
      end
      else if(flush_exception) begin
         cause_o[`BD_BIT] <= is_in_delayslot_i;
         cause_o[`EXC_CODE_BITS] <= excepttype_i;
      end
      else if(cause_wen) begin
         cause_o[`IP1_IP0_BITS] <= data_i[`IP1_IP0_BITS];  //软件中断
         cause_o[23] <= data_i[23]; 
      end
      else if(compare_wen)begin
         cause_o[15] <= 0;
      end
      else begin
         //外部中断
         cause_o[`IP7_IP0_BITS]  <= {cause_o[15] | (count == compare_o),int_i[4:0],cause_o[9:8]};
      end
   end

   //epc
   wire epc_wen;
   assign epc_wen = ~stallM & we_i & (waddr_i == `CP0_EPC);

   always @(posedge clk) begin
      if(flush_exception) begin
         epc_o <= is_in_delayslot_i ? Pc_Minus4 : PcCur;
      end
      else if(epc_wen) begin
         epc_o <= data_i;
      end
   end

   //bad_addr_i
   wire badvaddr_wen;
   assign badvaddr_wen = (excepttype_i==`EXC_CODE_ADEL) || (excepttype_i==`EXC_CODE_ADES) ? 1'b1 : 1'b0;
   always @(posedge clk) begin
      if(badvaddr_wen)
         badvaddr <= bad_addr_i;
   end


   wire count_wen;
   assign count_wen = ~stallM & we_i & (waddr_i == `CP0_COUNT);
   always @(posedge clk) begin
      if(rst) begin
         count     <= 32'b0;
      end
      else if(count_wen) begin
         count <= data_i;
      end
      else begin
         //计时器加1
         count <=  count + 1 ;
      end
   end



	always @(*) begin
		case (raddr_i)
			`CP0_REG_INDEX    : begin
				data_o = index_reg;
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
			`CP0_REG_CONFIG:begin 
				case (sel_addr)
					0:  data_o	=	config_o;
					1:	data_o 	= 	config1_o;
					default:
						data_o = 0;
				endcase 
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
endmodule