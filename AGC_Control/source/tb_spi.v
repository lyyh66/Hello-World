`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/09 16:15:55
// Design Name: 
// Module Name: tb_spi
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
// 
//////////////////////////////////////////////////////////////////////////////////
 module tb_spi;

reg main_clk,start;
wire A4, A5, A3_csa, A2_faa,A1_clka,A0_data,B4_sclk,B3_csb_gs1,B2_fab_gs0, B1_clkb, B0_datb,B5_spi_sdio;


  initial
  begin
//    rst=1;
//    #30 rst=0;
//     #40 rst=1;

 #100   start=0;
 
 #300 start=1;
    
    
   end
   
   initial
   begin
     forever #20 main_clk=~main_clk;
   end
   
   top_8363 tb1(.main_clk(main_clk),.start(start),.A4(A4),.A5(A5),. A3_csa(A3_csa),.A2_faa(A2_faa),.A1_clka(A1_clka),.A0_data(A0_data),.B4_sclk(B4_sclk),.B3_csb_gs1(B3_csb_gs1),.B2_fab_gs0(B2_fab_gs0),.B1_clkb(B1_clkb),.B0_datb(B0_datb),.B5_spi_sdio(B5_spi_sdio));
 endmodule

