----------------------------------------------------------------------------------
-- clockman.vhd
--
-- Author: Michael "Mr. Sump" Poppitz in original SUMP
-- Author: Mich He, <mhe747@gmail.com> in SUMPx15 Project.
-- Ported to SUMPx15 project FPGA Based Logic Analyzer With DAC output
-- 2006 Initial revision.
-- 2018 SUMPx15 Project started.
--        : http://sump.org/projects/analyzer/
--        : https://github.com/mhe747/sumpx15
--
-- This is only a wrapper for Xilinx' DCM component so it doesn't
-- have to go in the main code and can be replaced more easily.
--
-- Creates clk0 and clk180 with 100MHz and
-- the latter having 180 degree phase shift.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity clockman is
    Port ( clkin : in  std_logic;		-- clock input 50Mhz
			  clkin_90 : out  std_logic;	-- clock input + 90 deg
			  clk0 : out std_logic;			-- * 4 clock rate output
			  clk180 : out std_logic;		-- * 4 clock rate output w/ 180 shift
			  clkdv0 : out std_logic
	 );
end clockman;

architecture Behavioral of clockman is

signal clkfb, clkfbbuf, realclk0, realclk180 : std_logic;

begin
   -- DCM: Digital Clock Manager Circuit for Virtex-II/II-Pro and Spartan-3/3E
   -- Xilinx HDL Language Template version 8.1i

   DCM_baseClock : DCM
   generic map (
      CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                           --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
      CLKFX_DIVIDE => 1,   --  Can be any interger from 1 to 32
      CLKFX_MULTIPLY => 4, --  Can be any integer from 1 to 32
      CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
      CLKIN_PERIOD => 20.0,          --  Specify period of input clock
      CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
      CLK_FEEDBACK => "1X",         --  Specify clock feedback of NONE, 1X or 2X
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                             --     an integer from 0 to 15
      DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
      DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
      DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
      FACTORY_JF => X"C080",          --  FACTORY JF Values
      PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
      STARTUP_WAIT => TRUE) --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
   port map (
      CLKIN => clkin,   -- Clock input (from IBUFG, BUFG or DCM)
      PSCLK => '0',   -- Dynamic phase adjust clock input
      PSEN => '0',     -- Dynamic phase adjust enable input
      PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
      RST => '0',       -- DCM asynchronous reset input
--		CLK2X => realclk0,
--		CLK2X180 => realclk180,
		CLK0 => clkfb,
		CLK90 => clkin_90,
		CLKFB => clkfbbuf,
		CLKFX => realclk0,
		CLKFX180 => realclk180,
		CLKDV => clkdv0
   );

	-- clkfb is run through a BUFG only to shut up ISE 8.1
	BUFG_clkfb : BUFG
   port map (
      O => clkfbbuf,     -- Clock buffer output
      I => clkfb         -- Clock buffer input
   );

	clk0 <= realclk0;
	clk180 <= realclk180;

end Behavioral;

