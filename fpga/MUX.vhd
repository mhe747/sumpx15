----------------------------------------------------------------------------------
-- MUX.vhd
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
-- Mux is selector of 4 different Wave ROM Channel, should be extended to use more channels.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX is
    Port ( in0 : in  STD_LOGIC_VECTOR (7 downto 0);
           in1 : in  STD_LOGIC_VECTOR (7 downto 0);
           in2 : in  STD_LOGIC_VECTOR (7 downto 0);
           in3 : in  STD_LOGIC_VECTOR (7 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
           dout : out  STD_LOGIC_VECTOR (7 downto 0));
end MUX;

architecture Behavioral of MUX is

begin

dout<=
in0 when sel="11" else
in1 when sel="10" else
in2 when sel="01" else
in3;
end Behavioral;

