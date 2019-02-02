module reg_test #
  (
  parameter integer C_S_AXI_DATA_WIDTH =32,
  parameter integer C_S_ADDR_WIDTH =5,
    
  
  )
  (
    output reg [1:0]control_mode,
    output reg [7:0]spi_mode,
    output reg [7:0]spi_dataA,
    output reg [7:0]spi_dataB,
    output reg sig_R1W0,
    output reg start,
    input [7:0] read_data,
    input main_clk,
    
    output reg reg_reset'b0,
    output reg channel,
    input test_start
  
  );
  
  reg [7:0] slv_reg0=8'b00100101; //control mode 3:2 01 SPI 10 PARAL
  reg [7:0] slv_reg1=8'b10101010;// the last bit  1:read  0:write
  reg [7:0] slv_reg2=8'b11110011;// channel A data
  reg [7:0] slv_reg3;   //read back data
  reg [7:0] slv_reg4=8'b00100101; // channel b data
  
  
  
  alwaays @(posedge main_clk)
  begin
    control_mode[1:0]<=spi_reg0[3:2];
    reg_reset<=slv_reg0[4];
    channel<=slv_reg0[5];
    spi_mode[7:0]<=slv_reg1[7:0];
    spi_dataA[7:0]<=slv_reg2[7:0];
    spi_dataB[7:0]<=slv_reg4[7:0];
    
    sig_R1W0<=spi_mode[0];
    start<=slv_reg0[1];
    slv_reg3[7:0]<=read_data[7:0];
    
  end
  
  endmodule
