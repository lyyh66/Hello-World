`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/11 10:19:19
// Design Name: 
// Module Name: debounce
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


module debounce#
(
)
(
	output				 			signal_o,
	output				 			update_pulse_o,
	input[31:0] 					debounce_time_i,
	input 							clk_i ,
	input 							signal_i ,
	input   						rst_N_i
);


localparam
                S_IDEL           	 	=    7'h00,
                S_HIGH_JUDGE			=    7'h01,
                S_HIGH       		 	=    7'h02,
                S_LOW_JUDGE        		=    7'h04;
    
    
	reg[6:0] state;
	reg[6:0] next_state;
	reg count_done;
	reg[32:0]counter;
	reg[3:0]counter2;
	reg signal_out_reg;
	reg update_o_reg;
	reg signal_input;
	
	assign signal_o=signal_out_reg;
	assign update_pulse_o=update_o_reg; 
	
	always @(posedge clk_i)
		begin
            if(!rst_N_i)
                signal_input <= 'b0;
            else
                signal_input <= signal_i;
		end
	
	
	
	always @(posedge clk_i)
		begin
            if(!rst_N_i)
                state <= S_IDEL;
            else
                state <= next_state;
		end
    

	always @(*)begin
        if(!rst_N_i)    next_state = S_IDEL;
        else case(state)
        S_IDEL:
           
			if(signal_input) 
				next_state = S_HIGH_JUDGE;
			else 
				next_state = S_IDEL;
		
		
		S_HIGH_JUDGE:
			if(count_done)	
				next_state = S_HIGH;
			else if (!signal_input)	
				next_state = S_IDEL;	
			else 
				next_state = S_HIGH_JUDGE;	
        S_HIGH:
            if(!signal_input) 
				next_state = S_LOW_JUDGE;
            else 
				next_state = S_HIGH;
        S_LOW_JUDGE:
            if (count_done) 
				next_state = S_IDEL;
            else if (signal_input)
				next_state = S_HIGH;
			else 
				next_state=S_LOW_JUDGE;
    
		default:
		
		begin 
		next_state = S_IDEL;
	
        end 
		endcase
    end


	always @(posedge clk_i )
	
	begin
	case(state)
        S_IDEL:
			signal_out_reg<='b0;
		S_HIGH_JUDGE:
			signal_out_reg<=signal_out_reg;
		S_HIGH:
			signal_out_reg<='b1;
		S_LOW_JUDGE:
			signal_out_reg<=signal_out_reg;
		default:
			signal_out_reg<=signal_out_reg;
		
		
	endcase 
	end 

 always @(posedge clk_i)
	begin
		case (state)
		S_HIGH_JUDGE:
			if (counter>=debounce_time_i)
			begin
			count_done<=1'b1;
			
		
			end 
			else 
			begin 
			counter<=counter+1;
			
			end 
		S_LOW_JUDGE:
			if (counter>=debounce_time_i)
			begin
			count_done<=1'b1;
			
			end 
			else
			begin 
			counter<=counter+1;
		
			end 
		default:
		begin
			count_done<=1'b0;
			counter<='b0;
		
		end 
		endcase 
	end 
	
	
	always @(posedge clk_i)
	begin
		 if(count_done || counter2)
			begin 
			if (counter2>='d2)
			begin 
			update_o_reg<='b1;
			counter2<='b0;
			end 
			else 
			counter2<=counter2+'d1;
			end 
		else 
		
		begin 
		counter2<='b0;
		update_o_reg<='b0;
		end 
	end 
endmodule
