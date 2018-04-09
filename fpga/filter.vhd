----------------------------------------------------------------------------------
-- filter.vhd
--
-- Copyright (C) 2006 Michael Poppitz
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or (at
-- your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
--
----------------------------------------------------------------------------------
--
-- Author: Michael "Mr. Sump" Poppitz in original SUMP
-- Author: Mich He, <mhe747@gmail.com> in SUMPx15 Project.
-- Ported to SUMPx15 project FPGA Based Logic Analyzer With DAC output
-- 2006 Initial revision.
-- 2018 SUMPx15 Project started.
--        : http://sump.org/projects/analyzer/
--        : https://github.com/mhe747/sumpx15
--
-- Fast 32 channel digital noise filter using a single LUT function for each
-- individual channel. It will filter out all pulses that only appear for half
-- a clock cycle. This way a pulse has to be at least 5-10ns long to be accepted
-- as valid. This is sufficient for sample rates up to 100MHz.
--
-- Noise cancelation is important when connecting to 5V signals with high
-- slew rate, because cross talk will occur.
-- It may or may not be necessary with low voltage signals.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity filter is
    Port ( input : in  STD_LOGIC_VECTOR (31 downto 0);
			  clock : in std_logic;
			  clock180 : in std_logic;
           output : out  STD_LOGIC_VECTOR (31 downto 0));
end filter;

architecture Behavioral of filter is

signal input0, input180, input360, nresult, result : STD_LOGIC_VECTOR (31 downto 0);

begin
	process(clock)
	begin
		if rising_edge(clock) then
			input360 <= input0;
			input0 <= input;
			result <= nresult;
		end if;
	end process;
	output <= result;

	process(clock180)
	begin
		if rising_edge(clock180) then
			input180 <= input;
		end if;
	end process;

	-- determine next result
	process(input0, input180, input360, result)
	begin
		for i in 15 downto 0 loop
			if 
				(result(i) = '0' and input360(i) = '0' and input180(i) = '0' and input0(i) = '0')
				or (result(i) = '0' and input360(i) = '0' and input180(i) = '0' and input0(i) = '1')
				or (result(i) = '0' and input360(i) = '0' and input180(i) = '1' and input0(i) = '0')
				or (result(i) = '0' and input360(i) = '1' and input180(i) = '0' and input0(i) = '0')
				or (result(i) = '0' and input360(i) = '1' and input180(i) = '0' and input0(i) = '1')
				or (result(i) = '1' and input360(i) = '0' and input180(i) = '0' and input0(i) = '0')
				or (result(i) = '1' and input360(i) = '0' and input180(i) = '0' and input0(i) = '1')
				or (result(i) = '1' and input360(i) = '1' and input180(i) = '0' and input0(i) = '0')
			then
				nresult(i) <= '0';
			else
				nresult(i) <= '1';
			end if;
		end loop;
	end process;

end Behavioral;
