library ieee;
use ieee.std_logic_1164.all;

entity pipistrello_tb is
end pipistrello_tb;

architecture behavior of pipistrello_tb is 
	--Inputs
	signal CLKIN : std_logic := '0';
	signal I_RESET : std_logic := '0';
	signal I_EAR : std_logic := '0';
	signal PS2CLK1 : std_logic := '0';
	signal PS2DAT1 : std_logic := '0';

	--Outputs
	signal O_VIDEO_R : std_logic_vector(3 downto 0);
	signal O_VIDEO_G : std_logic_vector(3 downto 0);
	signal O_VIDEO_B : std_logic_vector(3 downto 0);
	signal O_HSYNC : std_logic;
	signal O_VSYNC : std_logic;
	signal O_AUDIO : std_logic;

	-- Clock period definitions
	constant CLKIN_period : time := 20 ns;

begin
 	-- Instantiate the Unit Under Test (UUT)
	uut: entity work.PIPISTRELLO_TOP
	port map (
		CLKIN     => CLKIN,
		I_RESET   => I_RESET,
		O_VIDEO_R => O_VIDEO_R,
		O_VIDEO_G => O_VIDEO_G,
		O_VIDEO_B => O_VIDEO_B,
		O_HSYNC   => O_HSYNC,
		O_VSYNC   => O_VSYNC,
		I_EAR     => I_EAR,
		O_AUDIO   => O_AUDIO,
		PS2CLK1   => PS2CLK1,
		PS2DAT1   => PS2DAT1
	);

	-- Clock process definitions
	CLKIN_process :process
	begin
		CLKIN <= '0';
		wait for CLKIN_period/2;
		CLKIN <= '1';
		wait for CLKIN_period/2;
	end process;

	-- Stimulus process
	stim_proc: process
	begin		
	-- hold reset state for 100 ns.
	I_RESET <= '1';
	wait for CLKIN_period*16;
	I_RESET <= '0';

	wait;
	end process;
end;
