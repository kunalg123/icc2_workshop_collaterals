set_attribute -objects [get_cells analog_out_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells bg_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ninputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_pinputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_csb_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_0 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_1 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_2 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio0 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio1 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio10 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio11 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio12 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio13 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio14 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio15 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio2 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio4 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio5 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio6 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio7 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio8 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio9 ] -name physical_status -value placed
set_attribute -objects [get_cells irq_pin_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_bias_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells pll_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_rx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_tx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells spi_sck_buf ] -name physical_status -value placed
set_attribute -objects [get_cells trap_buf ] -name physical_status -value placed
set_attribute -objects [get_cells xtal_in_buf ] -name physical_status -value placed
create_io_guide -side right -pad_cells {analog_out_sel_buf bg_ena_buf comp_ena_buf comp_in_buf comp_ninputsrc_buf comp_pinputsrc_buf ext_clk_buf ext_clk_sel_buf ext_reset_buf flash_clk_buf flash_csb_buf} -line {{1701 1402} 1101}
create_io_guide -side left -pad_cells {flash_io_buf_0 flash_io_buf_1 flash_io_buf_2 flash_io_buf_3 gpio0 gpio1 gpio10 gpio11 gpio12 gpio13 gpio14} -line {{ 0 300} 1101}
create_io_guide -side top -pad_cells {gpio15 gpio2 gpio3 gpio4 gpio5 gpio6 gpio7 gpio8 gpio9 irq_pin_buf opamp_bias_ena_buf} -line {{ 300 1701} 1101}
create_io_guide -side bottom -pad_cells {opamp_ena_buf overtemp_buf overtemp_ena_buf pll_clk_buf rcosc_ena_buf rcosc_in_buf reset_buf ser_rx_buf ser_tx_buf spi_sck_buf trap_buf xtal_in_buf} -line {{ 1402 0} 1101}

