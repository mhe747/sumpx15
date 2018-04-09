----------------------------------------------------------------------------------
-- dac_controller.vhd
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
-- Saves dac_input to external SRAM continuously in normal operation.
-- When the dac_run signal is received, it relay data to each WaveRAM
-- This allows to receive data from UART or another external link
--
-- TODO: The memory address increment / dac_clock divider block is pretty
-- slow right now. Needs improvement to get to 125 MHz.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dac_controller is
    Port ( dac_clock : in  STD_LOGIC;
	        dac_reset : in  STD_LOGIC;
			  dac_rewind : in  STD_LOGIC;
			  dac_input : in  STD_LOGIC_VECTOR (15 downto 0);
           dac_addr : in  STD_LOGIC_VECTOR (3 downto 0);
			  dac_data : out  STD_LOGIC_VECTOR (15 downto 0);
			  dac_run : in std_logic
	 );
end dac_controller;

architecture Behavioral of dac_controller is

type CONTROLLER_STATES is (SAMPLE, READ, READWAIT);

signal nAddress, address, ncounter, counter: std_logic_vector (3 downto 0);
signal nstate, state : CONTROLLER_STATES;
signal up, inc, ninc : std_logic;

begin
	-- synchronization and dac_reset logic
	process(dac_run, dac_clock, dac_reset)
	begin
		if dac_reset = '1' then
			state <= SAMPLE;
			address <= (others => '0');
			dac_data <= (others => '0');
		elsif rising_edge(dac_clock) then
			state <= nstate;
			counter <= ncounter;
			address <= nAddress;
			inc <= ninc;
			dac_data(15 downto 0) <= dac_input(15 downto 0);
		end if;
	end process;

	-- memory address counter
	process(up, address)
	begin
		if up = '1' then
			ninc <= '1';
		end if;
	end process;

	process(inc, up, address)
	begin
		if inc = '1' then
			nAddress <= address + 1;
		elsif up = '0' then
			nAddress <= (others => '0');
		else
			nAddress <= address;
		end if;
	end process;

	-- FSM to control the dac_controller action
	process(state, dac_run, counter)
	begin
		case state is

			-- default mode: sample data from uart to memory, reset address
			when SAMPLE =>
				if dac_run = '1' then
					nstate <= READ;
				else
					nstate <= READWAIT;
				end if;
				ncounter <= (others => '0');
				up <= '1';

			-- after each sample
			when READ =>
				 nstate <= state;
				 up <= '1';

			-- wait for the uart receiver to become ready again
			when READWAIT =>
				if dac_run = '1' then
					nstate <= READ;
				else
					nstate <= state;
				end if;
				ncounter <= counter;
				up <= '0';


		end case;
	end process;

end Behavioral;
