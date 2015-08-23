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

entity PAPILIO_TOP is
port(
	CLKIN     : in  std_logic;
	I_RESET   : in  std_logic;
	-- Video
	O_VIDEO_R : out std_logic_vector( 3 downto 0);
	O_VIDEO_G : out std_logic_vector( 3 downto 0);
	O_VIDEO_B : out std_logic_vector( 3 downto 0);
	O_HSYNC   : out std_logic;
	O_VSYNC   : out std_logic;
	-- ULA I/O 
	I_EAR     : in  std_logic;
	O_AUDIO   : out std_logic;
	-- PS/2 keyboard
	PS2CLK1   : in  std_logic;
	PS2DAT1   : in  std_logic
);

end PAPILIO_TOP;

architecture RTL of PAPILIO_TOP is
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
	signal cnt            : std_logic_vector( 2 downto 0) := (others=>'0');

	signal clkfx          : std_logic := '0';
	signal clk28          : std_logic := '0';
	signal clk14          : std_logic := '0';
	signal clk7           : std_logic := '0';

	signal
		hs_int, vs_int, s_red_i, s_grn_i, s_blu_i, s_red, s_grn, s_blu, s_int
	: std_logic := '0';
	signal dummy          : std_logic_vector( 3 downto 0);

begin

	sram_cs        <= '1' when a(15)='1'             and mreq_n='0'                           else '0';	-- 8xxx-Fxxx 32K
	vram_cs        <= '1' when a(15 downto 14)= "01" and mreq_n='0'                           else '0';	-- 4xxx-7xxx 16K
	rom_cs         <= '1' when a(15 downto 14)= "00" and mreq_n='0'              and rd_n='0' else '0';	-- 0xxx-3xxx 16K

	port255_cs     <= '1' when a( 7 downto  0)=x"FF" and iorq_n='0' and m1_n='1' and rd_n='0' else '0';
	ula_cs         <= '1' when a(0)='0'              and iorq_n='0' and m1_n='1'              else '0';

	nRESET         <= not I_RESET;
	RESET          <=     I_RESET;

	vramcs_n  <= not vramcs;
	vramoe_n  <= not vramoe;
	vramwe_n  <= not vramwe;
	sram_cs_n <= not sram_cs;

	--
	-- Clock generation 32Mhz -> 28Mhz
	--
	dcm_28m : DCM_SP
	generic map (
		CLKFX_DIVIDE   => 16,
		CLKFX_MULTIPLY => 14,
		CLKIN_PERIOD   => 31.25
	)
	port map(
		CLKIN => CLKIN,
		CLKFX => clkfx
	);

	inst_buf : BUFG port map (I => clkfx, O => clk28);

	process
	begin
		wait until rising_edge(clk28);
		cnt <= cnt + 1;
	end process;

	clk14     <= cnt(0);
	clk7      <= cnt(1);

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
		O_VIDEO(11 downto  8)=> O_VIDEO_R,
		O_VIDEO( 7 downto  4)=> O_VIDEO_G,
		O_VIDEO( 3 downto  0)=> O_VIDEO_B,
		O_HSYNC					=> O_HSYNC,
		O_VSYNC					=> O_VSYNC,
		O_CMPBLK_N				=> open,
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
