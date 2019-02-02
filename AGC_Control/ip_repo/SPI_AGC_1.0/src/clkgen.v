`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/11/24 16:07:21
// Design Name: 
// Module Name: clkgen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// this is for even clk generation
//M=Freqin/Freqout   N=M/2
//////////////////////////////////////////////////////////////////////////////////



    module clkgen #(
    parameter N = 2,
        WIDTH = 7
    )
    (
        input clk,
        input rst,
        output reg clk_out=‘b0,
        input start,
        output reg csgo='b0,
        inout stop
        );
    
        reg [WIDTH:0]counter='d0;
    always @(posedge clk )
        begin
            case({rst,stop})
            'b00:
                begin
                    counter<=counter+1;
                    
                    if (counter ==N-1)
                        begin 
                            if(clk_out==1'b1 && counter == 1'b1 && start)
                            begin 
                                csgo<=1'b1;
                            end
                            counter<=0;
                            clk_out<= !clk_out;
                        end
    
         end
                'b10:
                    begin
                        clk_out<='b0;
                        csgo<='b0;
                        counter<='d0;
                    end
                
                default:
                    begin
                        csgo='b0;
                        clk_out='b0;
                    end 
            endcase
        end
    
endmodule
