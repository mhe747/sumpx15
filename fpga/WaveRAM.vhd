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
-- This is only DAC memory to store custom WaveRAM to be sent to DAC.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity WaveRAM is
    Port ( wr_clk : in  STD_LOGIC;
	        rd_clk : in  STD_LOGIC;
           WR_Addr : in  STD_LOGIC_VECTOR (7 downto 0);
           RD_Addr : in  STD_LOGIC_VECTOR (7 downto 0);
           WR_Data : in  STD_LOGIC_VECTOR (13 downto 0);
           RD_Data : out  STD_LOGIC_VECTOR (13 downto 0);
			  Run_Time : in  STD_LOGIC_VECTOR (9 downto 0);
			  txBusy : in STD_LOGIC;
			  SE : in STD_LOGIC;
           WE : in  STD_LOGIC);
end WaveRAM;

architecture Behavioral of WaveRAM is
	type memory_type is array (0 to 256) of std_logic_vector(13 downto 0);
	signal memory : memory_type := (others=>(others=>'0'));
	signal run_counter : std_logic_vector(17 downto 0);
begin


WR_Proc: process(wr_clk, WE)
begin
if rising_edge(wr_clk) then
	if(WE='1') then
		memory(to_integer(unsigned(WR_ADDR))) <= WR_Data;
	end if;
end if;
end process;

RD_Proc: process(rd_clk, SE)
begin
if rising_edge(rd_clk) then
	if not(run_counter = "00000000000000000") then
		RD_Data <= memory(to_integer(unsigned(RD_ADDR)));
		run_counter <= run_counter - 1;
	elsif (SE = '1') then
		run_counter <= Run_Time (9 downto 0) & "00000000";
	else
		RD_Data <= (others => '0');
	end if;
end if;
end process;
end Behavioral;

