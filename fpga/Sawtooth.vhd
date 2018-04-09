----------------------------------------------------------------------------------
-- Sawtooth.vhd
--
-- Copyright (C) 2018 Mich He
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
-- Author: Mich He, <mhe747@gmail.com> in SUMPx15 Project.
-- Ported to SUMPx15 project FPGA Based Logic Analyzer With DAC output
-- 2018 SUMPx15 Project started.
--        : https://github.com/mhe747/sumpx15
--
-- The Sawtooth Wave ROM is an 8 bits Array of 16 samples.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Sawtooth is
    Port ( clk : in  STD_LOGIC;
           addr : in  STD_LOGIC_VECTOR (3 downto 0);
           Dout : out  STD_LOGIC_VECTOR (7 downto 0));
end Sawtooth;

architecture Behavioral of Sawtooth is
type rom is array (0 to 15) of std_logic_vector(7 downto 0);
constant memory:rom:=(
conv_std_logic_vector(15,8),
conv_std_logic_vector(31,8),
conv_std_logic_vector(47,8),
conv_std_logic_vector(63,8),
conv_std_logic_vector(79,8),
conv_std_logic_vector(95,8),
conv_std_logic_vector(111,8),
conv_std_logic_vector(127,8),
conv_std_logic_vector(143,8),
conv_std_logic_vector(159,8),
conv_std_logic_vector(175,8),
conv_std_logic_vector(191,8),
conv_std_logic_vector(207,8),
conv_std_logic_vector(223,8),
conv_std_logic_vector(239,8),
conv_std_logic_vector(255,8));
begin
process(clk)
begin
	if rising_edge(clk) then
		Dout<=memory(conv_integer(addr));
	end if;
end process;
end Behavioral;

