------------------------------------------------------------------------------
--
-- ADCSPI.VHD
-- Analog-to-Digital Converter Serial Programming Interface
--
-- This VHDL file contains synthesizable logic for programming the Texas
-- Instruments ADS5520 analog-to-digital converter through its three wire
-- serial programming interface.
--
-- Inputs:	reset	Active high asynchronous reset signal
--			clk		Core clock. Must be less than 40 MHz.
-- Outputs:	sclk	Serial clock. Rate is clk / 2. Duty cycle is 50%.
--			sen		Serial enable.
--			sdata	Serial data.
--
-- Author: Chris Hiszpanski, <chiszp@hotmail.com> in Sorad Project.
-- Author: Mich He, <mhe747@gmail.com> in SUMPx15 Project.
-- Ported to SUMPx15 project FPGA Based Logic Analyzer With DAC output
-- Apr 28 2007	Sorad Project.
-- Apr 09 2018 SUMPx15 Project started.
--        : https://github.com/thinkski/sorad
--        : https://github.com/mhe747/sumpx15
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adcapi is
	port (
		reset	: in	std_logic;
		clk		: in	std_logic;
		sclk	: out	std_logic;
		sen		: out	std_logic;
		sdata	: out	std_logic
	);
end adcapi;

architecture behavioral of adcapi is

	constant ROMSIZE : integer := 9;
	-- ROM contains values to output to ADC in order. Most significant
	-- nibble is register address. Remaining three nibbles are reg data.
	subtype rom_word is std_logic_vector(15 downto 0);
	type rom_table is array (0 to ROMSIZE-1) of rom_word;
	constant ROM : rom_table := rom_table'(
		rom_word'("1001000000000000"),
		rom_word'("1010000000000000"),
		rom_word'("1011000000000000"),
		rom_word'("1100000000000000"),
		rom_word'("1101000000000010"),	-- Internal DLL is OFF
		rom_word'("1110000000000000"),	-- Not in test mode
		rom_word'("0000000000000000"),
		rom_word'("0001000000000000"),
		rom_word'("1111000000000000")	-- Not in power down
	);

	-- States
	type state_type is (s_reset, s_setup, s_load, s_shift, s_clk, s_done);
	signal state	: state_type;

	-- ROM address
	signal addr		: integer;

	-- Counter for bit and ROM word selection
	signal shftcnt	: integer;
	
	-- Register for configuration vector
	signal data		: std_logic_vector(15 downto 0);

begin

	process (clk, reset)
	begin
		-- Asynchronous reset
		if (reset = '1') then
			-- State machine reset
			state <= s_reset;
			
			-- ROM address reset
			addr <= 0;
			
			-- Configuration vector register reset
			data <= (others => '0');
			
			-- Shift counter reset
			shftcnt <= 0;
			
			-- Serial clock high
			sclk <= '1';
			
			-- Serial enabled deasserted
			sen	<= '1';

		-- Rising clock edge
		elsif (clk = '1' and clk'event) then
			case state is
				-- Reset state machine
				when s_reset =>
					-- ROM address reset
					addr <= 0;
					
					-- Shift counter reset
					shftcnt <= 0;
					
					-- Serial clock high
					sclk <= '1';
					
					-- Serial enable deasserted
					sen <= '1';
					
					-- State machine reset
					state <= s_setup;					

				-- Assert serial enable (SEN) to meet setup time
				when s_setup =>
					-- Clock clock high
					sclk <= '1';
					
					-- Assert serial enable
					sen	<= '0';
					
					-- Next state: Load configuration vector
					state <= s_load;
					
				-- Load configuration vector from ROM
				when s_load =>
					-- Load next vector
					data <= ROM(addr);
					
					-- Increment address to next vector
					addr <= addr + 1;
					
					-- Reset the count of number of bits shifted out
					shftcnt <= 0;
					
					-- Serial clock high or rising edge
					sclk <= '1';
					
					-- Serial enable remains asserted
					sen <= '0';
					
					-- Next state: Serial clock falling edge (latches sdata)
					state <= s_clk;
					
				-- Shift out next configuration bit
				when s_shift =>
					-- Shift configuration vector left
					data <= data(data'high-1 downto 0) & '0';
					
					-- Increment shift count
					shftcnt <= shftcnt + 1;
				
					-- Serial clock rising edge
					sclk <= '1';
					
					-- Serial enable remains asserted
					sen	<= '0';
					
					-- Next state: serial clock falling edge (latches sdata)
					state <= s_clk;

				-- Serial clock falling edge latches data into ADC
				when s_clk   =>
					-- Serial clock falling edge
					sclk <= '0';
					
					-- Serial enable remains asserted
					sen	<= '0';
					
					-- Next state
					if (shftcnt >= data'high) then
						if (addr > ROM'high) then
							-- Done if all ROM entiries transmitted
							state <= s_done;
						else
							-- Load next configuration vector
							state <= s_load;
						end if;
					else
						-- Serial clock falling edge (latches sdata)
						state <= s_shift;
					end if;

				-- Final state
				when s_done  =>
					-- Serial clock set high
					sclk <= '1';
					
					-- Serial enable deasserted
					sen	<= '1';
					
					-- Remain in final state
					state	<= s_done;
			end case;
		end if;
	end process;

	-- Drive seria data with MSB of remaining configuration vector
	sdata <= data(data'high);

end behavioral;
