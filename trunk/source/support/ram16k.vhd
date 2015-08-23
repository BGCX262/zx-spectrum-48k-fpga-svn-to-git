library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity ram16k is
port (
	clk  : in  std_logic;
	cs   : in  std_logic;
	oe   : in  std_logic;
	we   : in  std_logic;
	addr : in  std_logic_vector(13 downto 0);
	di   : in  std_logic_vector( 7 downto 0);
	do   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of ram16k is
	signal ro : std_logic_vector(7 downto 0);
begin

	do <= ro when oe = '1' and cs='1' else (others=>'0');

	RAM_CPU_0 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(0 downto 0),
		DO   => ro(0 downto 0),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_1 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(1 downto 1),
		DO   => ro(1 downto 1),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_2 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(2 downto 2),
		DO   => ro(2 downto 2),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_3 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(3 downto 3),
		DO   => ro(3 downto 3),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_4 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(4 downto 4),
		DO   => ro(4 downto 4),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_5 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(5 downto 5),
		DO   => ro(5 downto 5),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_6 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(6 downto 6),
		DO   => ro(6 downto 6),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

	RAM_CPU_7 : RAMB16_S1
	port map (
		CLK  => clk,
		DI   => di(7 downto 7),
		DO   => ro(7 downto 7),
		ADDR => addr,
		EN   => cs,
		SSR  => '0',
		WE   => we
	);

end RTL;
