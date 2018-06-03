----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:20:43 03/09/2015 
-- Design Name: 
-- Module Name:    clock_divider - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock_divider is
    Port ( clk_in : in  STD_LOGIC;
           freq_div : in  STD_LOGIC_VECTOR (19 downto 0);
           clk_out : out  STD_LOGIC);
end clock_divider;

architecture Behavioral of clock_divider is
signal counter:std_logic_vector(19 downto 0):=(others=>'0');
signal reg:std_logic:='0';
begin
	process(clk_in)
	begin
		if rising_edge(clk_in) then
			if freq_div=counter then
				reg<= not(reg);
				counter<=(others=>'0');
			else
				counter<=counter+1;
			end if;
		end if;
	end process;
clk_out<=reg;
end Behavioral;

