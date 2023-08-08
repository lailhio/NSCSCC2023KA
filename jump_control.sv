module jump_control (
    input wire [31:0] instr1D, instr2D, 
    input wire [31:0] PcPlus4D, PcPlus8D,
    input wire [31:0] src1_a1D, src2_a1D, 

    output wire jump1D, jump2D,         
    output wire [31:0] pc_jump1D, pc_jump2D  
);
    wire jr1, j1;
    wire jr2, j2;

    assign jr1 = ~(|instr1D[31:26]) & (~|(instr1D[5:1] ^ 5'b00100)); 
    assign j1 = ~(|(instr1D[31:27] ^ 5'b00001));        
    assign jump1D = jr1 | j1; 

    assign jr2 = ~(|instr2D[31:26]) & (~|(instr2D[5:1] ^ 5'b00100)); 
    assign j2 = ~(|(instr2D[31:27] ^ 5'b00001));
    assign jump2D = jr2 | j2;
    
    wire [31:0] pc_jump1_immD;
    assign pc_jump1_immD = {PcPlus4D[31:28], instr1D[25:0], 2'b00}; 

    wire [31:0] pc_jump2_immD;
    assign pc_jump2_immD = {PcPlus8D[31:28], instr2D[25:0], 2'b00};

    assign pc_jump1D = j1 ?  pc_jump1_immD : src1_a1D; 
    assign pc_jump2D = j2 ?  pc_jump2_immD : src2_a1D; 
endmodule