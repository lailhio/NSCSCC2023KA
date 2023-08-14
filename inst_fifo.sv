`timescale 1ns / 1ps
`include "defines2.vh"

// 参考实现：https://github.com/name1e5s/Sirius/blob/SiriusG/hdl/ifu/instruction_fifo.sv
module inst_fifo(
        input                       clk,
        input                       rst,
        input                       fifo_rst,                 // fifo读写指针重置位
        input                       flush_delay_slot,
        input                       De_delay_sel,
        input                       D_delay_rst,              // 下一条master指令是延迟槽指令，要存起来
        input                       E_delay_rst,              // 下一条master指令是延迟槽指令，要存起来
        input                       i_stall,
        input                       delay_selD,         // 延迟槽判断
        input                       masterD_isbj,
        input                       slaveD_isbj,
        output logic                issue_delayslot, // 延迟槽判断结果

        input                       read_en1,    // master是否发射
        input                       read_en2,    // slave是否发射                   
        // output                      read_tlb_refill1,
        // output                      read_tlb_refill2,
        // output                      read_tlb_invalid1,
        // output                      read_tlb_invalid2,
        output logic [31:0]         read_data1,  // 指令
        output logic [31:0]         read_data2,
        output logic [31:0]         read_address1, // 指令地址，即pc
        output logic [31:0]         read_address2, 

        input                       write_en1, // 数据读回 ==> inst_ok & inst_ok_1
        input                       write_en2, // 数据读回 ==> inst_ok & inst_ok_2
        // input                       write_tlb_refill1,
        // input                       write_tlb_refill2,
        // input                       write_tlb_invalid1,
        // input                       write_tlb_invalid2,
        input logic                 inst_enF2,
        input [31:0]                write_address1, // pc
        input [31:0]                write_address2,  
        input [31:0]                write_data1, // inst写入
        input [31:0]                write_data2, 
        
        output logic                empty, 
        output logic                almost_empty,  
        output logic                full,
        
        output reg                  delayslot_stall// 还在读取相关数据
);

    // fifo结构
    fifo_entry  fifo_inst[0:15];
    fifo_entry  read_line1, read_line2;
    fifo_entry  write_line1, write_line2;
    fifo_entry  delayslot_line;
    reg         delayslot_enable; // 需要读取延迟槽的数据

    // fifo控制
    reg [3:0] write_pointer;
    reg [3:0] read_pointer;
    reg [3:0] data_count;

    // INPUT and OUTPUT
    assign write_line1 = '{default:'0, inst_en:inst_enF2, pc_save:write_address1, instr:write_data1};
    assign write_line2 = '{default:'0, inst_en:inst_enF2, pc_save:write_address2, instr:write_data2};
    // assign read_tlb_refill1  = read_line1.refill;
    // assign read_tlb_refill2  = read_line2.refill;
    // assign read_tlb_invalid1 = read_line1.invalid;
    // assign read_tlb_invalid2 = read_line2.invalid;
    assign read_address1     = read_line1.pc_save;
    assign read_address2     = read_line2.pc_save;
    assign read_data1        = read_line1.instr;
    assign read_data2        = read_line2.instr;

    // fifo状态
    assign full     = &data_count[3:1] || (write_pointer+4'd1==read_pointer); // 1110(装不下两条指令了) 
    assign empty    = (data_count == 4'd0); //0000
    assign almost_empty = (data_count == 4'd1); //0001
    reg willbe_delay;

    // 延迟槽判断
    always_ff @(posedge clk)begin
        if(rst | flush_delay_slot) begin
            issue_delayslot <= 1'b0;
            willbe_delay <= 1'b0;
        end
        else if( write_en1 & willbe_delay)begin
            issue_delayslot <= 1'b1;
            willbe_delay <=1'b0;
        end
        else if(!read_en1)begin
            issue_delayslot <= issue_delayslot;
            willbe_delay <= willbe_delay;
        end
        else if(De_delay_sel) begin// 发射一条bj，下周期的指令为延迟槽
            if(write_en1)begin
                // Not Empty
                issue_delayslot <= 1'b1;
                willbe_delay <=1'b0;
            end
            else if((read_pointer + 4'd2 == write_pointer) & slaveD_isbj)begin
                issue_delayslot <= 1'b0;
                willbe_delay <=1'b1;
            end
            else if((read_pointer + 4'd1 == write_pointer) & masterD_isbj)begin
                issue_delayslot <= 1'b0;
                willbe_delay <=1'b1;
            end
            else if(read_pointer == write_pointer) begin
                issue_delayslot <= 1'b0;
                willbe_delay <=1'b1;
            end
            else begin
                // Not Empty
                issue_delayslot <= 1'b1;
                willbe_delay <=1'b0;
            end
        end
        else begin
            issue_delayslot <= 1'b0;
            willbe_delay <=1'b0;
        end
    end

    always_ff @(posedge clk) begin // 延迟槽读取信号
        if (rst) begin
            delayslot_stall  <= 1'd0;
        end
        // 1、Delayslot在fifo下一条读出的指令。2、在取指。3、fifo是空的
        else if(fifo_rst && De_delay_sel && !flush_delay_slot && i_stall) begin
            if((read_pointer + 4'd2 == write_pointer) & slaveD_isbj)begin
                delayslot_stall   <= 1'd1;
            end
            else if((read_pointer + 4'd1 == write_pointer) & masterD_isbj)begin
                delayslot_stall   <= 1'd1;
            end
            else if(read_pointer == write_pointer) begin
                delayslot_stall   <= 1'd1;
            end
            else begin
                delayslot_stall   <= 1'd0;
            end
        end
        else if(delayslot_stall && write_en1)
            delayslot_stall  <= 1'd0;
        else
            delayslot_stall   <= delayslot_stall;
    end
    always_ff @(posedge clk) begin // 下一条指令在需要执行的延迟槽中
        if (rst) begin
            delayslot_enable <= 1'b0;
            delayslot_line   <= '{default:'0};
        end
        // 1、fifo需要被刷新。2、延迟槽不会被刷新。3、 istall会让全部停住，De信号不会变。
        else if(((fifo_rst & !flush_delay_slot & De_delay_sel) | delayslot_stall)& ~delayslot_enable) begin // 初步判断
            if(masterD_isbj)begin
                if(read_pointer + 4'd1 == write_pointer)begin
                    if(write_en1)begin
                        delayslot_enable <= 1'b1;
                        delayslot_line   <=   write_line1;
                    end
                end
                else begin
                    delayslot_enable <= 1'b1;
                    delayslot_line <= fifo_inst[read_pointer + 4'd1];
                end
            end
            else if(slaveD_isbj)begin
                if(read_pointer + 4'd2 == write_pointer)begin
                    if(write_en1)begin
                        delayslot_enable <= 1'b1;
                        delayslot_line <= write_line1;
                    end
                end
                else begin
                    delayslot_enable <= 1'b1;
                    delayslot_line <= fifo_inst[read_pointer + 4'd2];
                end
            end
            else begin
                if(read_pointer == write_pointer)begin
                    if(write_en1)begin
                        delayslot_enable <= 1'b1;
                        delayslot_line <= write_line1;
                    end
                end
                else begin
                    delayslot_enable <= 1'b1;
                    delayslot_line <= fifo_inst[read_pointer];
                end
            end
        end
        // 读出延迟槽
        else if(!delayslot_stall && read_en1) begin // 清空
            delayslot_enable <= 1'b0;
            delayslot_line   <= '{default:'0};
        end
    end
    // fifo读
    always_comb begin  // 取指限制：注意需要保证fifo中至少有一条指令
        if(delayslot_enable) begin
            read_line1 = delayslot_line;
            read_line2 = '{default: '0};
        end
        else if(empty) begin
            read_line1 = '{default: '0};
            read_line2 = '{default: '0};
        end
        else if(almost_empty) begin
            // 只能取一条数据
            read_line1 = fifo_inst[read_pointer];
            read_line2 = '{default: '0};
        end 
        else begin
            // 可以取两条数据
            read_line1 = fifo_inst[read_pointer];
            read_line2 = fifo_inst[read_pointer + 4'd1];
        end
    end

    // fifo写
    always_ff @(posedge clk) begin : write_data 
        if(delayslot_stall) begin
            if(write_en2) begin
                fifo_inst[write_pointer] <= write_line2;
            end
        end
        else begin
            if(write_en1) begin
                fifo_inst[write_pointer] <= write_line1;
            end
            if(write_en2) begin
                fifo_inst[write_pointer + 4'd1] <= write_line2;
            end
        end
    end
    
    always_ff @(posedge clk) begin : update_write_pointer
        if(fifo_rst)
            write_pointer <= 4'd0;
        else if(delayslot_stall)begin
            if(write_en1 && write_en2)
                write_pointer <= write_pointer + 4'd1;
            else if(write_en1)
                write_pointer <= write_pointer;
        end
        else begin
            if(write_en1 && write_en2)
                write_pointer <= write_pointer + 4'd2;
            else if(write_en1)
                write_pointer <= write_pointer + 4'd1;
        end
    end

    always_ff @(posedge clk) begin : update_read_pointer
        if(fifo_rst) begin
            read_pointer <= 4'd0;
        end else if(empty || delayslot_enable) begin
            read_pointer <= read_pointer;
        end else if(read_en1 && read_en2) begin
            read_pointer <= read_pointer + 4'd2;
        end else if(read_en1) begin
            read_pointer <= read_pointer + 4'd1;
        end
    end

    always_ff @(posedge clk) begin : update_counter
        if(fifo_rst)
            data_count <= 4'd0;
        else if(empty & ~delayslot_stall) begin
            // 只写不读
            case({write_en1, write_en2})
            2'b10: begin
                data_count  <= data_count + 4'd1;
            end
            2'b11: begin
                data_count  <= data_count + 4'd2;
            end
            default:
                data_count  <= data_count;
            endcase
        end
        else if(delayslot_stall) begin
            // 只写第二个，第一个给delay。第一个读delay。第二个不给读。
             case({write_en2, read_en2})
            2'b10: begin
                data_count  <= data_count + 4'd1;
            end
            default:
                data_count  <= data_count;
            endcase
        end
        else begin
            // 有写有读，且写优先，1优先 ==>{11,10,00}{11,10,00}
            case({write_en1, write_en2, read_en1 & ~delayslot_enable, read_en2 & ~delayslot_enable})
            4'b1100: begin
                data_count  <= data_count + 4'd2;
            end
            4'b1110, 4'b1000: begin
                data_count  <= data_count + 4'd1;
            end
            4'b1011, 4'b0010: begin
                data_count  <= data_count - 4'd1;
            end
            4'b0011: begin
                data_count  <= data_count == 4'd1 ? 4'd0 : data_count - 4'd2;
            end
            default:
                data_count  <= data_count;
            endcase
        end
    end

    // 统计
    reg [64:0] slave_cnt;
    reg [64:0] master_cnt;
    always_ff @(posedge clk) begin
        if(rst)
            master_cnt <= 0;
        else if(read_en1 && (!empty || issue_delayslot))
            master_cnt <= master_cnt + 1;
    end
    
    always_ff @(posedge clk) begin
        if(rst)
            slave_cnt <= 0;
        else if(read_en2 && (!empty && !delay_selD && !almost_empty))
            slave_cnt <= slave_cnt + 1;
    end

    wire [64:0] total_cnt = master_cnt + slave_cnt;

endmodule