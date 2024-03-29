// original ZXUNO port by DistWave (2016)
// fpganes
// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

`timescale 1ns / 1ps

module NES_TOP
(

	// Clocks
	input wire	clock_50_i,

	// Buttons
	input wire [4:1]	btn_n_i,

	// SRAMs (AS7C34096)
	output wire	[18:0]sram_addr_o  = 18'b0000000000000000000,
	inout wire	[7:0]sram_data_io	= 8'bzzzzzzzz,
	output wire	sram_we_n_o		= 1'b1,
	output wire	sram_oe_n_o		= 1'b1,
		
	// SDRAM	(H57V256)
	output wire	[12:0]sdram_ad_o,
	inout wire	[15:0]sdram_da_io,
	output wire	[1:0]sdram_ba_o,
	output wire	[1:0]sdram_dqm_o,
	output wire	sdram_ras_o,
	output wire	sdram_cas_o,
	output wire	sdram_cke_o,
	output wire	sdram_clk_o,
	output wire	sdram_cs_o,
	output wire	sdram_we_o,

	// PS2
	inout wire	ps2_clk_io			= 1'bz,
	inout wire	ps2_data_io			= 1'bz,
	inout wire	ps2_mouse_clk_io  	= 1'bz,
	inout wire	ps2_mouse_data_io 	= 1'bz,

	// SD Card
	output wire	sd_cs_n_o			= 1'b1,
	output wire	sd_sclk_o			= 1'b0,
	output wire	sd_mosi_o			= 1'b0,
	input wire	sd_miso_i,

	// Joysticks
	input wire	joy1_up_i,
	input wire	joy1_down_i,
	input wire	joy1_left_i,
	input wire	joy1_right_i,
	input wire	joy1_p6_i,
	input wire	joy1_p9_i,
	input wire	joy2_up_i,
	input wire	joy2_down_i,
	input wire	joy2_left_i,
	input wire	joy2_right_i,
	input wire	joy2_p6_i,
	input wire	joy2_p9_i,
	output wire	joyX_p7_o			= 1'b1,

	// Audio
	output wire	dac_l_o				= 1'b0,
	output wire	dac_r_o				= 1'b0,
	/*
	input wire	ear_i,
	output wire	mic_o				= 1'b0, 
   */
		// VGA
	output wire	[4:0]vga_r_o,
	output wire	[4:0]vga_g_o,
	output wire	[4:0]vga_b_o,
	output wire	vga_hsync_n_o,
	output wire	vga_vsync_n_o

		// HDMI
	//output wire	[7:0]tmds_o				= 8'b00000000,

		//STM32
	/*
	input wire	stm_tx_i,
	output wire	stm_rx_o,
	output wire	stm_rst_o			= 1'b0,
		
	inout wire	stm_b8_io,
	inout wire	stm_b9_io,
	inout wire	stm_b12_io,
	inout wire	stm_b13_io,
	inout wire	stm_b14_io,
	inout wire	stm_b15_io
	*/

  );

  wire osd_window;
  wire osd_pixel;
  wire [15:0] dipswitches;
  wire scanlines;
  wire hq_enable;
  wire border;
  
  assign scanlines = dipswitches[0];
  assign hq_enable = dipswitches[1];
  
  wire host_reset_n;
  wire host_reset_loader;
  wire host_divert_sdcard;
  wire host_divert_keyboard;
  wire host_select;
  wire host_start;
  
  reg boot_state = 1'b0;
 
  wire [31:0] bootdata;
  wire bootdata_req;
  reg bootdata_ack = 1'b0;
  
  wire AUD_MCLK;
  wire AUD_LRCK;
  wire AUD_SCK;
  wire AUD_SDIN;
  
  wire [3:0] vga_blue;
  wire [3:0] vga_green;
  wire [3:0] vga_red;
  
  wire vga_hsync;
  wire vga_vsync;
  wire vga_blank;
  wire [7:0] vga_osd_r;
  wire [7:0] vga_osd_g;
  wire [7:0] vga_osd_b;
  


  
  wire clock_locked;
  wire clk;
  wire clock_dvi_s;
  reg clk_loader;
  wire clk_gameloader;
  wire clk_fifo;

  wire clk_ctrl;
   wire clk_audio;
  reg[15:0] data;
  reg [7:0] loader_input;
    
  wire joypad_data;
  
  nes_clk clock_21mhz
  (
		 .inclk0(clock_50_i), 
		 .c0(clk), 
		 .c1(clk_ctrl), 
		 .c2(clk_audio),
		 .c3(clock_dvi_s),
		 .LOCKED(clock_locked)
	);

  
    // NES Palette -> RGB332 conversion
  reg [14:0] pallut[0:63];
  //initial $readmemh("../../src/nes_palette.txt", pallut);
  always@(posedge clk) begin 
		pallut[0]  = 15'h3def;
		pallut[1]  = 15'h7c00;
		pallut[2]  = 15'h5c00;
		pallut[3]  = 15'h5ca8;
		pallut[4]  = 15'h4012;
		pallut[5]  = 15'h1015;
		pallut[6]  = 15'h0055;
		pallut[7]  = 15'h0051;
		pallut[8]  = 15'h00ca;
		pallut[9]  = 15'h01e0;
		pallut[10] = 15'h01a0;
		pallut[11] = 15'h0160;
		pallut[12] = 15'h2d00;
		pallut[13] = 15'h0000;
		pallut[14] = 15'h0000;
		pallut[15] = 15'h0000;
		pallut[16] = 15'h5ef7;
		pallut[17] = 15'h7de0;
		pallut[18] = 15'h7d60;
		pallut[19] = 15'h7d0d;
		pallut[20] = 15'h641b;
		pallut[21] = 15'h2c1c;
		pallut[22] = 15'h00ff;
		pallut[23] = 15'h097c;
		pallut[24] = 15'h01f5;
		pallut[25] = 15'h02e0;
		pallut[26] = 15'h02a0;
		pallut[27] = 15'h22a0;
		pallut[28] = 15'h4620;
		pallut[29] = 15'h0000;
		pallut[30] = 15'h0000;
		pallut[31] = 15'h0000;
		pallut[32] = 15'h7fff;
		pallut[33] = 15'h7ee7;
		pallut[34] = 15'h7e2d;
		pallut[35] = 15'h7df3;
		pallut[36] = 15'h7dff;
		pallut[37] = 15'h4d7f;
		pallut[38] = 15'h2dff;
		pallut[39] = 15'h229f;
		pallut[40] = 15'h02ff;
		pallut[41] = 15'h0ff7;
		pallut[42] = 15'h2b6b;
		pallut[43] = 15'h4feb;
		pallut[44] = 15'h6fa0;
		pallut[45] = 15'h3def;
		pallut[46] = 15'h0000;
		pallut[47] = 15'h0000;
		pallut[48] = 15'h7fff;
		pallut[49] = 15'h7f94;
		pallut[50] = 15'h7ef7;
		pallut[51] = 15'h7efb;
		pallut[52] = 15'h7eff;
		pallut[53] = 15'h629f;
		pallut[54] = 15'h5b5e;
		pallut[55] = 15'h579f;
		pallut[56] = 15'h3f7f;
		pallut[57] = 15'h3ffb;
		pallut[58] = 15'h5ff7;
		pallut[59] = 15'h6ff7;
		pallut[60] = 15'h7fe0;
		pallut[61] = 15'h7f7f;
		pallut[62] = 15'h0000;
		pallut[63] = 15'h0000;
  end
  
  
  
  wire [8:0] cycle;
  wire [8:0] scanline;
  wire [15:0] sample;
  wire [5:0] color;
  wire joypad_strobe;
  wire [1:0] joypad_clock;
  wire [21:0] memory_addr;
  wire memory_read_cpu, memory_read_ppu;
  wire memory_write;
  wire [7:0] memory_din_cpu, memory_din_ppu;
  wire [7:0] memory_dout;
  reg [7:0] joypad_bits, joypad_bits2;
  reg [1:0] last_joypad_clock;
  wire [31:0] dbgadr;

  wire [1:0] dbgctr;

  reg [1:0] nes_ce;

  reg [13:0] debugaddr;
  wire [7:0] debugdata;


 
  wire ram_WE_n;          // Write Enable. WRITE when Low.
  wire [18:0] ram_a;
  wire [7:0] from_sram;
  wire [7:0] to_sram;
  
  

  
	assign sram_oe_n_o	= 1'b0;				//-- sempre ativa
	assign sram_we_n_o	= ram_WE_n;
	assign sram_addr_o	= ram_a[18:0];
	assign sram_data_io	= ram_WE_n == 0 ? to_sram : 8'bz;
   assign from_sram  	= sram_data_io;
	
	
	
	  wire [7:0] dbg1;
	  wire [7:0] dbg2;
	  wire [7:0] dbg3;
	  wire [4:0] debugleds;
	
	
	

  
  wire [21:0] loader_addr;
  wire [7:0] loader_write_data;
  wire loader_reset = host_reset_loader;// &&  uart_loader_conf[0];
  wire loader_write;
  wire [31:0] mapper_flags;
  wire loader_done, loader_fail;
  wire empty_fifo;
  
  GameLoader loader(
    clk_gameloader, 
    loader_reset, 
	 loader_input, 
	 clk_loader,
	 loader_addr, 
	 loader_write_data, 
	 loader_write,
	 mapper_flags,
	 loader_done,
	 loader_fail
	);
	
	 
  wire [7:0] joystick1, joystick2;
  wire p_sel = !host_select;
  wire p_start = !host_start;
  
  // 1 if the button was pressed, 0 otherwise.
  //assign joystick1 = {~joy1_right_i, ~joy1_left_i, ~joy1_down_i, ~joy1_up_i, ~btn_n_i[1], ~btn_n_i[2], ~joy1_p9_i, ~joy1_p6_i};
  assign joystick1 = {~joy1_right_i, ~joy1_left_i, ~joy1_down_i, ~joy1_up_i, ~p_sel, ~p_start, ~joy1_p9_i, ~joy1_p6_i};
  assign joystick2 = {~joy2_right_i, ~joy2_left_i, ~joy2_down_i, ~joy2_up_i, ~btn_n_i[3], ~btn_n_i[4], ~joy2_p9_i, ~joy2_p6_i};
  
	
	always @(posedge clk) begin
		 if (joypad_strobe) 
		 begin
				joypad_bits  <= joystick1; 
				joypad_bits2 <= joystick2;
		 end
		 
		 if (!joypad_clock[0] && last_joypad_clock[0])
				joypad_bits <= {1'b0, joypad_bits[7:1]};
			
		 if (!joypad_clock[1] && last_joypad_clock[1])
				joypad_bits2 <= {1'b0, joypad_bits2[7:1]};
			
		 last_joypad_clock <= joypad_clock;
  end

  wire reset_nes = (!host_reset_n || !loader_done);
  wire run_mem = (nes_ce == 0) && !reset_nes;
  wire run_nes = (nes_ce == 3) && !reset_nes;


  // NES is clocked at every 4th cycle.
  always @(posedge clk)
    nes_ce <= nes_ce + 1;
    
  NES nes(clk, reset_nes, run_nes,
          mapper_flags,
          sample, color,
          joypad_strobe, joypad_clock, {joypad_bits2[0], joypad_bits[0]},
          5'b11111,
          memory_addr,
          memory_read_cpu, memory_din_cpu,
          memory_read_ppu, memory_din_ppu,
          memory_write, memory_dout,
          cycle, scanline,
          dbgadr,
          dbgctr
   );

  // This is the memory controller to access the board's SRAM
  wire ram_busy;
  
  MemoryController memory(clk,
                          memory_read_cpu && run_mem, 
                          memory_read_ppu && run_mem,
                          memory_write && run_mem || loader_write,
                          loader_write ? loader_addr : memory_addr,
                          loader_write ? loader_write_data : memory_dout,
                          memory_din_cpu,
                          memory_din_ppu,
                          ram_busy,
								  
								  ram_WE_n,
                          ram_a,
                          from_sram,
	                       to_sram,
								  debugaddr,
								  dbg1,dbg2,dbg3
								  ,debugleds
								);
								  
  reg ramfail;
  always @(posedge clk) begin
    if (loader_reset)
      ramfail <= 0;
    else
      ramfail <= ram_busy && loader_write || ramfail;
  end

  wire [14:0] doubler_pixel;
  wire doubler_sync;
  wire [9:0] vga_hcounter, doubler_x;
  wire [9:0] vga_vcounter;
  
  VgaDriver vga(
		clk, 
		vga_hsync, 
		vga_vsync, 
		vga_red, 
		vga_green, 
		vga_blue, 
		vga_hcounter, 
		vga_vcounter, 
		doubler_x, 
		doubler_pixel, 
		doubler_sync, 
		1'b0,
		vga_blank);
		
		
	
  assign vga_hsync_n_o = vga_hsync;
  assign vga_vsync_n_o = vga_vsync;
  assign vga_r_o = vga_osd_r[7:4];
  assign vga_g_o = vga_osd_g[7:4];
  assign vga_b_o = vga_osd_b[7:4];
	
	/*		
	//HDMI OK em algumas TVs, porem sem som
	reg [7:0] tdms_s;	
		
	hdmi  
		#(
			.FREQ(21428000),	//-- pixel clock frequency 
			.FS(48000),			//-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
			.CTS(21428),		//-- CTS = Freq(pixclk) * N / (128 * Fs)
			.N(6144)				//-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
		) 
		dvi (
			.I_CLK_VGA		( clk ),
			.I_CLK_TMDS		( clock_dvi_s ),
			.I_RED			( { vga_osd_r[7:5] , vga_osd_r[7:5] , vga_osd_r[7:6] }),
			.I_GREEN			( { vga_osd_g[7:5] , vga_osd_g[7:5] , vga_osd_g[7:6] }),
			.I_BLUE			( { vga_osd_b[7:5] , vga_osd_b[7:5] , vga_osd_b[7:6] }),
			.I_BLANK			( vga_blank ),
			.I_HSYNC			( vga_hsync ),
			.I_VSYNC			( vga_vsync ),
			.I_AUDIO_PCM_L ( { 1'b0, sample[15:8] } ),
			.I_AUDIO_PCM_R	( { 1'b0, sample[15:8] } ),
			.O_TMDS			( tdms_s )
		);
		
		assign vga_hsync_n_o	= tdms_s[7];	//-- 2+		10
		assign vga_vsync_n_o	= tdms_s[6];	//-- 2-		11
		assign vga_b_o[2] = tdms_s[5];		//-- 1+		144	
		assign vga_b_o[1] = tdms_s[4];		//-- 1-		143
		assign vga_r_o[0] = tdms_s[3];		//-- 0+		133
		assign vga_g_o[2] = tdms_s[2];		//-- 0-		132
		assign vga_r_o[1] = tdms_s[1];		//-- CLK+	113
		assign vga_r_o[2] = tdms_s[0];		//-- CLK-	112
		
		
		
		
	*/		
		
		
		
		
		
		
		
  
  wire [14:0] pixel_in = pallut[color];
  
  Hq2x hq2x(clk, pixel_in, !hq_enable, 
            scanline[8],        // reset_frame
            (cycle[8:3] == 42), // reset_line
            doubler_x,          // 0-511 for line 1, or 512-1023 for line 2.
            doubler_sync,       // new frame has just started
            doubler_pixel);     // pixel is outputted

	assign dac_l_o = audio;
	assign dac_r_o = audio;
   wire audio;
	
	sigma_delta_dac sigma_delta_dac (
        .DACout         (audio),
        .DACin          (sample[15:8]),
        .CLK            (clk),
        .RESET          (reset_nes)
	);
	
	
wire [31:0] rom_size;

	CtrlModule control (
			.clk(clk_ctrl), 
			.reset_n(1'b1), 
			.vga_hsync(vga_hsync), 
			.vga_vsync(vga_vsync), 
			.osd_window(osd_window), 
			.osd_pixel(osd_pixel), 
			.ps2k_clk_in( ps2_clk_io ), 
			.ps2k_dat_in( ps2_data_io ),
			.spi_miso( sd_miso_i ), 
			.spi_mosi( sd_mosi_o ), 
			.spi_clk( sd_sclk_o ), 
			.spi_cs( sd_cs_n_o ), 
			.dipswitches(dipswitches), 
			.size(rom_size), 
			.joy_pins({~(btn_n_i[4] || btn_n_i[3]), ~joy1_up_i, ~joy1_down_i, ~joy1_left_i, ~joy1_right_i, ~joy1_p6_i}), 
			.host_divert_sdcard(host_divert_sdcard), 
			.host_divert_keyboard(host_divert_keyboard), 
			.host_reset_n(host_reset_n), 
			.host_select(host_select), 
			.host_start(host_start),
			.host_reset_loader(host_reset_loader),
			.host_bootdata(bootdata), 
			.host_bootdata_req(bootdata_req), 
			.host_bootdata_ack(bootdata_ack)
	);
	
	OSD_Overlay osd (
			.clk(clk_ctrl),
			.red_in({vga_red, 4'b0000}),
			.green_in({vga_green, 4'b0000}),
			.blue_in({vga_blue, 4'b0000}),
			.window_in(1'b1),
			.hsync_in(vga_hsync),
			.osd_window_in(osd_window),
			.osd_pixel_in(osd_pixel),
			.red_out(vga_osd_r),
			.green_out(vga_osd_g),
			.blue_out(vga_osd_b),
			.window_out(),
			.scanline_ena(scanlines)
	);
 
reg write_fifo;
reg read_fifo;
wire full_fifo;
reg skip_fifo = 1'b0;
wire [7:0] dout_fifo;
reg [31:0] bytesloaded;

reg [12:0] counter_fifo;
assign clk_fifo = counter_fifo[7]; 
assign clk_gameloader = counter_fifo[6]; 




fifo_loader loaderbuffer (
        .wrclk(clk_ctrl),
        .rdclk(clk_fifo), 
			.data({bootdata[7:0],bootdata[15:8],bootdata[23:16],bootdata[31:24]}),  //.data(bootdata), //acerto na ordem dos bytes
			.wrreq(write_fifo), 
			.rdreq(read_fifo), 
			.q(dout_fifo),
			.wrfull(full_fifo), 
			.rdempty(empty_fifo)
 );
 
always@( posedge clk_ctrl )
begin
	if (host_reset_loader == 1'b1) begin
		bootdata_ack <= 1'b0;
		boot_state <= 1'b0;
		write_fifo <= 1'b0;
		read_fifo <= 1'b0;
		skip_fifo <= 1'b0;
		bytesloaded <= 32'h00000000;
	end else begin
		if (dout_fifo == 8'h4E) skip_fifo <= 1'b1;

		case (boot_state)
		
			1'b0:
				if (bootdata_req == 1'b1) 
				begin
				
					if (full_fifo == 1'b0) 
					begin
						boot_state <= 1'b1;
						bootdata_ack <= 1'b1;
						write_fifo <= (bytesloaded < rom_size) ? 1'b1 : 1'b0;
					end 
					else read_fifo <= 1'b1;
					
				end else begin
					bootdata_ack <= 1'b0;
					end
					
			1'b1: 
 				begin
					if (write_fifo == 1'b1) begin
						write_fifo <= 1'b0;
						bytesloaded <= bytesloaded + 4;
					end
					boot_state <= 1'b0;
					bootdata_ack <= 1'b0;
				end
		endcase;
	end
end

always@( posedge clk )
begin

	counter_fifo <= counter_fifo + 1'b1;
	
	//clk_loader <= !clk_fifo && skip_fifo;
	clk_loader <= !clk_fifo && skip_fifo && read_fifo; //adicionado read_fifo pra sincronizar o clock
end

always@( posedge clk_loader)
begin
	loader_input <= dout_fifo;
//	data <= bytesloaded[19:4];
end
endmodule
