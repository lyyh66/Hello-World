
`timescale 1 ns / 1 ps

	module SPI_AGC_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI_AGC
		parameter integer C_S00_AXI_AGC_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_AGC_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        output wire spi_clk,
        output wire spi_cs,
        output reset,
        inout spi_sdio,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI_AGC
		input wire  s00_axi_agc_aclk,
		input wire  s00_axi_agc_aresetn,
		input wire [C_S00_AXI_AGC_ADDR_WIDTH-1 : 0] s00_axi_agc_awaddr,
		input wire [2 : 0] s00_axi_agc_awprot,
		input wire  s00_axi_agc_awvalid,
		output wire  s00_axi_agc_awready,
		input wire [C_S00_AXI_AGC_DATA_WIDTH-1 : 0] s00_axi_agc_wdata,
		input wire [(C_S00_AXI_AGC_DATA_WIDTH/8)-1 : 0] s00_axi_agc_wstrb,
		input wire  s00_axi_agc_wvalid,
		output wire  s00_axi_agc_wready,
		output wire [1 : 0] s00_axi_agc_bresp,
		output wire  s00_axi_agc_bvalid,
		input wire  s00_axi_agc_bready,
		input wire [C_S00_AXI_AGC_ADDR_WIDTH-1 : 0] s00_axi_agc_araddr,
		input wire [2 : 0] s00_axi_agc_arprot,
		input wire  s00_axi_agc_arvalid,
		output wire  s00_axi_agc_arready,
		output wire [C_S00_AXI_AGC_DATA_WIDTH-1 : 0] s00_axi_agc_rdata,
		output wire [1 : 0] s00_axi_agc_rresp,
		output wire  s00_axi_agc_rvalid,
		input wire  s00_axi_agc_rready
	);
// Instantiation of Axi Bus Interface S00_AXI_AGC
	SPI_AGC_v1_0_S00_AXI_AGC # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_AGC_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_AGC_ADDR_WIDTH)
	) SPI_AGC_v1_0_S00_AXI_AGC_inst (
		.S_AXI_ACLK(s00_axi_agc_aclk),
		.S_AXI_ARESETN(s00_axi_agc_aresetn),
		.S_AXI_AWADDR(s00_axi_agc_awaddr),
		.S_AXI_AWPROT(s00_axi_agc_awprot),
		.S_AXI_AWVALID(s00_axi_agc_awvalid),
		.S_AXI_AWREADY(s00_axi_agc_awready),
		.S_AXI_WDATA(s00_axi_agc_wdata),
		.S_AXI_WSTRB(s00_axi_agc_wstrb),
		.S_AXI_WVALID(s00_axi_agc_wvalid),
		.S_AXI_WREADY(s00_axi_agc_wready),
		.S_AXI_BRESP(s00_axi_agc_bresp),
		.S_AXI_BVALID(s00_axi_agc_bvalid),
		.S_AXI_BREADY(s00_axi_agc_bready),
		.S_AXI_ARADDR(s00_axi_agc_araddr),
		.S_AXI_ARPROT(s00_axi_agc_arprot),
		.S_AXI_ARVALID(s00_axi_agc_arvalid),
		.S_AXI_ARREADY(s00_axi_agc_arready),
		.S_AXI_RDATA(s00_axi_agc_rdata),
		.S_AXI_RRESP(s00_axi_agc_rresp),
		.S_AXI_RVALID(s00_axi_agc_rvalid),
		.S_AXI_RREADY(s00_axi_agc_rready),
	    
	    .spi_clk(spi_clk),
        .spi_cs(spi_cs),
        .reset(reset),
        .spi_sdio(spi_sdio)
	
	);
     wire spi_mosi;
     wire spi_miso;
     wire ioControl;
     wire spi_clk;
     wire spi_cs;
     wire spi_data;
     wire spi_mode;
     wire sig_R0W1;
     
     
     
   IOBUF #(
       .DRIVE(12), // Specify the output drive strength
       .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
       .IOSTANDARD("DEFAULT"), // Specify the I/O standard
       .SLEW("SLOW") // Specify the output slew rate
    ) IOBUF_inst (
       .O(spi_mosi),     // Buffer output
       .IO(spi_sdio),   // Buffer inout port (connect directly to top-level port)
       .I(spi_miso),     // Buffer input
       .T(ioControl)      // 3-state enable input, high=input, low=output
    );
    
    clkgen (
    .clk(s00_axi_agc_aclk),
    .clkout(spi_clk)
    );
    
     test_spi (
       .spi_clk(spi_clk),
       .spi_cs(spi_cs),
       .spi_data(spi_data),
       .spi_mode(spi_mode),
       .sig_R0W1(sig_R0W1),
       .spi_mosi(spi_mosi),
       .spi_miso(spi_miso),
       .read_data(read_data),
       .reset(reset)
       )
    ;
   
	// Add user logic here

	// User logic ends

	endmodule
