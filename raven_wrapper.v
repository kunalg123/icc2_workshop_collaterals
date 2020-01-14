
module raven_wrapper (
	input pll_clk,
	input ext_clk,
	input ext_clk_sel,
	input ext_reset,
	input reset,
 	input spi_sck,
	output [15:0] gpio,

	output	      analog_out_sel,	// Analog output select (DAC or bandgap)
	output	      opamp_ena,	// Op-amp enable for analog output
	output	      opamp_bias_ena,	// Op-amp bias enable for analog output
	output	      bg_ena,		// Bandgap enable

	output	      comp_ena,
	output [1:0]  comp_ninputsrc,
	output [1:0]  comp_pinputsrc,
	output	      rcosc_ena,

	output	      overtemp_ena,
	input	      overtemp,
	input	      rcosc_in,		// RC oscillator output
	input	      xtal_in,		// crystal oscillator output
	input	      comp_in,		// comparator output

	output ser_tx,
	input  ser_rx,

	// IRQ
	input  irq_pin,		// dedicated IRQ pin

	// trap
	output trap,

	// Flash memory control (SPI master)
	output flash_csb,
	output flash_clk,

	inout flash_io0,
	inout flash_io1,
	inout flash_io2,
	inout flash_io3

);

  wire analog_out_sel_core ;
  wire opamp_ena_core ;
  wire opamp_bias_ena_core ;
  wire bg_ena_core ;
  wire comp_ena_core ;
  wire rcosc_ena_core ;
  wire overtemp_ena_core ;
  wire ser_tx_core ;
  wire trap_core ;
  wire flash_csb_core ;
  wire flash_clk_core ;
  wire [1:0] comp_ninputsrc_core ;
  wire [1:0] comp_pinputsrc_core ;

  wire pll_clk_core ;
  wire ext_clk_core ;
  wire ext_clk_sel_core ;
  wire ext_reset_core ;
  wire reset_core ;
  wire spi_sck_core ;
  wire overtemp_core ;
  wire rcosc_in_core ;
  wire xtal_in_core ;
  wire comp_in_core ;
  wire ser_rx_core ;
  wire irq_pin_core ;

  wire inter_ram_wenb;
  wire [9:0] inter_ram_addr;
  wire [31:0] inter_ram_wdata;
  wire [31:0] inter_ram_rdata;
  wire [15:0] inter_gpio_outenb, inter_gpio_out, inter_gpio_in;
  wire inter_spi_ro_xtal_ena ;
  wire inter_spi_ro_reg_ena ;
  wire inter_spi_ro_pll_cp_ena ;
  wire inter_spi_ro_pll_vco_ena ;
  wire inter_spi_ro_pll_bias_ena ;
  wire [3:0] inter_spi_ro_pll_trim ;
  wire [11:0] inter_spi_ro_mfgr_id ;
  wire [7:0] inter_spi_ro_prod_id ;
  wire [3:0] inter_spi_ro_mask_rev ;
  wire inter_irq_spi ;
  wire inter_flash_io0_di, inter_flash_io1_di, inter_flash_io2_di, inter_flash_io3_di;
  wire inter_flash_io0_do, inter_flash_io1_do, inter_flash_io2_do, inter_flash_io3_do;
  wire inter_flash_io0_oeb, inter_flash_io1_oeb, inter_flash_io2_oeb, inter_flash_io3_oeb;

PADOUT analog_out_sel_buf (
	 .YPAD(analog_out_sel),
	 .DO(analog_out_sel_core)
);

PADOUT opamp_ena_buf (
	 .YPAD(opamp_ena),
	 .DO(opamp_ena_core)
);

PADOUT opamp_bias_ena_buf (
	 .YPAD(opamp_bias_ena),
	 .DO(opamp_bias_ena_core)
);

PADOUT bg_ena_buf (
	 .YPAD(bg_ena),
	 .DO(bg_ena_core)
);

PADOUT comp_ena_buf (
	 .YPAD(comp_ena),
	 .DO(comp_ena_core)
);

PADOUT rcosc_ena_buf (
	 .YPAD(rcosc_ena),
	 .DO(rcosc_ena_core)
);

PADOUT overtemp_ena_buf (
	 .YPAD(overtemp_ena),
	 .DO(overtemp_ena_core)
);

PADOUT ser_tx_buf (
	 .YPAD(ser_tx),
	 .DO(ser_tx_core)
);

PADOUT trap_buf (
	 .YPAD(trap),
	 .DO(trap_core)
);

PADOUT flash_csb_buf (
	 .YPAD(flash_csb),
	 .DO(flash_csb_core)
);

PADOUT flash_clk_buf (
	 .YPAD(flash_clk),
	 .DO(flash_clk_core)
);

PADOUT comp_ninputsrc_buf (
	 .YPAD(comp_ninputsrc),
	 .DO(comp_ninputsrc_core)
);

PADOUT comp_pinputsrc_buf (
	 .YPAD(comp_pinputsrc),
	 .DO(comp_pinputsrc_core)
);

