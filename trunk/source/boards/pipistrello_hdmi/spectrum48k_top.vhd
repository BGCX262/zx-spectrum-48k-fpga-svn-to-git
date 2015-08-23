--
-- Company:        Dept. Architecture and Computing Technology. University of Seville
-- Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
-- 
-- Create Date:    19:13:39 4-Apr-2012 
-- Design Name:    ZX Spectrum
-- Module Name:    PIPISTRELLO_TOP
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 1.00 - File Created
-- Additional Comments: GPL License policies apply to the contents of this file.
--
--

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library unisim;
	use unisim.vcomponents.all;

entity PIPISTRELLO_TOP is
port(
	CLKIN     : in  std_logic;
	I_RESET   : in  std_logic;
	-- Video
	TMDS_P    : out std_logic_vector( 3 downto 0);
	TMDS_N    : out std_logic_vector( 3 downto 0);
	-- ULA I/O 
	I_EAR     : in  std_logic;
	O_AUDIO   : out std_logic;
	-- PS/2 keyboard
	PS2CLK1   : in  std_logic;
	PS2DAT1   : in  std_logic
);

end PIPISTRELLO_TOP;

architecture RTL of PIPISTRELLO_TOP is
	-- CPU signals
	signal a              : std_logic_vector(15 downto 0) := (others=>'0');
	signal cpudout        : std_logic_vector( 7 downto 0) := (others=>'0');
	signal cpudin         : std_logic_vector( 7 downto 0) := (others=>'0');
	signal clkcpu         : std_logic := '0';
	signal mreq_n         : std_logic := '0';
	signal iorq_n         : std_logic := '0';
	signal wr_n           : std_logic := '0';
	signal rd_n           : std_logic := '0';
	signal rfsh_n         : std_logic := '0';
	signal int_n          : std_logic := '0';
	signal m1_n           : std_logic := '0';
	signal nRESET         : std_logic := '1';
	signal RESET          : std_logic := '1';

	-- VRAM signals
	signal va             : std_logic_vector(13 downto 0) := (others=>'0');
	signal vramdin        : std_logic_vector( 7 downto 0) := (others=>'0');
	signal vramdout       : std_logic_vector( 7 downto 0) := (others=>'0');
	signal vramoe         : std_logic := '0';
	signal vramcs         : std_logic := '0';
	signal vramwe         : std_logic := '0';
	signal vramcs_n       : std_logic := '1';
	signal vramoe_n       : std_logic := '1';
	signal vramwe_n       : std_logic := '1';
	
	-- I/O
	signal mic            : std_logic := '0';
	signal spk            : std_logic := '0';
	signal kbd_columns    : std_logic_vector( 4 downto 0) := (others=>'0');

	-- data buses
	signal uladout        : std_logic_vector( 7 downto 0) := (others=>'0');
	signal sramdout       : std_logic_vector( 7 downto 0) := (others=>'0');
	signal romdout        : std_logic_vector( 7 downto 0) := (others=>'0');

	signal sram_cs        : std_logic := '0';
	signal sram_cs_n      : std_logic := '1';
	signal ula_cs         : std_logic := '0';
	signal vram_cs        : std_logic := '0';
	signal port255_cs     : std_logic := '0';
	signal rom_cs         : std_logic := '0';

	signal clkfx          : std_logic := '0';
	signal clk28          : std_logic := '0';
	signal clk14          : std_logic := '0';
	signal clk7           : std_logic := '0';

	signal
		hs_int, vs_int, s_red_i, s_grn_i, s_blu_i, s_red, s_grn, s_blu, s_int
	: std_logic := '0';
	signal dummy          : std_logic_vector( 3 downto 0);
	signal VideoR         : std_logic_vector( 3 downto 0) := (others=>'0');
	signal VideoG         : std_logic_vector( 3 downto 0) := (others=>'0');
	signal VideoB         : std_logic_vector( 3 downto 0) := (others=>'0');
	signal HSync          : std_logic := '0';
	signal VSync          : std_logic := '0';

   signal red_s				: std_logic := '0';
   signal grn_s				: std_logic := '0';
   signal blu_s				: std_logic := '0';

   signal clk_dvi_p			: std_logic := '0';
   signal clk_dvi_n			: std_logic := '0';
   signal clk_s				: std_logic := '0';
	signal CLKFB         	: std_logic := '0';
	signal clkout0         	: std_logic := '0';
	signal clkout1         	: std_logic := '0';
	signal clkout2         	: std_logic := '0';
	signal clkout3         	: std_logic := '0';
	signal clkout4         	: std_logic := '0';
	signal pll_locked			: std_logic := '0';
   signal s_blank				: std_logic := '0';

