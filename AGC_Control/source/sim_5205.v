`timescale 1ns/1ps

module sim_top5205;
reg main_clk;
reg start;

wire A4;
wire A5
.....



reg reset;


initial begin
main_clk=0;
forever #6.25 main_clk=~main_clk;
end

initial begin

#25 start='b1;

#2000 reset='b1;



#200 $stop;
end


top 5205 x1(
.main(main_clk),
.start(start),
.A4(A4),




);end module
