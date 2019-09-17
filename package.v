`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/20 10:54:13
// Design Name: 
// Module Name: cms_package
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


module cms_package(

//to ad card
	input 	[7:0]	data_i,
	input			data_valid_i,
	output 	[2:0]	cmd_code_o,
	output			cs_o,

	input	[7:0]	byte_numb_i,
	input 	[2:0]	command_code_i,
	input 			start_i,
	output 			package_done_o,
	output 			error,

	
	output	[31:0]	data_fifo_o,
	input			rd_en_i,

	//basic input 
	input			clk,
	input 			rst

    );
//clock declareation 
	localparam CLK_PERIOD=10; //10ns
	localparam START_HOLDING_TIME=30;//50ns
	localparam START_HOLDING_TIME_CNT=START_HOLDING_TIME/CLK_PERIOD-1;
		
	
	localparam S_IDLE			=6'd0;
	localparam S_COMMAND_UPDATE	=6'd1;
	localparam S_WAITING	 	=6'd2;		
	localparam S_PACKAGE_8		=6'd3;
	localparam S_ARRANGE		=6'd4;
	localparam S_JUDGE_FIFO		=6'd5;
	localparam S_UPDATE_FIFO	=6'd6;
	localparam S_JUDGE			=6'd7;
	localparam S_DONE			=6'd8;
	localparam S_ERROR			=6'd9;
	
	
//register declareation
	reg		[5:0]	curr_state;
	reg 	[5:0]	next_state;
	
	reg 	[2:0]	command_reg;
	reg		[7:0]	byte_numb_reg; //numbers of 8 bits data

	reg 			fifo_wr_enable;
	reg 	[31:0]	data_temp;
	wire	[31:0]	data_fifo_o;
	
	reg				package_done;
	wire 			onebyte_done;
	wire 	[7:0]	data_orig;
	wire			error;
	reg				start_control;
//counter declarition
	reg 	[31:0]  counter;
	reg		[ 3:0]	package_counter;

	assign package_done_o=package_done;
	
	always@(posedge clk)
	begin
		if(rst)
			curr_state<=S_IDLE;
		else
			curr_state<=next_state;
	end 
	
	
	
	always@(*)
	begin 
		next_state=S_IDLE;
		case(curr_state)
			S_IDLE:
				begin
					if(start_i)
						next_state=S_COMMAND_UPDATE;
					else 
						next_state=S_IDLE;
				end
			S_COMMAND_UPDATE:
				begin
					if(counter==START_HOLDING_TIME_CNT)
						next_state=S_WAITING;
					else 
						next_state=S_COMMAND_UPDATE;
				end 
			S_WAITING:
				begin
					if(onebyte_done)
						next_state=S_PACKAGE_8;
					else if (error)
						next_state=S_ERROR;
					else 
						next_state=S_WAITING;
				end
			S_PACKAGE_8:
				begin 
					next_state=S_ARRANGE;
				end
			S_ARRANGE:
				begin 
					next_state=S_JUDGE_FIFO;
				end
			S_JUDGE_FIFO:
				begin
					if(all_done_o ||package_counter=='d4 )
						next_state=S_UPDATE_FIFO;
					else 
						next_state=S_WAITING;
				end

			S_UPDATE_FIFO:
				begin
					next_state=S_JUDGE;
				end
			S_JUDGE:
				begin
					if(all_done_o)
						next_state=S_DONE;
					else 
						next_state=S_WAITING;
				end
			S_DONE:
				begin
					next_state=S_IDLE;
				end 
				
			S_ERROR:
				begin
					next_state=S_ERROR;
				end 
			
		endcase
	end 
	
	
	always@(posedge clk)
		begin
		case(curr_state)
			S_IDLE:
				begin 
					command_reg		<=command_code_i;
					start_control	<='b0;
					counter			<='b0;
					data_temp		<='b0;
					byte_numb_reg	<=byte_numb_i;
					package_done	<='b0;
					package_counter	<='b0;
				end 
			S_COMMAND_UPDATE:
				begin
					package_done	<='b0;
					package_counter	<='b0;
					command_reg		<=command_reg;
					start_control	<='b1;
					counter			<=counter+'b1;
					
				end 
			S_WAITING:
				begin
					
					package_done	<='b0;
					package_counter	<=package_counter;
					command_reg		<=command_reg;
					start_control	<='b0;
					counter			<='b0;
					data_temp		<=data_temp;
				
				end 
			S_PACKAGE_8:
				begin
					package_done	<='b0;
					command_reg		<=command_reg;
					data_temp[31:24]<=data_orig;
					byte_numb_reg	<=byte_numb_reg-'b1;
					package_counter	<=package_counter+'d1;
				end
			S_ARRANGE:
				begin
				if (all_done_o && command_reg=='d3)
					begin
					package_done	<='b0;
					command_reg		<=command_reg;
					package_counter	<=package_counter;
					data_temp		<={data_temp[7:0],data_temp[31:8]};
					end
					
				else
					begin
					package_done	<='b0;
					command_reg		<=command_reg;
					package_counter	<=package_counter;
					data_temp		<={data_temp[23:0],data_temp[31:24]};
					end 
					
				end 
			S_JUDGE_FIFO:
				begin
					package_done	<='b0;
					command_reg		<=command_reg;
					data_temp		<=data_temp;
					package_counter	<=package_counter;
				end 
			
			S_UPDATE_FIFO:
				begin
					command_reg		<=command_reg;
					package_counter	<='b0;
					package_done	<='b0;
					counter			<='b0;
					
				end

			S_JUDGE:
				begin
					command_reg		<=command_reg;
					package_done	<='b0;
					counter			<='b0;
					data_temp		<='b0;
				end 
			S_DONE:
				begin
					command_reg		<=command_reg;
					byte_numb_reg	<='b0;
					package_done	<='b1;
				
				end 
				
			S_ERROR:
				begin
					command_reg		<='b0;
					package_done	<='b1;
				
				end 
				
	
		endcase
		end 


	always@(negedge clk)
		begin
			if(rst)
				fifo_wr_enable<='b0;
			else if(curr_state==S_UPDATE_FIFO)
				fifo_wr_enable<='b1;
			else 
				fifo_wr_enable<='b0;
		end 
	
	
	cms_data_capture cms_data_capture
	(
	
	.error_o		(error			),
	.data_i			(data_i			),
	.data_valid_i	(data_valid_i	),
	.cmd_code_o		(cmd_code_o		),
	.cs_o			(cs_o			),
	.start_i		(start_control	),
	.command		(command_reg	),
	.byte_numb_i	(byte_numb_i	),
	.data_o			(data_orig		),
	.all_done_o		(all_done_o		),
	.onebyte_done_o	(onebyte_done	),
	.clk			(clk			),
	.rst			(rst			)
	);
	
	
	
	
	fifo_package	fifo_package
	(
	.clk 		(clk 			),
    .srst 		(rst 			),
    .din 		(data_temp		),
    .wr_en 		(fifo_wr_enable	),
    .rd_en 		(rd_en_i		),
    .dout 		(data_fifo_o	),
    .full 		( 				),
    .empty 		( 				),
    .data_count (				)
	
	);
	
endmodule
