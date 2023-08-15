module pht #(
    parameter LEN_DATA = 2,
    parameter LEN_ADDR = 6
) (clka,clkb,ena,enb,wea,addra,addrb,dina,doutb);
    input clka,clkb,ena,enb,wea;
    input [LEN_ADDR-1:0] addra,addrb;
    input dina;
    output [LEN_DATA-1:0] doutb;

    parameter DEPTH = 2**LEN_ADDR;

    (* ram_style="block" *) reg [LEN_DATA-1:0] ram [DEPTH-1:0];

    reg [LEN_DATA-1:0] doutb;

    integer j;
    initial begin
        for (j=0;j<DEPTH;j++) ram[j] = 0;
    end
    
    always @(posedge clka) begin
        if (ena) if (wea) begin
            case(dina)
                1'b1:
                case(ram[addra])
                    2'b00:ram[addra] <= 2'b01;
                    2'b01:ram[addra] <= 2'b10;
                    2'b10:ram[addra] <= 2'b11;
                    default:ram[addra] <= 2'b11;
                endcase
                1'b0:
                case(ram[addra])
                    2'b11:ram[addra] <= 2'b10;
                    2'b10:ram[addra] <= 2'b01;
                    2'b01:ram[addra] <= 2'b00;
                    default:ram[addra] <= 2'b00;
                endcase
            endcase
            
        end
    end
    
    always @(posedge clkb) begin
        if (enb)
            doutb <= ram[addrb][1];
    end
endmodule