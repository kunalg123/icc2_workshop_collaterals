
module raven_wrapper (
	input pll_clk,
	input ext_clk,
	input ext_clk_sel,
	input ext_reset,
	input reset,



	output [15:0] gpio,
	output 	      adc0_ena,
	output 	      adc0_convert,
	input  [9:0]  adc0_data,
	input  	      adc0_done,
	output	      adc0_clk,
	output [1:0]  adc0_inputsrc,
	output 	      adc1_ena,
	output 	      adc1_convert,
	output	      adc1_clk,
	output [1:0]  adc1_inputsrc,
	input  [9:0]  adc1_data,
	input  	      adc1_done,

	output	      dac_ena,
	output [9:0]  dac_value,

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
//	input	      spi_sck,

//	input [7:0]   spi_ro_config,
//	input 	      spi_ro_xtal_ena,
//	input 	      spi_ro_reg_ena,
//	input 	      spi_ro_pll_cp_ena,
//	input 	      spi_ro_pll_vco_ena,
//	input 	      spi_ro_pll_bias_ena,
//	input [3:0]   spi_ro_pll_trim,

//	input [11:0]  spi_ro_mfgr_id,
//	input [7:0]   spi_ro_prod_id,
//	input [3:0]   spi_ro_mask_rev,

	output ser_tx,
	input  ser_rx,

	// IRQ
	input  irq_pin,		// dedicated IRQ pin
//	input  irq_spi,		// IRQ from standalone SPI

	// trap
	output trap,

	// Flash memory control (SPI master)
	output flash_csb,
	output flash_clk,

	output flash_io0_oeb,
	output flash_io1_oeb,
	output flash_io2_oeb,
	output flash_io3_oeb,

	output flash_io0_do,
	output flash_io1_do,
	output flash_io2_do,
	output flash_io3_do,

	input  flash_io0_di,
	input  flash_io1_di,
	input  flash_io2_di,
	input  flash_io3_di
);

  wire inter_ram_wenb;
  wire [9:0] inter_ram_addr;
  wire [31:0] inter_ram_wdata;
  wire [31:0] inter_ram_rdata;
  wire [15:0] inter_gpio_outenb, inter_gpio_out, inter_gpio_in;
  wire inter_spi_sck ;
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
	.pll_clk	(pll_clk), 	
	.ext_clk	(ext_clk),
	.ext_clk_sel	(ext_clk_sel),
	.ext_reset	(ext_reset),
	.reset		(reset),

	.ram_wenb	(inter_ram_wenb),
	.ram_addr	(inter_ram_addr),
	.ram_wdata	(inter_ram_wdata),
	.ram_rdata	(inter_ram_rdata),

	.gpio_out	(inter_gpio_out),
	.gpio_in	(inter_gpio_in),
	.gpio_outenb	(inter_gpio_outenb),
	.adc0_ena	(adc0_ena),
	.adc0_convert	(adc0_convert),
	.adc0_data	(adc0_data),
	.adc0_done	(adc0_done),
	.adc0_clk	(adc0_clk),
	.adc0_inputsrc	(adc0_inputsrc),
	.adc1_ena	(adc1_ena),
	.adc1_convert	(adc1_convert),
	.adc1_clk	(adc1_clk),
	.adc1_inputsrc	(adc1_inputsrc),
	.adc1_data	(adc1_data),
	.adc1_done	(adc1_done),
	.dac_ena	(dac_ena),
	.dac_value	(dac_value),
	.analog_out_sel	(analog_out_sel),
	.opamp_ena	(opamp_ena),
	.opamp_bias_ena	(opamp_bias_ena),
	.bg_ena	(bg_ena),
	.comp_ena	(comp_ena),
	.comp_ninputsrc	(comp_ninputsrc),
	.comp_pinputsrc	(comp_pinputsrc),
	.rcosc_ena	(rcosc_ena),
	.overtemp_ena	(overtemp_ena),
	.overtemp	(overtemp),
	.rcosc_in	(rcosc_in),
	.xtal_in	(xtal_in),
	.comp_in	(comp_in),
	.spi_sck	(inter_spi_sck),
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
	.ser_tx	(ser_tx),
	.ser_rx	(ser_rx),
	.irq_pin	(irq_pin),
	.irq_spi	(inter_irq_spi),
	.trap	(trap),
	.flash_csb	(flash_csb),
	.flash_clk	(flash_clk),
	.flash_io0_oeb	(flash_io0_oeb),
	.flash_io1_oeb	(flash_io1_oeb),
	.flash_io2_oeb	(flash_io2_oeb),
	.flash_io3_oeb	(flash_io3_oeb),
	.flash_io0_do	(flash_io0_do),
	.flash_io1_do	(flash_io1_do),
	.flash_io2_do	(flash_io2_do),
	.flash_io3_do	(flash_io3_do),
	.flash_io0_di	(flash_io0_di),
	.flash_io1_di	(flash_io1_di),
	.flash_io2_di	(flash_io2_di),
	.flash_io3_di	(flash_io3_di)

);

sram_32_1024_freepdk45 sram (
	.web0  (inter_ram_wenb),
	.addr0 (inter_ram_addr),
	.din0  (inter_ram_wdata),
        .dout0 (inter_ram_rdata),
	.clk0  (pll_clk),
	.csb0  (reset)
);

raven_spi spi (
           .RST(reset),
           .SCK(inter_spi_sck),
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
           .reset(reset),
           .trap(),
           .mask_rev_in(),               // Metal programmed
           .mfgr_id(inter_spi_ro_mfgr_id),
           .prod_id(inter_spi_ro_prod_id),
           .mask_rev(inter_spi_ro_mask_rev)

);
endmodule

