`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/12 13:50:31
// Design Name: 
// Module Name: mask
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


module mask#
(
	parameter DATA_LEN				=	8,	//length of data 	
	parameter MASK_LEN				=	8,	//length of mask
	parameter REG_O_LEN				=	24	//length of output register
)
(
	
	input				 			clk_i ,
	input				 			rst_N_i ,
	input 							outsignal_pulse_i,
	input[MASK_LEN-1:0]  			mask_i,
	output[DATA_LEN-1:0]			signal_o,
	input[DATA_LEN-1:0] 			data_i
);


localparam
                S_INIT           	 	=    7'h00,
                S_IDLE					=    7'h01,
                S_PROCESS     		 	=    7'h02;
                
    
    
	reg[6:0] state;
	reg[6:0] next_state;
	reg[6:0]counter;
	reg[DATA_LEN-1:0] signal_out_reg;
	reg[DATA_LEN-1:0] data_reg_latch;
	reg[MASK_LEN-1:0] mask_reg;

	
	assign signal_o=signal_out_reg;
	
	
	always @(posedge clk_i or negedge rst_N_i)
		begin
            if(!rst_N_i)
                state <= S_INIT;
            else
                state <= next_state;
		end
    

	always @(*)begin
        if(!rst_N_i)    next_state = S_INIT;
        else case(state)
        
		S_INIT:
			
				next_state = S_IDLE;
			
		S_IDLE:
           
			if(outsignal_pulse_i) 
				next_state = S_PROCESS;
			else 
				next_state = S_IDLE;
		
		
		
        S_PROCESS:
            if(counter>='d8) 
				next_state = S_IDLE;
            else 
				next_state = S_PROCESS;
       
		default:
		begin 
		next_state = S_IDLE;
        end 
		endcase
    end

	always @(posedge clk_i)
		begin
		case(state)
		S_INIT:
		begin    
			signal_out_reg				<= 'b0;
		end 
	
		S_IDLE:
		begin
			signal_out_reg				<= signal_out_reg;
			mask_reg					<= mask_i;
			data_reg_latch				<= data_i;
		end 
		
		S_PROCESS:
		begin 
		signal_out_reg[counter-1]		<= (mask_reg[counter-1]=='b1)?data_reg_latch[counter-1]:signal_out_reg[counter-1];
		
		end 
		endcase 
		end
	
	always @(posedge clk_i)
		begin
			case(next_state)
				S_PROCESS:
				begin 
				counter<=counter+'d1;
				end
		
			default:
				counter<='b0;
			endcase 
	end	  




endmodule
