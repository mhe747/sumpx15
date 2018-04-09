----------------------------------------------------------------------------------
-- SineWave.vhd
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
-- The Sinus Wave ROM is an 8 bits Array of 16 samples.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SineWave is
    Port ( clk : in  STD_LOGIC;
           addr : in  STD_LOGIC_VECTOR (3 downto 0);
           Dout : out  STD_LOGIC_VECTOR (7 downto 0));
end SineWave;

architecture Behavioral of SineWave is
type rom is array (0 to 15) of std_logic_vector(7 downto 0);
constant sine:rom:=(
conv_std_logic_vector(176,8),
conv_std_logic_vector(217,8),
conv_std_logic_vector(245,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(245,8),
conv_std_logic_vector(217,8),
conv_std_logic_vector(176,8),
conv_std_logic_vector(127,8),
conv_std_logic_vector(78,8),
conv_std_logic_vector(37,8),
conv_std_logic_vector(9,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(9,8),
conv_std_logic_vector(37,8),
conv_std_logic_vector(78,8),
conv_std_logic_vector(127,8));
begin
process(clk)
begin
	if rising_edge(clk) then
		Dout<=sine(conv_integer(addr));
	end if;
end process;
end Behavioral;

