module jump_control (
    input wire [31:0] instrD,
    input wire [31:0] PcPlus4D,
    input wire [31:0] rd1D,

    output wire jump1D,          
    output wire [31:0] pc_jump1D        
);
    wire jr, j;
    wire [4:0] rsD;
    assign rsD = instrD[25:21];
    assign jr = ~(|instrD[31:26]) & (~|(instrD[5:1] ^ 5'b00100)); //判断jr, jalr
    assign j = ~(|(instrD[31:27] ^ 5'b00001));                   //判断j, jal
    assign jump1D = jr | j; //需要jump
    
    wire [31:0] pc_jump_immD;
    assign pc_jump_immD = {PcPlus4D[31:28], instrD[25:0], 2'b00}; //instr_index左移2位，与pc+4高四位拼接

    assign pc_jump1D = j ?  pc_jump_immD : rd1D; //从立即数选择跳转地址或从寄存器选择
endmodule