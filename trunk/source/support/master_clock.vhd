--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.ALL;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.ALL;

library unisim;
	use unisim.vcomponents.all;

entity master_clock is
	generic (
		C_CLKFX_DIVIDE   : integer := 2;
		C_CLKFX_MULTIPLY : integer := 3;
		C_CLKIN_PERIOD   : real    := 31.25
	);
	port (
		I_CLK				: in	std_logic;
		O_CLK				: out	std_logic
	);
end master_clock;

architecture RTL of master_clock is
	signal clkfx_buf			: std_logic := '0';

	-- Output clock buffering
	signal clkfb				: std_logic := '0';
	signal clk0					: std_logic := '0';
	signal clkfx				: std_logic := '0';
begin

	O_CLK  <= clkfx_buf;
	clkout1_buf	: BUFG  port map (I => clkfx, O => clkfx_buf);

	dcm_sp_inst: DCM_SP
	generic map(
		CLKFX_DIVIDE				=> C_CLKFX_DIVIDE,
		CLKFX_MULTIPLY				=> C_CLKFX_MULTIPLY,
		CLKIN_PERIOD				=> C_CLKIN_PERIOD

	)
	port map (
		-- Input clock
		CLKIN			=> I_CLK,
		CLKFB			=> clkfb,
		-- Output clocks
		CLK0			=> clkfb,
		CLKFX			=> clkfx,
		-- Other control and status signals
		RST			=> '0'
	);

end RTL;
