----------------------------------------------------------------------------------
-- la.vhd
--
-- Copyright (C) 2006 Michael Poppitz
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
-- Author: Michael "Mr. Sump" Poppitz in original SUMP
-- Author: Mich He, <mhe747@gmail.com> in SUMPx15 Project.
-- Ported to SUMPx15 project FPGA Based Logic Analyzer With DAC output
-- 2006 Initial revision.
-- 2018 SUMPx15 Project started.
--        : http://sump.org/projects/analyzer/
--        : https://github.com/mhe747/sumpx15
--
-- Top level module. It connects all the other modules
-- and defines all inputs and outputs that represent phyisical pins of
-- the fpga.
--
-- It defines two constants FREQ and RATE. The first is the clock frequency 
-- used for receiver and transmitter for generating the proper baud rate.
-- The second defines the speed at which to operate the serial port.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library unisim;
use unisim.vcomponents.all;

entity la is
	Port(
		clockIn : in std_logic;   -- input frequency 50 Mhz
		osc125_clk : in std_logic;   -- input frequency 125 Mhz
	   resetSwitch : in std_logic;		
		input : in std_logic_vector(31 downto 0);
		rx : in std_logic;
		tx : inout std_logic;
		led : OUT std_logic_vector(1 downto 0);
		wave : out   std_logic_vector (13 downto 0);
		DAC_CLK : out std_logic; 
		DAC_SLEEP : out std_logic;
		ADC_SEN : out std_logic;
		ADC_CLKP : out std_logic;
		ADC_RESET : out std_logic;
		ADC_SDATA : out std_logic;
		ADC_SCLK : out std_logic
	);
end la;

architecture Behavioral of la is
---- ADC 552x
	signal rst : std_logic_vector (3 downto 0);
	signal adc_clk : std_logic;
	
	component adcapi is
	port (
		reset	: in	std_logic;
		clk		: in	std_logic;
		sclk	: out	std_logic;
		sen		: out	std_logic;
		sdata	: out	std_logic
	);
   end component;
	
---- Wave Generator
   signal clk_div : std_logic;
	signal clk_dac : std_logic;
   signal wave1   : std_logic_vector (7 downto 0);
   signal wave2   : std_logic_vector (7 downto 0);
   signal wave3   : std_logic_vector (7 downto 0);
   signal wave4   : std_logic_vector (7 downto 0);
   signal Addr  : std_logic_vector (3 downto 0);

	signal RD_Addr    : std_logic_vector (7 downto 0);
	signal RD_data    : std_logic_vector (13 downto 0);	
	signal WR_Addr    : std_logic_vector (7 downto 0);
	signal WR_Data    : std_logic_vector (13 downto 0); 	
	signal WE         : std_logic;


   component Address
      port ( clk  : in    std_logic; 
             dout : out   std_logic_vector (3 downto 0));
   end component;
   
   component SineWave
      port ( clk  : in    std_logic; 
             addr : in    std_logic_vector (3 downto 0); 
             Dout : out   std_logic_vector (7 downto 0));
   end component;
   
   component Triangle
      port ( clk  : in    std_logic; 
             addr : in    std_logic_vector (3 downto 0); 
             Dout : out   std_logic_vector (7 downto 0));
   end component;
   
   component Sawtooth
      port ( clk  : in    std_logic; 
             addr : in    std_logic_vector (3 downto 0); 
             Dout : out   std_logic_vector (7 downto 0));
   end component;
   
   component Pulse
      port ( clk  : in    std_logic; 
             addr : in    std_logic_vector (3 downto 0); 
             Dout : out   std_logic_vector (7 downto 0));
   end component;
   
   component MUX
      port ( in0  : in    std_logic_vector (7 downto 0); 
             in1  : in    std_logic_vector (7 downto 0); 
             in2  : in    std_logic_vector (7 downto 0); 
             in3  : in    std_logic_vector (7 downto 0); 
             sel  : in    std_logic_vector (1 downto 0); 
             dout : out   std_logic_vector (7 downto 0));
   end component;
	
	COMPONENT WaveRAM
	PORT(
		wr_clk : IN std_logic;
		rd_clk : IN std_logic;
		WR_Addr : IN std_logic_vector(7 downto 0);
		WR_Data : IN std_logic_vector(13 downto 0);
		RD_Addr : IN std_logic_vector(7 downto 0);
		RD_Data : OUT std_logic_vector(13 downto 0); -- output to wave
		Run_Time : IN std_logic_vector(9 downto 0); -- number of time the the wave will be sent to DAC (maximum 1024 times)
		txBusy : IN std_logic; -- when UART is ready
		SE : IN std_logic; -- select this WaveRAM
		WE : IN std_logic);
	END COMPONENT;

