--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:12:45 02/16/2016
-- Design Name:   
-- Module Name:   C:/Ahmed/xilinx_projects/UART_ARTIX7/RX_tb.vhd
-- Project Name:  UART_ARTIX7
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: RX
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.UART_RS232.all; 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY RX_tb IS
END RX_tb;
 
ARCHITECTURE behavior OF RX_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT RX
	 generic(baudrate:integer:=9600;freq:integer:=100000000);
    PORT(
         reset : IN  std_logic;
         clk : IN  std_logic;
         Serial_in : IN  std_logic;
         RX_done : OUT  std_logic;
         Data_out : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';
   signal Serial_in : std_logic := '0';

 	--Outputs
   signal RX_done : std_logic;
   signal Data_out : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
   signal I : integer;
BEGIN
 I <= max_count(115200, 50000000);
	-- Instantiate the Unit Under Test (UUT)
   uut: RX 
	generic map(baudrate=>115200,freq=>50000000)
	PORT MAP (
          reset => reset,
          clk => clk,
          Serial_in => Serial_in,
          RX_done => RX_done,
          Data_out => Data_out
        );
--TX_tester:entity work.TX 
--generic map(baudrate=>19200,freq=>100000000)
--port map( clk        => clk,
--          reset      => reset, 
--          start      => '1',
--          TX_data    => x"33",
--			 tx_ready   => open,
--          Serial_out => Serial_in);
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   tb : PROCESS
   BEGIN
	for i in 0 to 127 loop
      uart_send(x"AF", Serial_in);
		uart_send(x"55", Serial_in);
	end loop;
   wait; -- will wait forever
   END PROCESS;

END;
