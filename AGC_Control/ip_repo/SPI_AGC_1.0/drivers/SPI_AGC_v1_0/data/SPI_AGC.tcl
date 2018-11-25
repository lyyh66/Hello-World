

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "SPI_AGC" "NUM_INSTANCES" "DEVICE_ID"  "C_S00_AXI_AGC_BASEADDR" "C_S00_AXI_AGC_HIGHADDR"
}
