----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:30:37 03/09/2015 
-- Design Name: 
-- Module Name:    Address - Behavioral 
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

entity Address is
	 Generic (
		BUFFER_LOGSIZE : integer
	 );
    Port ( clk : in  STD_LOGIC;
           dout : out  STD_LOGIC_VECTOR (BUFFER_LOGSIZE downto 0));
end Address;

architecture Behavioral of Address is
signal reg:std_logic_vector(BUFFER_LOGSIZE downto 0):=(others=>'0');
begin
process(clk)
begin
if rising_edge(clk) then
 reg<=reg+1;
end if;
end process;
dout<=reg;

end Behavioral;

