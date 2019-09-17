`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/21 10:27:14
// Design Name: 
// Module Name: cms_control
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
module cms_control(

	//to ad card a
	input 	[7:0]	data_a_i,
	input			data_valid_a_i,
	output 	[2:0]	cmd_code_a_o,
	output			cs_a_o,
	//to ad card b
	input 	[7:0]	data_b_i,
	input			data_valid_b_i,
	output 	[2:0]	cmd_code_b_o,
	output			cs_b_o,
	//to ad card c
	input 	[7:0]	data_c_i,
	input			data_valid_c_i,
	output 	[2:0]	cmd_code_c_o,
	output			cs_c_o,
	
	input 	[63:0]	timescale_i,
	input 			start_i,
	input 	[31:0]	update_period_i,

	output 	[31:0]	dma_wr_data_o,
	output			dma_wr_enable_o,
	
	//basic input 
	output	[10:0]	data_count,
	input			clk,
	input 			rst

    );
//clock declareation 
	localparam CLK_PERIOD=10; //10ns
	localparam CALI_HOLDING_TIME=200;//20 cycle
	localparam CALI_HOLDING_TIME_CNT=CALI_HOLDING_TIME/CLK_PERIOD-1;
	
	localparam AMPL_HOLDING_TIME=200;//20 cycle
	localparam AMPL_HOLDING_TIME_CNT=AMPL_HOLDING_TIME/CLK_PERIOD-1;
	
	localparam UPDATE_TIME_MAX=200*1000;//5kHz
	localparam UPDATE_TIME_MAX_CNT=UPDATE_TIME_MAX/CLK_PERIOD-1;
	
	localparam UPDATE_TIME_MIN=20*1000;//50kHz
	localparam UPDATE_TIME_MIN_CNT=UPDATE_TIME_MIN/CLK_PERIOD-1;
	
	
//command declarition
	localparam CMD_IDLE			=3'd0;
	localparam CMD_AMPL			=3'd1;
	localparam CMD_FREQ			=3'd2;
	localparam CMD_RADS			=3'd3;
	localparam CMD_CALI			=3'd4;
	
//byte number declarition
	localparam NUM_AMPL			=8'd32;
	localparam NUM_FREQ			=8'd80;
	localparam NUM_RADS			=8'd10;	
	localparam NUM_CALI			=8'd64;
	localparam NUM_CALI_32		=8'd16;
	
	
	localparam NUM_TOTAL_CA		=8'd47; // number of 32bits inside of FIFO with calibration 
	localparam NUM_TOTAL_NCA	=8'd31;// number of 32bits inside of FIFO without calibration
//state machine 	
	localparam S_IDLE			=6'd0;
	localparam S_CALI			=6'd1;
	localparam S_WAITING_CALI	=6'd2;
	localparam S_READY_AMPL		=6'd3;
	localparam S_WAITING_AMPL	=6'd4;
	localparam S_READY_FREQ		=6'd5;
	localparam S_WAITING_FREQ   =6'd6;
	localparam S_READY_RADS     =6'd7;
	localparam S_WAITING_RADS   =6'd8;
	localparam S_JUDGE_CALIWR_A	=6'd9;
	localparam S_CALIWR_A       =6'd10;
	localparam S_JUDGE_CALIWR_B	=6'd11;
	localparam S_CALIWR_B       =6'd12;
	localparam S_JUDGE_CALIWR_C	=6'd13;
	localparam S_CALIWR_C       =6'd14;
	localparam S_TIME_HIGH		=6'd15;
	localparam S_TIME_LOW		=6'd16;
	localparam S_JUDGE_A        =6'd17;
	localparam S_ID_A			=6'd18;
	localparam S_DATA_A			=6'd19;
	localparam S_JUDGE_B        =6'd20;
	localparam S_ID_B           =6'd21;
	localparam S_DATA_B			=6'd22;
	localparam S_JUDGE_C        =6'd23;
	localparam S_ID_C           =6'd24;
	localparam S_DATA_C			=6'd25;
	localparam S_WAITING 		=6'd26;
	localparam S_ERROR			=6'd27;
	
	
	
	reg 			start_control;
	reg [2:0]		command_code;
	reg	[7:0]		byte_numb;
	wire[2:0]		error_cba;
	wire[2:0]		package_done_cba;
	reg 			done_trigger;
	reg	[31:0]		id_a;
	reg	[31:0]		id_b;
	reg	[31:0]		id_c;
	reg				cali_lock;
	
	reg	[5:0]		curr_state;
	reg	[5:0]		next_state;
//fifo register declarition
	wire[31:0]		fifo_data_a;
	wire[31:0]		fifo_data_b;
	wire[31:0]		fifo_data_c;
	reg				rd_en_a;
	reg				rd_en_b;
	reg				rd_en_c;
	
	reg 			dma_wr_enable;
	reg	[31:0]		dma_wr_data;
	
	wire [31:0]		dma_wr_data_o;
	wire			dma_wr_enable_o;
	
	reg [9:0]		fifo_count_a;
	reg [9:0]		fifo_count_b;
	reg [9:0]		fifo_count_c;
//counter 	
	reg [31:0]		update_period;
	reg [31:0]		update_counter;
	reg	[31:0]		counter;
	reg	[7:0]		counter_fifo;
	reg [7:0]		num_reg;
	
	assign dma_wr_data_o=dma_wr_data;
	assign dma_wr_enable=dma_wr_enable_o;
	
	
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
						next_state=S_CALI;
					else 
						next_state=S_IDLE;
				end
			S_CALI:
				begin
					if(counter==CALI_HOLDING_TIME_CNT)
						next_state=S_WAITING_CALI;
					else 
						next_state=S_CALI;
				end 
			S_WAITING_CALI:
				begin
					if(&package_done_cba)
						next_state=S_READY_AMPL;
					else 
						next_state=S_WAITING_CALI;
				end 
			S_READY_AMPL:
				begin
					if(counter==AMPL_HOLDING_TIME_CNT)
						next_state=S_WAITING_AMPL;
					else 
						next_state=S_READY_AMPL;
				end
			S_WAITING_AMPL:		
				begin
					if(&package_done_cba)
						next_state=S_READY_FREQ;
					else 
						next_state=S_WAITING_AMPL;
				end 	
			S_READY_FREQ:
				begin
					if(counter==AMPL_HOLDING_TIME_CNT)
						next_state=S_WAITING_FREQ;
					else 
						next_state=S_READY_FREQ;
				end
			S_WAITING_FREQ:
				begin
					if(&package_done_cba)
						next_state=S_READY_RADS;
					else 
						next_state=S_WAITING_FREQ;
				end 	
			S_READY_RADS:
				begin
					if(counter==AMPL_HOLDING_TIME_CNT)
						next_state=S_WAITING_RADS;
					else 
						next_state=S_READY_RADS;
				end
			S_WAITING_RADS:
				begin
					if(&package_done_cba && !(&error_cba))
						next_state=S_JUDGE_CALIWR_A;
					else if(&package_done_cba && (&error_cba))
						next_state=S_ERROR;
					else 
						next_state=S_WAITING_RADS;
				end 
			S_JUDGE_CALIWR_A:
				begin
					if (cali_lock&& !(error_cba[0]))
						next_state=S_CALIWR_A;
					else if (cali_lock&& error_cba[0])
						next_state=S_JUDGE_CALIWR_B;
					else 
						next_state=S_TIME_HIGH;
				end 
			S_CALIWR_A:
				begin
					if(counter_fifo==NUM_CALI_32-1)
						next_state=S_JUDGE_CALIWR_B;
					else
						next_state=S_CALIWR_A;
				end 
			S_JUDGE_CALIWR_B:
				begin
					if (cali_lock&& !(error_cba[1]))
						next_state=S_CALIWR_B;
					else if (cali_lock&& error_cba[1])
						next_state=S_JUDGE_CALIWR_C;
					else 
						next_state=S_TIME_HIGH;
				end 
			S_CALIWR_B:
				begin
					if(counter_fifo==NUM_CALI_32-1)
						next_state=S_JUDGE_CALIWR_C;
					else
						next_state=S_CALIWR_B;
				end 
			S_JUDGE_CALIWR_C:
				begin
					if (cali_lock&& !(error_cba[2]))
						next_state=S_CALIWR_C;
					else if (cali_lock&& error_cba[2])
						next_state=S_TIME_HIGH;
					else 
						next_state=S_TIME_HIGH;
				end 
			S_CALIWR_C:
				begin
					if(counter_fifo==NUM_CALI_32-1)
						next_state=S_TIME_HIGH;
					else
						next_state=S_CALIWR_C;
				end 	
				
			S_TIME_HIGH:
				begin
					next_state=S_TIME_LOW;
				end 
			S_TIME_LOW:
				begin
					next_state=S_JUDGE_A;
				end 
			S_JUDGE_A:
				begin
					if(error_cba[0])
						next_state=S_JUDGE_B;
					else 
						next_state=S_ID_A;
				end 
			S_ID_A:
				begin 
					next_state=S_DATA_A;
				end
			S_DATA_A:
				begin
					if(counter_fifo==NUM_TOTAL_NCA-1)
						next_state=S_JUDGE_B;
					else
						next_state=S_DATA_A;
				end 
			S_JUDGE_B:
				begin
					if(error_cba[1])
						next_state=S_JUDGE_C;
					else 
						next_state=S_ID_B;
				end 
			S_ID_B:
				begin 
					next_state=S_DATA_B;
				end 
			S_DATA_B:
				begin
					if(counter_fifo==NUM_TOTAL_NCA-1)
						next_state=S_JUDGE_C;
					else
						next_state=S_DATA_B;
				end 
			S_JUDGE_C:
				begin
					if(error_cba[2])
						next_state=S_WAITING;
					else 
						next_state=S_ID_C;
				end
			S_ID_C:
				begin 
					next_state=S_DATA_C;
				end 
			S_DATA_C:
				begin
					if(counter_fifo==NUM_TOTAL_NCA-1)
						next_state=S_WAITING;
					else
						next_state=S_DATA_C;
				end 
			S_WAITING:
				begin 
					if((update_counter==update_period) && start_i)
						next_state=S_READY_AMPL;
					else if((&error_cba)&& start_i )
						next_state=S_ERROR;
					else if(!start_i)
						next_state=S_IDLE;
					else 
						next_state=S_WAITING;
				end 
			S_ERROR:
				begin
					if(!start_i)
						next_state=S_IDLE;
					else
						next_state=S_ERROR;
				end 
		endcase
	end 

//write operation to dma fifo	
	always@(posedge clk)
		begin
			if(rst)
				begin
				dma_wr_enable<=1'b0;
				dma_wr_data	<='b0;
				end 
			else 
				case(curr_state)
				S_TIME_HIGH:
					begin
					dma_wr_data		<=timescale_i[63:32];
					dma_wr_enable	<=1'b1;
					end 
				S_TIME_LOW:
					begin
					dma_wr_data		<=timescale_i[31:0];
					dma_wr_enable	<=1'b1;
					end 
				S_CALIWR_A:
					begin
					dma_wr_enable	<=1'b1;
					dma_wr_data		<=fifo_data_a;
					end 
				S_CALIWR_B:
					begin
					dma_wr_enable	<=1'b1;
					dma_wr_data		<=fifo_data_b;
					end 
				S_CALIWR_C:
					begin
					dma_wr_enable	<=1'b1;
					dma_wr_data		<=fifo_data_c;
					end 
				
				S_ID_A:
					begin 
					dma_wr_data		<=id_a;
					dma_wr_enable	<=1'b1;
					end 
				S_ID_B:
					begin
					dma_wr_data		<=id_b;
					dma_wr_enable	<=1'b1;
					end 
				S_ID_C:
					begin
					dma_wr_data		<=id_c;
					dma_wr_enable	<=1'b1;
					end 
				S_DATA_A:
					begin
					dma_wr_data		<=fifo_data_a;
					dma_wr_enable	<=1'b1;
					end 
				S_DATA_B:
					begin
					dma_wr_data		<=fifo_data_b;
					dma_wr_enable	<=1'b1;
					end 
				S_DATA_C:
					begin
					dma_wr_data		<=fifo_data_c;
					dma_wr_enable	<=1'b1;
					end 
				default:
					begin
					dma_wr_enable<=1'b0;
					dma_wr_data		<=dma_wr_data;
					end 
				endcase
			 
				
		end

//read operation from fifo	
	always@(posedge clk)
		begin
			if(rst)
				begin
				rd_en_a<=1'b0;
				rd_en_b<=1'b0;
				rd_en_c<=1'b0;	
				end 
			else if ((next_state==S_DATA_A) ||(next_state==S_CALIWR_A))
				begin
				rd_en_a<=1'b1;
				rd_en_b<=1'b0;
				rd_en_c<=1'b0;				
				end 
			else if ((next_state==S_DATA_B)||(next_state==S_CALIWR_B))
				begin
				rd_en_a<=1'b0;
				rd_en_b<=1'b1;
				rd_en_c<=1'b0;
				end 
			else if ((next_state==S_DATA_C)||(next_state==S_CALIWR_C))
				begin
				rd_en_a<=1'b0;
				rd_en_b<=1'b0;
				rd_en_c<=1'b1;
				end 
			else 
				begin
				rd_en_a<=1'b0;
				rd_en_b<=1'b0;
				rd_en_c<=1'b0;
				end 
		end 

		
		
	always@(posedge clk)
		begin
		case(curr_state)
			S_IDLE:
				begin 
				byte_numb		<=	NUM_CALI;
				command_code	<=	CMD_CALI;
				start_control	<=	1'b0;
				//error_cba		<=	1'b0;
				counter			<=	1'b0;
				update_counter	<=	1'b0;
				cali_lock		<=	1'b1;
				num_reg			<=	NUM_TOTAL_CA;
				id_a			<=	'd1;
				id_b			<=	'd2;
				id_c			<=	'd3;
				if (update_period_i	>=UPDATE_TIME_MAX_CNT)
					update_period	<=	UPDATE_TIME_MAX_CNT;
				else if(update_period_i	<=UPDATE_TIME_MIN_CNT)
					update_period	<=	UPDATE_TIME_MIN_CNT;
				else 
					update_period	<=	update_period_i;
				end
			S_CALI:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b1;
				counter			<=	counter+'b1;
				update_counter	<=	1'b0;
				cali_lock		<=	1'b1;
				num_reg			<=	NUM_TOTAL_CA;
				end 
			S_WAITING_CALI:
				begin
				byte_numb		<=	NUM_AMPL;
				command_code	<=	CMD_AMPL;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				update_counter	<=	1'b0;
				end 
			S_READY_AMPL:
				begin 
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b1;
				counter			<=	counter+'b1;
				update_counter	<=	'b0;
				end 
			S_WAITING_AMPL:		
				begin
				byte_numb		<=	NUM_FREQ;
				command_code	<=	CMD_FREQ;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				update_counter	<=	update_counter+1'b1;
				end 
			S_READY_FREQ:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b1;
				counter			<=	counter+'b1;
				update_counter	<=	update_counter+1'b1;
				end 
			S_WAITING_FREQ:
				begin
				byte_numb		<=	NUM_RADS;
				command_code	<=	CMD_RADS;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				update_counter	<=	update_counter+1'b1;
				end 
			S_READY_RADS:	
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b1;
				counter			<=	counter+'b1;
				update_counter	<=	update_counter+1'b1;
				end 
			S_WAITING_RADS:
				begin
				byte_numb		<=	NUM_AMPL;
				command_code	<=	CMD_AMPL;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				end
			S_JUDGE_CALIWR_A:
				begin
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				end 
			S_CALIWR_A:
				begin
				counter_fifo	<=counter_fifo+1'b1;
				cali_lock		<=	1'b1;
				update_counter	<=	update_counter+1'b1;
				end 				
			S_JUDGE_CALIWR_B:
				begin
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				end 
			S_CALIWR_B:
				begin
				counter_fifo	<=counter_fifo+1'b1;
				cali_lock		<=	1'b1;
				update_counter	<=	update_counter+1'b1;
				end 				
			S_JUDGE_CALIWR_C:
				begin
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				end 
			S_CALIWR_C:
				begin
				counter_fifo	<=counter_fifo+1'b1;
				cali_lock		<=	1'b0;
				update_counter	<=	update_counter+1'b1;
				end 				
			
			S_TIME_HIGH:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end
			S_TIME_LOW:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
				
			S_JUDGE_A:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	 
			S_ID_A:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	 
			S_DATA_A:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=counter_fifo+1'b1;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_JUDGE_B:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_ID_B:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_DATA_B:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=counter_fifo+1'b1;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_JUDGE_C:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_ID_C:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_DATA_C:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	counter_fifo+1'b1;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end	
			S_WAITING:
				begin
				byte_numb		<=	byte_numb;
				command_code	<=	command_code;
				start_control	<=	1'b0;
				counter			<=	1'b0;
				counter_fifo	<=	'b0;
				num_reg			<=	NUM_TOTAL_NCA;
				update_counter	<=	update_counter+1'b1;
				cali_lock		<=	1'b0;
				end 
		endcase 
		end 
	
	
	cms_package cms_packageA
	(
	.data_i			(data_a_i		),
	.data_valid_i	(data_valid_a_i	),
	.cmd_code_o		(cmd_code_a_o	),
	.cs_o			(cs_a_o			),
	
	.error			(error_cba[0]	),
	.byte_numb_i	(byte_numb		),					
	.command_code_i	(command_code	),                  
	.package_done_o	(package_done_cba[0]),       
	.start_i		(start_control	),                  
	.data_fifo_o	(fifo_data_a),             
	.rd_en_i		(rd_en_a),                                 
    //.data_count		(),            
	.clk			(clk			),                  
	.rst			(rst			)                   
	);                                                  
	
	
	cms_package cms_packageB
	(
	.data_i			(data_b_i		),
	.data_valid_i	(data_valid_b_i	),
	.cmd_code_o		(cmd_code_b_o	),
	.cs_o			(cs_b_o			),
	
	.error			(error_cba[1]	),
	.byte_numb_i	(byte_numb		),					
	.command_code_i	(command_code	),                  
	.package_done_o	(package_done_cba[1]),       
	.start_i		(start_control	),                  
	.data_fifo_o	(fifo_data_b),             
	.rd_en_i		(rd_en_b),                                 
    //.data_count		(),            
	.clk			(clk			),                  
	.rst			(rst			)                   
	);   

	cms_package cms_packageC
	(
	.data_i			(data_c_i		),
	.data_valid_i	(data_valid_c_i	),
	.cmd_code_o		(cmd_code_c_o	),
	.cs_o			(cs_c_o			),
	
	.error			(error_cba[2]	),
	.byte_numb_i	(byte_numb		),					
	.command_code_i	(command_code	),                  
	.package_done_o	(package_done_cba[2]),       
	.start_i		(start_control	),                  
	.data_fifo_o	(fifo_data_c	),             
	.rd_en_i		(rd_en_c		),                                 
	//.data_count		(),
	.clk			(clk			),                  
	.rst			(rst			)                   
	); 	
	
	DMA_FIFO DMA_FIFO
	(
	.din		(dma_wr_data	),					
	.wr_en		(dma_wr_enable	),                  
	.rd_en		(				),       
	.dout		(	),                  
	.data_count	(	data_count	),                                             
                
	.clk		(clk			),                  
	.srst		(rst			)                   
	); 	
	
	
endmodule