PADINC pll_clk_buf (
	 .YPAD(pll_clk),
	 .DI(pll_clk_core)
);

PADINC ext_clk_buf (
	 .YPAD(ext_clk),
	 .DI(ext_clk_core)
);

PADINC ext_clk_sel_buf (
	 .YPAD(ext_clk_sel),
	 .DI(ext_clk_sel_core)
);

PADINC ext_reset_buf (
	 .YPAD(ext_reset),
	 .DI(ext_reset_core)
);

PADINC reset_buf (
	 .YPAD(reset),
	 .DI(reset_core)
);

PADINC spi_sck_buf (
	 .YPAD(spi_sck),
	 .DI(spi_sck_core)
);

PADINC overtemp_buf (
	 .YPAD(overtemp),
	 .DI(overtemp_core)
);

PADINC rcosc_in_buf (
	 .YPAD(rcosc_in),
	 .DI(rcosc_in_core)
);

PADINC xtal_in_buf (
	 .YPAD(xtal_in),
	 .DI(xtal_in_core)
);

PADINC comp_in_buf (
	 .YPAD(comp_in),
	 .DI(comp_in_core)
);

PADINC ser_rx_buf (
	 .YPAD(ser_rx),
	 .DI(ser_rx_core)
);

PADINC irq_pin_buf (
	 .YPAD(irq_pin),
	 .DI(irq_pin_core)
);


PADINOUT flash_io_buf_0 (
        .DI(inter_flash_io0_di),
        .DO(inter_flash_io0_do),
        .OEN(inter_flash_io0_oeb),
        .YPAD(flash_io0)
);

PADINOUT flash_io_buf_1 (
        .DI(inter_flash_io1_di),
        .DO(inter_flash_io1_do),
        .OEN(inter_flash_io1_oeb),
        .YPAD(flash_io1)
);

PADINOUT flash_io_buf_2 (
        .DI(inter_flash_io2_di),
        .DO(inter_flash_io2_do),
        .OEN(inter_flash_io2_oeb),
        .YPAD(flash_io2)
);

PADINOUT flash_io_buf_3 (
        .DI(inter_flash_io3_di),
        .DO(inter_flash_io3_do),
        .OEN(inter_flash_io3_oeb),
        .YPAD(flash_io3)
);

PADINOUT gpio0 (
	.DI(inter_gpio_in[0]),
	.DO(inter_gpio_out[0]),
	.OEN(inter_gpio_outenb[0]),
	.YPAD(gpio[0])
);

PADINOUT gpio1 (
        .DI(inter_gpio_in[1]),
        .DO(inter_gpio_out[1]),
        .OEN(inter_gpio_outenb[1]),
        .YPAD(gpio[1])
);

PADINOUT gpio2 (
        .DI(inter_gpio_in[2]),
        .DO(inter_gpio_out[2]),
        .OEN(inter_gpio_outenb[2]),
        .YPAD(gpio[2])
);

PADINOUT gpio3 (
        .DI(inter_gpio_in[3]),
        .DO(inter_gpio_out[3]),
        .OEN(inter_gpio_outenb[3]),
        .YPAD(gpio[3])
);

PADINOUT gpio4 (
        .DI(inter_gpio_in[4]),
        .DO(inter_gpio_out[4]),
        .OEN(inter_gpio_outenb[4]),
        .YPAD(gpio[4])
);

PADINOUT gpio5 (
        .DI(inter_gpio_in[5]),
        .DO(inter_gpio_out[5]),
        .OEN(inter_gpio_outenb[5]),
        .YPAD(gpio[5])
);

PADINOUT gpio6 (
        .DI(inter_gpio_in[6]),
        .DO(inter_gpio_out[6]),
        .OEN(inter_gpio_outenb[6]),
        .YPAD(gpio[6])
);

PADINOUT gpio7 (
        .DI(inter_gpio_in[7]),
        .DO(inter_gpio_out[7]),
        .OEN(inter_gpio_outenb[7]),
        .YPAD(gpio[7])
);

PADINOUT gpio8 (
        .DI(inter_gpio_in[8]),
        .DO(inter_gpio_out[8]),
        .OEN(inter_gpio_outenb[8]),
        .YPAD(gpio[8])
);

PADINOUT gpio9 (
        .DI(inter_gpio_in[9]),
        .DO(inter_gpio_out[9]),
        .OEN(inter_gpio_outenb[9]),
        .YPAD(gpio[9])
);

PADINOUT gpio10 (
        .DI(inter_gpio_in[10]),
        .DO(inter_gpio_out[10]),
        .OEN(inter_gpio_outenb[10]),
        .YPAD(gpio[10])
);

PADINOUT gpio11 (
        .DI(inter_gpio_in[11]),
        .DO(inter_gpio_out[11]),
        .OEN(inter_gpio_outenb[11]),
        .YPAD(gpio[11])
);

PADINOUT gpio12 (
        .DI(inter_gpio_in[12]),
        .DO(inter_gpio_out[12]),
        .OEN(inter_gpio_outenb[12]),
        .YPAD(gpio[12])
);