begin
	-----------------------------------------------
	-- generate all the system clocks required
	-----------------------------------------------
	inst_pll_base : PLL_BASE
	generic map (
		BANDWIDTH          => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED"
		COMPENSATION       => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRNOUS", "SOURCE_SYNCHRNOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		CLKIN_PERIOD       => 20.00, -- Clock period (ns) of input clock on CLKIN
		DIVCLK_DIVIDE      => 1,     -- Division factor for all clocks (1 to 52)
		CLKFBOUT_MULT      => 14,    -- Multiplication factor for all output clocks (1 to 64)
		CLKFBOUT_PHASE     => 0.0,   -- Phase shift (degrees) of all output clocks
		REF_JITTER         => 0.100, -- Input reference jitter (0.000 to 0.999 UI%)
		-- 140Mhz positive
		CLKOUT0_DIVIDE     => 5,     -- Division factor for CLKOUT2 (1 to 128)
		CLKOUT0_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT2 (0.01 to 0.99)
		CLKOUT0_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
		-- 140Mhz negative
		CLKOUT1_DIVIDE     => 5,     -- Division factor for CLKOUT3 (1 to 128)
		CLKOUT1_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT3 (0.01 to 0.99)
		CLKOUT1_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
		-- 28Mhz
		CLKOUT2_DIVIDE     => 25,    -- Division factor for CLKOUT1 (1 to 128)
		CLKOUT2_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT1 (0.01 to 0.99)
		CLKOUT2_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
		-- 14Mhz
		CLKOUT3_DIVIDE     => 50,    -- Division factor for CLKOUT0 (1 to 128)
		CLKOUT3_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT0 (0.01 to 0.99)
		CLKOUT3_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
		-- 7Mhz
		CLKOUT4_DIVIDE     => 100,   -- Division factor for CLKOUT4 (1 to 128)
		CLKOUT4_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT4 (0.01 to 0.99)
		CLKOUT4_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
		-- Not used
		CLKOUT5_DIVIDE     => 1,     -- Division factor for CLKOUT5 (1 to 128)
		CLKOUT5_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT5 (0.01 to 0.99)
		CLKOUT5_PHASE      => 0.0    -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
	)
	port map (
		CLKFBOUT => CLKFB,      -- General output feedback signal
		CLKOUT0  => clkout0,
		CLKOUT1  => clkout1,
		CLKOUT2  => clkout2,
		CLKOUT3  => clkout3,
		CLKOUT4  => clkout4,
		CLKOUT5  => open,
		LOCKED   => pll_locked, -- Active high PLL lock signal
		CLKFBIN  => CLKFB,      -- Clock feedback input
		CLKIN    => CLKIN,      -- Clock input
		RST      => I_RESET     -- Asynchronous PLL reset
	);

	-- Distribute some PLL clocks globally
	inst_buf0 : BUFG port map (I => clkout0, O => clk_dvi_p);
	inst_buf1 : BUFG port map (I => clkout1, O => clk_dvi_n);
	inst_buf2 : BUFG port map (I => clkout2, O => clk28);
	inst_buf3 : BUFG port map (I => clkout3, O => clk14);
	clk7 <= clkout4;

	sram_cs        <= '1' when a(15)='1'             and mreq_n='0'                           else '0';	-- 8xxx-Fxxx 32K
	vram_cs        <= '1' when a(15 downto 14)= "01" and mreq_n='0'                           else '0';	-- 4xxx-7xxx 16K
	rom_cs         <= '1' when a(15 downto 14)= "00" and mreq_n='0'              and rd_n='0' else '0';	-- 0xxx-3xxx 16K

	port255_cs     <= '1' when a( 7 downto  0)=x"FF" and iorq_n='0' and m1_n='1' and rd_n='0' else '0';
	ula_cs         <= '1' when a(0)='0'              and iorq_n='0' and m1_n='1'              else '0';

	nRESET         <=     pll_locked;
	RESET          <= not pll_locked;

	vramcs_n  <= not vramcs;
	vramoe_n  <= not vramoe;
	vramwe_n  <= not vramwe;
	sram_cs_n <= not sram_cs;

   --
   -- CPU data bus
   --
	cpudin  <=
		romdout  when rom_cs = '1' else
		uladout  when (ula_cs or vram_cs or port255_cs) = '1' else
		sramdout when sram_cs = '1' else x"FF";

	s_red_i <= s_red and s_int; 
	s_grn_i <= s_grn and s_int; 
	s_blu_i <= s_blu and s_int;

	OBUFDS_clk : OBUFDS port map ( O => TMDS_P(3), OB => TMDS_N(3), I => clk_s );
	OBUFDS_red : OBUFDS port map ( O => TMDS_P(2), OB => TMDS_N(2), I => red_s );
	OBUFDS_grn : OBUFDS port map ( O => TMDS_P(1), OB => TMDS_N(1), I => grn_s );
	OBUFDS_blu : OBUFDS port map ( O => TMDS_P(0), OB => TMDS_N(0), I => blu_s );

	inst_dvid: entity work.dvid
	port map(
      clk_p     => clk_dvi_p,
      clk_n     => clk_dvi_n, 
      clk_pixel => clk28,
      red_p(  7 downto 4) => VideoR,
      red_p(  3 downto 0) => x"0",
      green_p(7 downto 4) => VideoG,
      green_p(3 downto 0) => x"0",
      blue_p( 7 downto 4) => VideoB,
      blue_p( 3 downto 0) => x"0",
      blank     => not s_blank,
      hsync     => HSync,
      vsync     => VSync,
      -- outputs to TMDS drivers
      red_s     => red_s,
      green_s   => grn_s,
      blue_s    => blu_s,
      clock_s   => clk_s
   );

	-----------------------------------------------------------------
	-- video scan converter required to display video on VGA hardware
	-----------------------------------------------------------------
	-- active resolution 192x256
	-- take note: the values below are relative to the CLK period not standard VGA clock period
	inst_scan_conv : entity work.VGA_SCANCONV
	generic map (
		-- mark active area of input video
		cstart      =>  38,  -- composite sync start
		clength     => 352,  -- composite sync length

		-- output video timing
		hA				=>  24,	-- h front porch
		hB				=>  32,	-- h sync
		hC				=>  40,	-- h back porch
		hD				=> 352,	-- visible video

--		vA				=>   0,	-- v front porch (not used)
		vB				=>   2,	-- v sync
		vC				=>  10,	-- v back porch
		vD				=> 284,	-- visible video

		hpad			=>   0,	-- create H black border
		vpad			=>   0	-- create V black border
	)
	port map (
		I_VIDEO(15 downto 12)=> "0000",

		I_VIDEO(11) 			=> s_red_i,
		I_VIDEO(10) 			=> s_red,
		I_VIDEO(9) 				=> s_red,
		I_VIDEO(8) 				=> s_red,

		I_VIDEO(7) 				=> s_grn_i,
		I_VIDEO(6) 				=> s_grn,
		I_VIDEO(5) 				=> s_grn,
		I_VIDEO(4) 				=> s_grn,

		I_VIDEO(3) 				=> s_blu_i,
		I_VIDEO(2) 				=> s_blu,
		I_VIDEO(1) 				=> s_blu,
		I_VIDEO(0) 				=> s_blu,
		I_HSYNC					=> hs_int,
		I_VSYNC					=> vs_int,
		--
		O_VIDEO(15 downto 12)=> dummy,
		O_VIDEO(11 downto  8)=> VideoR,
		O_VIDEO( 7 downto  4)=> VideoG,
		O_VIDEO( 3 downto  0)=> VideoB,
		O_HSYNC					=> HSync,
		O_VSYNC					=> VSync,
		O_CMPBLK_N				=> s_blank,
		--
		CLK						=> clk7,
		CLK_x2					=> clk14
	);

   --
   -- ROM
   --
	inst_rom : entity work.rom_cpu
	port map (
		clk  => clk28,
		ena  => rom_cs,
		addr => a(13 downto 0),
		data => romdout
	);

