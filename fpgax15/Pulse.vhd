----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:39:04 03/09/2015 
-- Design Name: 
-- Module Name:    Sawtooth - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Pulse is
    Port ( clk : in  STD_LOGIC;
           addr : in  STD_LOGIC_VECTOR (3 downto 0);
           Dout : out  STD_LOGIC_VECTOR (7 downto 0));
end Pulse;

architecture Behavioral of Pulse is
type rom is array (0 to 15) of std_logic_vector(7 downto 0);
constant memory:rom:=(
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(0,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8),
conv_std_logic_vector(255,8));
begin
process(clk)
begin
	if rising_edge(clk) then
		Dout<=memory(conv_integer(addr));
	end if;
end process;
end Behavioral;

