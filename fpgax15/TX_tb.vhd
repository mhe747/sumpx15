--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:53:20 08/18/2017
-- Design Name:   
-- Module Name:   C:/Ahmed/xilinx_projects/UART_ARTIX7/TX_tb.vhd
-- Project Name:  UART_ARTIX7
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TX
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
USE ieee.numeric_std.ALL;
 
ENTITY TX_tb IS
END TX_tb;
 
ARCHITECTURE behavior OF TX_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TX
	 generic(baudrate:integer;freq:integer);
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         start : IN  std_logic;
         TX_data : IN  std_logic_vector(7 downto 0);
         tx_ready : OUT  std_logic;
         Serial_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal start : std_logic := '0';
   signal TX_data : std_logic_vector(7 downto 0) := (others => '0');
   signal data : std_logic_vector(7 downto 0) := (others => '0');
 	--Outputs
   signal tx_ready : std_logic;
   signal Serial_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TX 
	generic map(baudrate=>115200,freq=>50000000)
	PORT MAP (
          clk => clk,
          reset => reset,
          start => start,
          TX_data => TX_data,
          tx_ready => tx_ready,
          Serial_out => Serial_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		
      wait for 100 ns;	
		for i in 0 to 255 loop
			TX_data <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, 8));
			start <= '1';
			uart_get(Serial_out, data);
		END LOOP;
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
