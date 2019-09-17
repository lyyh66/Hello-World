`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/19 10:30:22
// Design Name: 
// Module Name: cms_data_capture
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


module cms_data_capture(
//adc operation ports 
	input 			data_valid_i,
	input	[7:0]	data_i,	
	output 	[2:0]	cmd_code_o,
	output 			cs_o,
	
	input 			start_i,

// FPGA part
	input	[2:0]	command,
	input	[7:0]	byte_numb_i,
	output 	[7:0]	data_o,
	output			all_done_o,
	output 			onebyte_done_o,
	output			error_o,
//basic input 
	input			clk,
	input 			rst

    );
//clock declareation 
	localparam CLK_PERIOD=10; //10ns
	localparam UPDATE_TIME=1*1000;
	localparam UPDATE_TIME_CNT=UPDATE_TIME/CLK_PERIOD-1;
	
	localparam WATCHDOG_TIME=150;//150ns
	localparam WATCHDOG_TIME_CNT=WATCHDOG_TIME/CLK_PERIOD-1;
	
	localparam CSWAITING_TIME=30; //30ns
	localparam CSWAITING_TIME_CNT=CSWAITING_TIME/CLK_PERIOD-1;
	localparam CSHOLDINGING_TIME=150; //150ns
	localparam CSHOLDINGING_TIME_CNT=CSHOLDINGING_TIME/CLK_PERIOD-1;
	
	localparam CSHOLDINGING_FINISH_TIME=100; //100ns  10clk cycle
	localparam CSHOLDINGING_FINISH_TIME_CNT=CSHOLDINGING_FINISH_TIME/CLK_PERIOD-1;
	
	
	localparam SCL_PERIOD=10*1000; //10us
	localparam SCL_CNT=SCL_PERIOD/CLK_PERIOD-1;
	localparam SCL_HALF_CNT=SCL_PERIOD/CLK_PERIOD/2-1;
	localparam SCL_LOW_MID=SCL_PERIOD/CLK_PERIOD/4-1;
	localparam SCL_HIGH_CNT=SCL_PERIOD*3/CLK_PERIOD/4-1;


//STATE MACHINE 
	localparam S_IDLE			=6'd0;
	localparam S_CMD_LATCH		=6'd1;
	localparam S_WAITING_CS		=6'd2;
	localparam S_CLEARWD_CS		=6'd3;
	localparam S_READY			=6'd4;
//localparam S_CLEARWD_RD     =6'd5;
	localparam S_DATA_LATCH		=6'd5;
	localparam S_JUDGE			=6'd6;
	localparam S_DONE			=6'd7;
	localparam S_ERROR			=6'd8;
//register declareation
	reg		[5:0]	curr_state;
	reg 	[5:0]	next_state;
	reg 	[31:0]	watchdog_cnt;
	reg				error;
	
	reg 	[2:0]	cmd_code_reg;
	reg 			cs_reg;
	reg				data_valid_reg;
	reg 	[7:0]	data_reg;
	reg		[7:0]	byte_numb;
	reg 			all_done;
	reg 			onebyte_done;
//counter declarition
	reg 	[31:0]  counter;
	
	

//assigment 

	assign cs_o				=cs_reg;
	assign cmd_code_o		=cmd_code_reg;
	assign data_o			=data_reg;
	assign all_done_o		=all_done;
	assign onebyte_done_o	=onebyte_done;
	assign error_o			=error;

	always@(posedge clk)
	begin
		if(rst)
			curr_state<=S_IDLE;
		else
			curr_state<=next_state;
	end 

//watchdog time counter 	
/* 	
	
	always@(posedge clk)
	begin
		if(rst)
			watchdog_cnt<='b0;
		else if (curr_state==S_WAITING_CS)
			watchdog_cnt<=watchdog_cnt+1'b1;
		else if (curr_state==S_READY)
			watchdog_cnt<=watchdog_cnt+1'b1;
		else 
			watchdog_cnt<='b0;
	end  */
	
//state machine 	
	
	always@(*)
	begin 
		next_state=S_IDLE;
		case(curr_state)
			S_IDLE:
				begin
					if(start_i)
						next_state=S_CMD_LATCH;
					else 
						next_state=S_IDLE;
				end
			S_CMD_LATCH:
				begin 
					if(counter==CSHOLDINGING_TIME_CNT)
						next_state=S_WAITING_CS;
					else 
						next_state=S_CMD_LATCH;
				end 
			S_WAITING_CS:
				begin 
					if(data_valid_reg)
						next_state=S_CLEARWD_CS;
					else if(watchdog_cnt==WATCHDOG_TIME_CNT)
						next_state=S_ERROR;
					else 
						next_state=S_WAITING_CS;
				end
			S_CLEARWD_CS:
				begin
					next_state=S_READY;
				end 
			
			S_READY:
				begin
					if(~data_valid_reg)
						next_state=S_DATA_LATCH;
					else if(watchdog_cnt==WATCHDOG_TIME_CNT)
						next_state=S_ERROR;
					else 
						next_state=S_READY;
				end 
			
			S_DATA_LATCH:
				begin
					next_state=S_JUDGE;
				end 

			S_JUDGE:
				begin
					if(byte_numb=='b0)
						next_state=S_DONE;
					else
						next_state=S_WAITING_CS;
				end
			S_DONE:
				begin 
					if(counter==CSHOLDINGING_FINISH_TIME_CNT)
						next_state=S_IDLE;
					else
						next_state=S_DONE;
				end 
			S_ERROR:
				begin 
					next_state=S_ERROR;
				end 
			
			default:
				begin
					next_state=S_IDLE;
				end
		endcase
	
	end
	
	always@(posedge clk)
	begin
		case(curr_state)
			S_IDLE:
				begin 
					cmd_code_reg	<='b0;
					cs_reg			<='b1;
					data_reg		<='b0;
					data_valid_reg	<='b0;
					byte_numb		<='b0;
					counter			<='b0;
					all_done		<='b0;
					onebyte_done	<='b0;
					watchdog_cnt	<='b0;
					error			<='b0;
				end 
			S_CMD_LATCH:
				begin 		 
					cmd_code_reg	<=command;
					byte_numb		<=byte_numb_i;
					cs_reg			<='b1;
					data_reg		<='b0;
					counter			<=counter+'d1;
					all_done		<='b0;
					onebyte_done	<='b0;
				end 
			S_WAITING_CS:
				begin
					cmd_code_reg	<=cmd_code_reg;
					cs_reg			<='b0;
					data_reg		<=data_reg;
					data_valid_reg	<=data_valid_i;
					counter			<='b0;
					all_done		<='b0;
					onebyte_done	<='b0;
					watchdog_cnt	<=watchdog_cnt+1'b1;
				end 
			S_CLEARWD_CS:
				begin 
					watchdog_cnt	<='b0;
				
				end 
			S_READY:
				begin
					cmd_code_reg	<=cmd_code_reg;
					counter			<='b0;
					cs_reg			<='b0;
					all_done		<='b0;
					onebyte_done	<='b0;
					data_reg		<=data_reg;
					data_valid_reg	<=data_valid_i;
					watchdog_cnt	<=watchdog_cnt+1'b1;
				end
				
			S_DATA_LATCH:
				begin 
					counter			<='b0;
					cs_reg			<='b0;
					all_done		<='b0;
					onebyte_done	<='b0;
					data_reg		<=data_i;
					data_valid_reg	<=data_valid_i;
					byte_numb		<=byte_numb-1'b1;
					watchdog_cnt	<='b0;
				end 
			S_JUDGE:
				begin
					counter			<='b0;
					cs_reg			<='b0;
					all_done		<='b0;
					onebyte_done	<='b1;
					data_reg		<=data_reg;
					data_valid_reg	<=data_valid_i;
					watchdog_cnt	<='b0;
				end 
			S_DONE:
				begin
					counter			<=counter+1;
					cs_reg			<='b0;
					all_done		<='b1;
					onebyte_done	<='b0;
				end 
			S_ERROR:
				begin
					error			<='b1;
					all_done		<='b1;
					watchdog_cnt	<='b0;
				end 
		endcase
	end 
	
	endmodule
