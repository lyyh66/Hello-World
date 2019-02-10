`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/07 15:44:45
// Design Name: 
// Module Name: test_spi
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

`timescale 1ns/1ps


module
test_spi

(
  spi_clk,
  spi_cs,
  spi_dataA,
  spi_dataB,
  
  spi_mode,
  sig_R1W0,
  spi_stop,
  sig_read,
  
  control_mode,
  spi_mosi,
  spi_miso,
  spi_done,
  
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

input[1:0]control_mode;
input sig_R1W0;
  
input[7:0] spi_dataA;
input[7:0] spi_dataB;
input[7:0] spi_mode;


output reg [7:0] read_data;

output reg spi_stop=1'b0;
output spi_done;
reg [7:0] counter1;//for write register
reg [7:0] counter2;//for write data
reg [7:0] counter3;// for read data

reg sig_R0W1;
  
reg data=1'b0;

reg spi_rdone=1'b0;
reg spi_wdone=1'b0;
reg spi_cdone=1'b0;
reg spi_control;

//input here

assign spi_done=((spi_rdone | spi_wdone) & spi_cdone);

//    always @(reg_reset)
//            begin
//             data=1'b0;
       
//             counter1='d8+'d1;
//             counter2='d8;
            
//             read_data='d0;
           
           
//            end


        always @(posedge spi_clk)
            begin
            if (spi_cs==1)
              begin 
               data=1'b0;
               counter1='d8+'d1;
              end 
            
            else
             begin  
             case({data,sig_R0W1,spi_rdone})
                        'b010:
                            begin
                                 if (counter1 >= 0)
                                  begin
                                    spi_mosi=spi_mode[counter1-1];
                                   if (counter1 == 0)
                                         begin
                                        spi_cdone='b0;
                                        end 
                                    counter1=counter1-'d1;
                                   end
                                 else   
                                     begin
                                     counter1<='d8+1;
                                     data<=1'b1;
                                     end
                             end
                            'b110:
                                  begin  
                                    if(counter2 =='d0) 
                                       begin
                                       counter2<='d8;
                                       data<=1'b0;
                                       spi_wdone<=1'b1;
                                       end     
                                     
                                    else if (counter2>'d0)
                                        begin
                                        spi_mosi=spi_dataA[counter2];
                                        counter2=counter2- 'd1;
                                        end
                                   end                    
                          default:
                                begin
                                counter2<='d8;
                                data<=1'b0;
                                spi_wdone<='b0;
                                spi_cdone<='b0;
                                end
                          
                          endcase
                        end      
                    end

            always @ (negedge spi_clk)
            begin 
               case({data,sig_R0W1})
                     'b10:
                         begin
                            if (counter3>='d0)
                             begin
                               read_data[counter3]<=spi_miso;
                                if (counter3=='d0)
                                 begin
                                 counter3='d8-1;
                                 spi_rdone='b1;
                                 end
                                 counter3=counter3-'d1;
                              end
                          end
                              
                         default:
                              begin 
                                 counter3='d8-1;
                                 spi_rdone='b0;
                                 
                              end
                       endcase
             
               end

endmodule
