-- Company:        Dept. Architecture and Computing Technology. University of Seville
-- Engineer:       Miguel Angel Rodriguez Jodar. rodriguj@atc.us.es
-- 
-- Create Date:    19:13:39 4-Apr-2012 
-- Design Name:    ZX Spectrum
-- Module Name:    audio mixer
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

library ieee;
use ieee.std_logic_1164.all;

entity mixer is
port (
	clkdac : in  std_logic;
	reset  : in  std_logic;
	ear    : in  std_logic;
	mic    : in  std_logic;
	spk    : in  std_logic;
	audio : out std_logic
);
end mixer;

architecture rtl of mixer is
	signal mix : std_logic_vector(7 downto 0) := (others=>'0');
begin

	process
		variable selector : std_logic_vector(2 downto 0);
	begin
		wait until rising_edge(clkdac);
		selector := (ear & spk & mic);
		case selector is
			when "000"  => mix <= x"11";
			when "001"  => mix <= x"24";
			when "010"  => mix <= x"B8";
			when "011"  => mix <= x"C0";
			when "100"  => mix <= x"16";
			when "101"  => mix <= x"30";
			when "110"  => mix <= x"F4";
			when others => mix <= x"FF";
		end case;
	end process;

	audio_dac : entity work.dac
	port map (
		clk_i => clkdac, 
		res_i => reset,
		dac_o => audio, 
		dac_i => mix
	);
end rtl;