--   --
--   -- VRAM bank
--   --
--	vram : entity work.ram16k
--	port map (
--		clk  => clk28,
--		cs   => vramcs,
--		oe   => vramoe,
--		we   => vramwe,
--		addr => va(13 downto 0),
--		di   => vramdin,
--		do   => vramdout
--	);
--
--   --
--   -- Upper RAM bank
--   --
--	uram : entity work.ram32k
--	port map (
--		clk  => clk28,
--		cs   => sram_cs,
--		oe   => RD,
--		we   => WR,
--		addr => a(14 downto 0),
--		di   => cpudout,
--		do   => sramdout
--	);

   inst_ram_controller : entity work.ram_controller
	port map (
		clk              => clk28,
		-- Bank 1 (VRAM)
		a1(15 downto 14) => "00",
		a1(13 downto 0)  => va,
		cs1_n            => vramcs_n,
		oe1_n            => vramoe_n,
		we1_n            => vramwe_n,
		din1             => vramdin,
		dout1            => vramdout,
		-- Bank 2 (upper RAM)
		a2(15)           => '0',
		a2(14 downto 0)  => a(14 downto 0),
		cs2_n            => sram_cs_n,
		oe2_n            => rd_n,
		we2_n            => wr_n,
		din2             => cpudout,
		dout2            => sramdout
	);

	--
	-- The ULA
	--
	inst_ula : entity work.ula
	port map (
		clk14           => clk14, 
		a               => a, 
		din             => cpudout, 
		dout            => uladout, 
		mreq_n          => mreq_n, 
		iorq_n          => iorq_n, 
		rd_n            => rd_n, 
		wr_n            => wr_n, 
		rfsh_n          => rfsh_n,
		clkcpu          => clkcpu, 
		msk_int_n       => int_n, 
		va              => va, 
		vramdout        => vramdout, 
		vramdin         => vramdin, 
		vramoe          => vramoe, 
		vramcs          => vramcs, 
		vramwe          => vramwe, 
		ear             => I_EAR, 
		mic             => mic, 
		spk             => spk, 
		kbrows          => open, 
		kbcolumns       => kbd_columns, 
		r               => s_red, 
		g               => s_grn, 
		b               => s_blu, 
		i               => s_int,
		csync           => open,
		hs              => hs_int,
		vs              => vs_int
	);

   --
   -- The CPU Z80A
   --
   inst_cpu : entity work.T80sed
	port map (
		-- Outputs
		M1_n      => m1_n,
		MREQ_n    => mreq_n,
		IORQ_n    => iorq_n,
		RD_n      => rd_n,
		WR_n      => wr_n,
		RFSH_n    => rfsh_n,
		HALT_n    => open,
		BUSAK_n   => open,
		A         => a,
		DO        => cpudout,
		-- Inputs
		RESET_n   => nRESET,
		CLK_n     => clkcpu,
		CLKEN     => '1',
		WAIT_n    => '1',
		INT_n     => int_n,
		NMI_n     => '1',
		BUSRQ_n   => '1',
		DI        => cpudin
   );

   --
   -- Audio mixer
   --
	inst_audio_mix : entity work.mixer
	port map (
		clkdac => clk14,
		reset  => RESET,
		ear    => I_EAR,
		mic    => mic,
		spk    => spk,
		audio  => O_AUDIO
	);

	--
   -- PS2 Keyboard
   --
	inst_keyboard : entity work.keyboard
	port map (
		CLK      => clk14,
		nRESET   => nRESET,
		PS2_CLK  => PS2CLK1,
		PS2_DATA => PS2DAT1,
		A        => a,
		KEYB     => kbd_columns
    );

end RTL;
