`timescale 1ns/1ps


module
test_spi(
  spi_clk,
  spi_cs,
  spi_dataA,
  spi_dataB,
  
  spi_mode,
  sig_R1W0,
  spi_stop,
  spi_read,
  
  control_mode.
  spi_mosi,
  spi_miso,
  
  read_data,
  reg_reset,
  channel
);

input spi_clk;
input spi_cs;
input reg_reset;
  input channel;
  
output reg spi_mosi;
input spi_miso;
input sig_read;

  input [1:0]control_mode;
  input sig_R1W0;
  
  input[7:0] spi_dataA;
  input[7:0] spi_dataB;
input[7:0] spi_mode;


output reg [7:0] read_data;

oytput reg spi_stop=1'b0;

reg [7:0] counter1;
reg [7:0] counter2;
reg  sig_read;

  
reg data=1'b0;

//input here


always @(reset)

begin
    data=1'b0;
    wstopB=1'b1;
    counter1='d8+'d1;
    counter2='d8;
    sig_write=1'b1;

    read_data='d0;

end


always @(posedge spi_clk && ~spi_cs)
begin

if (counter1>='d0 && sig_write=='b1 && ~data)

begin

if (counter1 !=0)

begin
    spi_mosi=spi_mode[counter1-1];
    counter1=counter1-'d1;
    if ((counter1)=='d0 && ~sig_R0W1)

    begin
        wstopB=1'b1;
    end

else

    begin
    wstopB=1'b0;
    end
end

else if (counter1==0)

begin
    counter1='d8+1;
    data=1'b1;
    sig_write=sig_R0W1?'b1:'b0;
end
end

else if (counter2>='d0 &&  sig_write=='b1 && data && sig_R0W1)

begin
    spi_mosi=spi_data[counter2];
    counter2=(counter2!='d0)?(counter2-'d1):'d8-1;
end
end

always @(negedge spi_clk && ~spi_cs && sig_write=='b0 && ~sig_R0W1)

begin 
if (counter2>='d0)
begin
read_data[counter2]<=spi_miso;

if (counter2=='d0)

begin
    counter2='d8-1;
    data=1'b0;
    sig_write='b1;

end
counter2=counter2-'d1;
end
end

endmodule
