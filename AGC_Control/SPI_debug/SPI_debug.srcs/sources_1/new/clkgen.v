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
        output reg clk_out
        );
    
    reg [WIDTH:0]counter;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            counter <= 0;
        end
        else if (counter == N-1) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset
            clk_out <= 0;
        end
        else if (counter == N-1) begin
            clk_out <= !clk_out;
        end
    end
    
 

    
endmodule
