----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:06:48 01/19/2018 
-- Design Name: 
-- Module Name:    RAM2 - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM2 is
	 Generic (
		BUFFER_LOGSIZE : integer;
		SAMPLE_LOGSIZE : integer
	 );
    Port ( wr_clk : in  STD_LOGIC;
	        rd_clk : in  STD_LOGIC;
           WR_Addr : in  STD_LOGIC_VECTOR (BUFFER_LOGSIZE downto 0);
           RD_Addr : in  STD_LOGIC_VECTOR (BUFFER_LOGSIZE downto 0);
           WR_Data : in  STD_LOGIC_VECTOR (SAMPLE_LOGSIZE downto 0);
           RD_Data : out  STD_LOGIC_VECTOR (SAMPLE_LOGSIZE downto 0);
           WE : in  STD_LOGIC);
end RAM2;

architecture Behavioral of RAM2 is
	type memory_type is array (0 to 2**(BUFFER_LOGSIZE+1)) of std_logic_vector(SAMPLE_LOGSIZE downto 0);
	signal memory : memory_type := (others=>(others=>'0'));
begin
WR_Proc: process(wr_clk)
begin
if rising_edge(wr_clk) then
	if(WE='1')then
		memory(to_integer(unsigned(WR_ADDR))) <= WR_Data;
	end if;
end if;
end process;
RD_Proc: process(rd_clk)
begin
if rising_edge(rd_clk) then
	RD_Data <= memory(to_integer(unsigned(RD_ADDR)));
end if;
end process;
end Behavioral;

