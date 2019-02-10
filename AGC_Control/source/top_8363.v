`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/07 15:45:27
// Design Name: 
// Module Name: top_8363
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
module top_8363 #
(

)
(

output [1:0]control_mode_8363,

//input reg_reset,

input main_clk,
input start,
output reg A4,
output reg A5,
output reg A3_csa,
output reg A2_faa,
output reg A1_clka,
output reg A0_data,

inout B5_spi_sdio,
output reg B4_sclk,
output reg B3_csb_gs1,
output reg B2_fab_gs0,
output reg B1_clkb,
output reg B0_datb

);

wire spi_mosi;
wire spi_miso;
wire ioControl;
wire spi_clk;
wire [7:0] spi_data;
wire [7:0] spi_mode;
wire [7:0] spi_dataA;
wire [7:0] spi_dataB;
wire [1:0] control_mode;


wire sig_R1W0;

wire spi_stop;
wire cs_go;

reg spi_csA;
reg spi_csB;

reg spi_sdio;

wire reg_reset; // this is for using register test
wire channel;

assign control_mode_8363=control_mode;

    always @(posedge main_clk)
        begin
            case(reg_reset)
            'b0:
                begin
                    if (csgo==1'b1 && spi_stop==1'b0 && spi_clk==1'b1)
                        begin
                            case (channel)
                            'b0:
                            spi_csA<=1'b1;
                            'b1:
                            spi_csB<=1'b1;
                            endcase
                        end
                    else if(spi_stop==1'b1)
                        begin
                         spi_csA<=1'b0;
                         spi_csB<=1'b0;
                        end
                end

            'b1:
                begin
                    spi_csA<=1'b0;
                    spi_csB<=1'b0;
                end
            endcase
            end

IOBUF #(
    .DRIVE(12), // specify the output drive strnth
    .IBUF_LOW_PWR("TRUE"), 
    .IOSTANDARD("DEFAULT"),
    .SLEW("SLOW")
    ) IOBUF_inst (
    .O(spi_miso),
    .IO(B5_spi_sdio),
    .I(spi_mosi),
    .T(ioControl));
    
    
 clkgen clk1(
 .clk(main_clk),
 .clk_out(spi_clk),
 .start(start),
 .csgo(csgo),
 .stop(spi_stop),
 .rst(reg_reset));
 
 
 test_spi top1(
 .spi_clk(spi_clk),
 .spi_cs(spi_csA),
 .channel(channel),
 .spi_mode(spi_mode),
 .sig_R1W0(sig_R1W0),
 .spi_mosi(spi_mosi),
 .spi_miso(spi_miso),
 .spi_dataA(spi_dataA),
 .spi_dataB(spi_dataB),
 .reg_reset(reg_reset),
 .sig_read(ioControl),
 .spi_stop(spi_stop),
 .control_mode(control_mode) // this is for determine the MOSI multifuction pin output
 );
 
 
 
 reg_test regtest(
 
 .spi_mode(spi_mode),
 .control_mode(control_mode),
 
 .reg_reset(reg_reset),
 .sig_R1W0(sig_R1W0),
 .test_start(start),
 .main_clk(main_clk),
 .spi_dataA(spi_dataA),
 .spi_dataB(spi_dataB),
 .channel(channel)
 );
 
 
 always@(posedge main_clk)
         begin
             case (control_mode)
             'b00: A3_csa<=~spi_csA;
             'b01:
                 begin
                 A3_csa<=~spi_csA;
                 B3_csb_gs1<=~spi_csB;
                 B4_sclk<=spi_clk;
                 end
 
            'b10:
                begin
                A0_data<=spi_dataA[0];
                A1_clka<=spi_dataA[1];
                A2_faa<=spi_dataA[2];
                A3_csa<=spi_dataA[3];
                A4<=spi_dataA[4];
                A5<=spi_dataA[5];
 
                 B0_datb<=spi_dataB[0];
                 B1_clkb<=spi_dataB[1];
                 B2_fab_gs0<=spi_dataB[2];
                 B3_csb_gs1<=spi_dataB[3];   
                 B4_sclk<=spi_dataB[4];
                 end
            endcase
          end
endmodule
