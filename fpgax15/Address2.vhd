----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:30:37 03/09/2015 
-- Design Name: 
-- Module Name:    Address2 - Behavioral 
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

entity Address2 is
	 Generic (
		BUFFER_LOGSIZE : integer
	 );
    Port ( 
		reset : in  STD_LOGIC;
			clk : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (BUFFER_LOGSIZE downto 0));
end Address2;

architecture Behavioral of Address2 is
signal reg:std_logic_vector(BUFFER_LOGSIZE downto 0):=(others=>'0');
begin
	process(clk)
	begin
	 if reset = '1' then
      reg <= (others=>'0');
    elsif rising_edge(clk) then	
		reg<=reg+1;
	end if;
	end process;
	-- add a reset management
dout<=reg;

end Behavioral;