PADINOUT gpio13 (
        .DI(inter_gpio_in[13]),
        .DO(inter_gpio_out[13]),
        .OEN(inter_gpio_outenb[13]),
        .YPAD(gpio[13])
);

PADINOUT gpio14 (
        .DI(inter_gpio_in[14]),
        .DO(inter_gpio_out[14]),
        .OEN(inter_gpio_outenb[14]),
        .YPAD(gpio[14])
);

PADINOUT gpio15 (
        .DI(inter_gpio_in[15]),
        .DO(inter_gpio_out[15]),
        .OEN(inter_gpio_outenb[15]),
        .YPAD(gpio[15])
);

raven_soc core1 ( 
	.pll_clk	(pll_clk_core), 	
	.ext_clk	(ext_clk_core),
	.ext_clk_sel	(ext_clk_sel_core),
	.ext_reset	(ext_reset_core),
	.reset		(reset_core),

	.ram_wenb	(inter_ram_wenb),
	.ram_addr	(inter_ram_addr),
	.ram_wdata	(inter_ram_wdata),
	.ram_rdata	(inter_ram_rdata),

	.gpio_out	(inter_gpio_out),
	.gpio_in	(inter_gpio_in),
	.gpio_outenb	(inter_gpio_outenb),
	.analog_out_sel	(analog_out_sel_core),
	.opamp_ena	(opamp_ena_core),
	.opamp_bias_ena	(opamp_bias_ena_core),
	.bg_ena	(bg_ena_core),
	.comp_ena	(comp_ena_core),
	.comp_ninputsrc	(comp_ninputsrc_core),
	.comp_pinputsrc	(comp_pinputsrc_core),
	.rcosc_ena	(rcosc_ena_core),
	.overtemp_ena	(overtemp_ena_core),
	.overtemp	(overtemp_core),
	.rcosc_in	(rcosc_in_core),
	.xtal_in	(xtal_in_core),
	.comp_in	(comp_in_core),
	.spi_sck	(spi_sck_core),
	.spi_ro_config	(8'h00),
	.spi_ro_xtal_ena	(inter_spi_ro_xtal_ena),
	.spi_ro_reg_ena	(inter_spi_ro_reg_ena),
	.spi_ro_pll_cp_ena	(inter_spi_ro_pll_cp_ena),
	.spi_ro_pll_vco_ena	(inter_spi_ro_pll_vco_ena),
	.spi_ro_pll_bias_ena	(inter_spi_ro_pll_bias_ena),
	.spi_ro_pll_trim	(inter_spi_ro_pll_trim),
	.spi_ro_mfgr_id	(inter_spi_ro_mfgr_id),
	.spi_ro_prod_id	(inter_spi_ro_prod_id),
	.spi_ro_mask_rev	(inter_spi_ro_mask_rev),
	.ser_tx	(ser_tx_core),
	.ser_rx	(ser_rx_core),
	.irq_pin	(irq_pin_core),
	.irq_spi	(inter_irq_spi),
	.trap	(trap_core),
	.flash_csb	(flash_csb_core),
	.flash_clk	(flash_clk_core),
	.flash_io0_oeb	(inter_flash_io0_oeb),
	.flash_io1_oeb	(inter_flash_io1_oeb),
	.flash_io2_oeb	(inter_flash_io2_oeb),
	.flash_io3_oeb	(inter_flash_io3_oeb),
	.flash_io0_do	(inter_flash_io0_do),
	.flash_io1_do	(inter_flash_io1_do),
	.flash_io2_do	(inter_flash_io2_do),
	.flash_io3_do	(inter_flash_io3_do),
	.flash_io0_di	(inter_flash_io0_di),
	.flash_io1_di	(inter_flash_io1_di),
	.flash_io2_di	(inter_flash_io2_di),
	.flash_io3_di	(inter_flash_io3_di)

);

sram_32_1024_freepdk45 sram (
	.web0  (inter_ram_wenb),
	.addr0 (inter_ram_addr),
	.din0  (inter_ram_wdata),
        .dout0 (inter_ram_rdata),
	.clk0  (pll_clk),
	.csb0  (reset_core)
);

raven_spi spi (
           .RST(reset_core),
           .SCK(spi_sck_core),
           .SDI(),
           .CSB(),
           .SDO(),
           .sdo_enb(),
           .xtal_ena(inter_spi_ro_xtal_ena),
           .reg_ena(inter_spi_ro_reg_ena),
           .pll_vco_ena(inter_spi_ro_pll_vco_ena),
           .pll_cp_ena(inter_spi_ro_pll_cp_ena),
           .pll_bias_ena(inter_spi_ro_pll_bias_ena),
           .pll_trim(inter_spi_ro_pll_trim),
           .pll_bypass(),
           .irq(inter_irq_spi),
           .reset(),
           .trap(),
           .mask_rev_in(),               // Metal programmed
           .mfgr_id(inter_spi_ro_mfgr_id),
           .prod_id(inter_spi_ro_prod_id),
           .mask_rev(inter_spi_ro_mask_rev)

);
endmodule