---- SUMP

	COMPONENT clockman
	PORT(
		clkin : IN std_logic;
      clkin_90 : OUT std_logic;
		clk0 : OUT std_logic;
		clk180 : OUT std_logic;
		clkdv0 : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT receiver
	generic (
		FREQ : integer;
		RATE : integer
	);
	PORT(
		rx : IN std_logic;
		clock : IN std_logic;    
	   reset : in STD_LOGIC;
		cmd : INOUT std_logic_vector(39 downto 0)
	   );
	END COMPONENT;

	COMPONENT decoder
	PORT ( opcode : in  STD_LOGIC_VECTOR (7 downto 0);
			  clock : in std_logic;
           wrtrigmask : out  STD_LOGIC;
           wrtrigval : out  STD_LOGIC;
			  wrspeed : out STD_LOGIC;
			  wrsize : out std_logic;
			  wrFlags : out std_logic;
				dac_select : out STD_LOGIC_VECTOR (2 downto 0);
				dac_enable : out STD_LOGIC;
				dac_rewind : out STD_LOGIC;			
			  arm : out std_logic;
			  reset : out std_logic
		);
	END COMPONENT;

	COMPONENT flags
	PORT(
		data : IN std_logic_vector(1 downto 0);
		clock : IN std_logic;
		write : IN std_logic;          
		demux : OUT std_logic;
	   filter : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT demux
	PORT(
		input : IN std_logic_vector(15 downto 0);
		clock : IN std_logic;
		clock180 : IN std_logic;
		output : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT filter
	PORT(
		input : IN std_logic_vector(31 downto 0);
		clock : IN std_logic;
		clock180 : IN std_logic;
		output : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT trigger
	PORT(
		input : IN std_logic_vector(31 downto 0);
		data : IN std_logic_vector(31 downto 0);
	   clock : in std_logic;
		reset : in std_logic;
		wrMask : IN std_logic;
		wrValue : IN std_logic;
		arm : IN std_logic;          
		run : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT controller
	PORT(
		clock : IN std_logic;
		reset : in std_logic;
		input : IN std_logic_vector(31 downto 0);    
		data : in std_logic_vector(31 downto 0);
		wrSpeed : in std_logic;
		wrSize : in std_logic;
		run : in std_logic;
		txBusy : in std_logic;
		send : inout std_logic;
		output : out std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT transmitter
	generic (
		FREQ : integer;
		RATE : integer
	);
	PORT(
		data : IN std_logic_vector(31 downto 0);
		write : IN std_logic;
		clock : IN std_logic;
		tx : OUT std_logic;
		busy : out std_logic
		);
	END COMPONENT;


signal command : std_logic_vector (39 downto 0);
--signal displayData : std_logic_vector (31 downto 0);
signal output : std_logic_vector (31 downto 0);
signal filteredInput, demuxedInput, synchronizedInput, selectedInput : std_logic_vector (31 downto 0);
signal wrtrigmask, wrtrigval, wrspeed, wrsize, run, arm, txBusy, send : std_logic;
signal clock, clock180, reset, resetCmd, flagDemux, flagFilter, wrFlags: std_logic;
signal clkin_90 : std_logic;
---- Wave Generator
signal dac_select : std_logic_vector (2 downto 0);
signal dac_addr : std_logic_vector (3 downto 0);
signal dac_data : std_logic_vector (15 downto 0);
signal dac_clock, dac_reset, dac_enable, dac_run, dac_rewind : std_logic;
signal WaveRAM_addr : std_logic_vector (7 downto 0);
signal WaveRAM_data : std_logic_vector (13 downto 0);

constant FREQ : integer := 200000000;
constant RATE : integer := 115200; --921600;

begin
------------------------------------------------------------------------
-- This part is for data sampling by FPGA sampling from real world / ADC
------------------------------------------------------------------------
	-- switches and leds are kept in design to be available for debugging
	led(1 downto 0) <= resetSwitch & txBusy;
	--	displayData <= output;

	-- reset is triggered either by switch or reset command
	reset <= (not resetSwitch) or resetCmd;

	-- synch input guarantees use of iob ff on spartan 3 (as filter and demux do)
	process (clock)
	begin
		if rising_edge(clock) then
			synchronizedInput <= input;
		end if;
	end process;

	-- add another pipeline step for input selector to not decrease maximum clock
	process (clock) 
	begin
		if rising_edge(clock) then
			if flagDemux = '1' then
				selectedInput <= demuxedInput;
			else
				if flagFilter = '1' then
					selectedInput <= filteredInput;
				else
					selectedInput <= synchronizedInput;
				end if;
			end if;
		end if;
	end process;
	
	Inst_clockman: clockman PORT MAP(
		clkin => clockIn,
		clkin_90 => clkin_90,
		clk0 => clock,
		clk180 => clock180,
		clkdv0 => clk_div
	);
	
	Inst_receiver: receiver
	generic map (
		FREQ => FREQ,
		RATE => RATE
	)
	PORT MAP(
		rx => rx,
		clock => clock,
		reset => reset,
		cmd => command
	);

	Inst_decoder: decoder PORT MAP(
		opcode => command(7 downto 0),
		clock => clock,
		wrtrigmask => wrtrigmask,
		wrtrigval => wrtrigval,
		wrspeed => wrspeed,
		wrsize => wrsize,
		wrFlags => wrFlags,
		dac_select => dac_select,
		dac_enable => dac_enable,
		dac_rewind => dac_rewind,
		arm => arm,
		reset => resetCmd
	);

	Inst_flags: flags PORT MAP(
		data => command(9 downto 8),
		clock => clock,
		write => wrFlags,
		demux => flagDemux,
		filter => flagFilter
	);
	
	Inst_demux: demux PORT MAP(
		input => input(15 downto 0),
		clock => clock,
		clock180 => clock180,
		output => demuxedInput
	);

	Inst_filter: filter PORT MAP(
		input => input,
		clock => clock,
		clock180 => clock180,
		output => filteredInput
	);
	
	Inst_trigger: trigger PORT MAP(
		input => selectedInput,
		data => command(39 downto 8),
		clock => clock,
		reset => reset,
		wrMask => wrtrigmask,
		wrValue => wrtrigval,
		arm => arm,
		run => run
	);

	Inst_controller: controller PORT MAP(
		clock => clock,
		reset => reset,
		input => selectedInput,
		data => command(39 downto 8),
		wrSpeed => wrspeed,
		wrSize => wrsize,
		run => run,
		txBusy => txBusy,
		send => send,
		output => output
	);
	
	Inst_transmitter: transmitter
	generic map (
		FREQ => FREQ,
		RATE => RATE
	)
	PORT MAP(
		data => output,
		write => send,
		clock => clock,
		tx => tx,
		busy => txBusy
	);
	
	
----- SUMP END
------------------------------------------------------------------
-- This part is for data emission from FPGA to outside world / DAC
------------------------------------------------------------------	
	clk_dac <= osc125_clk ;		
	DAC_CLK <= clk_dac ; -- this clock commands the DAC
	DAC_SLEEP <= '0';
   Inst_addr_gen : Address
      port map (clk=>clk_dac,
                dout(3 downto 0)=>Addr(3 downto 0));
   	
	--11
   Inst_Rom1 : SineWave
      port map (addr(3 downto 0)=>Addr(3 downto 0),
                clk=>clk_dac,
                Dout(7 downto 0)=>wave1(7 downto 0));
   --10
   Inst_Rom2 : Triangle
      port map (addr(3 downto 0)=>Addr(3 downto 0),
                clk=>clk_dac,
                Dout(7 downto 0)=>wave2(7 downto 0));
   --01
   Inst_Rom3 : Sawtooth
      port map (addr(3 downto 0)=>Addr(3 downto 0),
                clk=>clk_dac,
                Dout(7 downto 0)=>wave3(7 downto 0));
   --00
   Inst_Rom4 : Pulse
      port map (addr(3 downto 0)=>Addr(3 downto 0),
                clk=>clk_dac,
                Dout(7 downto 0)=>wave4(7 downto 0));

   Inst_XLXI_1 : MUX
      port map (in0(7 downto 0)=>wave1(7 downto 0),
                in1(7 downto 0)=>wave2(7 downto 0),
                in2(7 downto 0)=>wave3(7 downto 0),
                in3(7 downto 0)=>wave4(7 downto 0),
                sel(1 downto 0)=>"10",
                dout(7 downto 0)=>wave(13 downto 6));
	wave(5 downto 0) <= "000000";
--   WaveRAM_data (5 downto 0) <= "000000";
--   WaveRAM_addr <= "0000" & Addr(3 downto 0);
--	-- for test : dac_run <= '1';
--	dac_run <= dac_enable;
--	-- this is DAC memory, used to send wave data
--   Inst_WaveRAM : WaveRAM
--   port map (   wr_clk  => clk_dac,
--                rd_clk  => clk_dac,
--                WR_Addr(7 downto 0) => command(15 downto 8), --for test : WaveRAM_addr
--                WR_Data(13 downto 0) => command(29 downto 16),	--for test : WaveRAM_data				 
--                RD_Addr => WaveRAM_addr,
--                RD_Data => wave,
--					 Run_Time(9 downto 0) => command(39 downto 30),
--					 txBusy => txBusy,
--					 SE => dac_select(0),
--                WE => dac_run);
					 
   --wave(13 downto 6) <= WaveRAM_data(13 downto 6);
----- Wave Generator END

-------------------------------------------------------------------
-- This part is for data reception from outside world to FPGA / ADC
-------------------------------------------------------------------
	adc_clk <= clkin_90; -- need some delay for transition stabilization
	
	Inst_adcapi: adcapi
	port map(
      reset => reset,
      clk => adc_clk,
      sclk => ADC_SCLK,  -- gives output serial programming interface clock
      sen => ADC_SEN,
      sdata => ADC_SDATA  -- gives output serial programming interface data
	);	
	
	-- delayed / stretched Reset generator used to initialise the ADC ADS552x
	FCDE_latch0 : FDCE
	generic map(
	  INIT => '0'
	)
	port map(
	  Q=>rst(0),
	  C=>adc_clk,
	  CE=>'1',
	  CLR=>'0',
	  D=>'1'
	 );
	 
	FCDE_latch1 : FDCE
	generic map(
	  INIT => '0'
	)
	port map(
	  Q=>rst(1),
	  C=>adc_clk,
	  CE=>'1',
	  CLR=>'0',
	  D=>rst(0)
	 );

	FCDE_latch2 : FDCE
	generic map(
	  INIT => '0'
	)
	port map(
	  Q=>rst(2),
	  C=>adc_clk,
	  CE=>'1',
	  CLR=>'0',
	  D=>rst(1)
	 );
	 
	FCDE_latch3 : FDCE
	generic map(
	  INIT => '1'
	)
	port map(
	  Q=>rst(3),
	  C=>adc_clk,
	  CE=>'1',
	  CLR=>'0',
	  D=>not rst(2)
	 );
	 
-- reset only one time set to 1, used to reset the ADC ADS552x
	ADC_RESET <= rst(3);
	
	ADC_CLKP <= adc_clk; -- this clock used to sample data
	
----- ADC END
	
end Behavioral;

