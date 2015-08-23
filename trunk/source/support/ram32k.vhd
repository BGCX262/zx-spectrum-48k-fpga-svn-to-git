library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity ram32k is
port (
	clk  : in  std_logic;
	cs   : in  std_logic;
	oe   : in  std_logic;
	we   : in  std_logic;
	addr : in  std_logic_vector(14 downto 0);
	di   : in  std_logic_vector( 7 downto 0);
	do   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of ram32k is
	signal ro_l    : std_logic_vector(7 downto 0);
	signal ro_h    : std_logic_vector(7 downto 0);
	signal csl, csh : std_logic := '0';
begin

	csl <= '1' when cs='1' and addr(14)='0' else '0';
	csh <= '1' when cs='1' and addr(14)='1' else '0';

	do <=
		ro_l when oe='1' and csl='1' else
		ro_h when oe='1' and csh='1' else
		(others=>'0');

	raml : entity work.ram16k
	port map (
		clk  => clk,
		cs   => csl,
		oe   => oe,
		we   => we,
		addr => addr(13 downto 0),
		di   => di,
		do   => ro_l
	);

	ramh : entity work.ram16k
	port map (
		clk  => clk,
		cs   => csh,
		oe   => oe,
		we   => we,
		addr => addr(13 downto 0),
		di   => di,
		do   => ro_h
	);

end RTL;
