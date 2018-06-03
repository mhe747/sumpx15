library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity WaveGenerator is
   port (oscclk  : in    std_logic; 
			exClock  : in    std_logic;
			reset : in std_logic;		
			-- UART ports   115200-8N1
			Serial_in  : in    std_logic; 
         Serial_out : out   std_logic;
			-- DAC
         --freq : in    std_logic_vector (2 downto 0); 
         --sel  : in    std_logic_vector (1 downto 0); 
         wave : out   std_logic_vector (13 downto 0);
			DAC_CLK : out std_logic; 
			DAC_SLEEP : out std_logic;
			-- SPI -- in futur implementation
--			SPI_MOSI : in    std_logic; 
--			SPI_MISO : out    std_logic;
			-- ADC
			input : in std_logic_vector(11 downto 0);			
			ADC_SEN : out std_logic;
			ADC_CLKP : out std_logic;
			ADC_RESET : out std_logic;
			ADC_SDATA : out std_logic;
			ADC_SCLK : out std_logic			 
			 );
			 
end WaveGenerator;

architecture BEHAVIORAL of WaveGenerator is

	constant DAC_BUFFER_LOGSIZE : integer := 12; -- 14:32768 13:16384 12:8192 samples
	constant ADC_BUFFER_LOGSIZE : integer := 12; -- 14:32768 13:16384 12:8192 samples
	
	constant DAC_SAMPLE_SIZE : integer := 12;  -- 13 bits
	constant ADC_SAMPLE_SIZE : integer := 7;  -- 8 bits
	
	constant UART_SAMPLE_SIZE : integer := 7; -- 8 bits
	
   component Address
		generic (
			BUFFER_LOGSIZE : integer
		);
      port ( clk  : in    std_logic; 
             dout : out   std_logic_vector (DAC_BUFFER_LOGSIZE downto 0));
   end component;
	
   component Address2
		generic (
			BUFFER_LOGSIZE : integer
		);
      port ( reset : in  STD_LOGIC;
				 clk  : in    std_logic; 
             dout : out   std_logic_vector (ADC_BUFFER_LOGSIZE downto 0));
   end component;	
   
   component clock_divider
      port ( clk_in   : in    std_logic; 
             freq_div : in    std_logic_vector (19 downto 0); 
             clk_out  : out   std_logic);
   end component;
   
	component clockman
		port(
			clkin : in  STD_LOGIC;
			clk0 : out std_logic
		);
	end component;
	
--! Component declaration for UART_subsystem
component UART_subsystem is
   port ( clock      : in    std_logic; 
	       reset      : in    std_logic; 
			 
			 tx_ready   : out   std_logic;
			 rx_done    : out   std_logic;
			 start_tx   : in    std_logic; 
			 
          RX_data    : out   std_logic_vector (UART_SAMPLE_SIZE downto 0); 
			 TX_data    : in    std_logic_vector (UART_SAMPLE_SIZE downto 0); 
			 
			 Serial_in  : in    std_logic; 
          Serial_out : out   std_logic);
			 
end component;   
	COMPONENT RAM
	generic (
		BUFFER_LOGSIZE : integer;
		SAMPLE_LOGSIZE : integer
	);
	port(
		wr_clk : IN std_logic;
		rd_clk : IN std_logic;
		WR_Addr : IN std_logic_vector(DAC_BUFFER_LOGSIZE downto 0); -- N elements
		RD_Addr : IN std_logic_vector(DAC_BUFFER_LOGSIZE downto 0);
		WR_Data : IN std_logic_vector(DAC_SAMPLE_SIZE downto 0);
		RD_Data : OUT std_logic_vector(DAC_SAMPLE_SIZE downto 0);
		WE : IN std_logic
		);
	END COMPONENT;
	
	
	COMPONENT RAM2
	generic (
		BUFFER_LOGSIZE : integer;
		SAMPLE_LOGSIZE : integer
	);
	port(
		wr_clk : IN std_logic;
		rd_clk : IN std_logic;
		WR_Addr : IN std_logic_vector(ADC_BUFFER_LOGSIZE downto 0); -- N elements
		RD_Addr : IN std_logic_vector(ADC_BUFFER_LOGSIZE downto 0);
		WR_Data : IN std_logic_vector(ADC_SAMPLE_SIZE downto 0);
		RD_Data : OUT std_logic_vector(ADC_SAMPLE_SIZE downto 0);
		WE : IN std_logic
		);
	END COMPONENT;	
	---- ADC 552x
	signal rst : std_logic_vector (3 downto 0);
	signal adc_clk : std_logic;
	signal adc_clock : std_logic;	
	
	component adcapi is
	port (
		reset	: in	std_logic;
		clk		: in	std_logic;
		sclk	: out	std_logic;
		sen		: out	std_logic;
		sdata	: out	std_logic
	);
   end component;
----
	
-- Signal declarations
signal   clk_div : std_logic;
signal   clk : std_logic;
signal   tx_ready   : std_logic;
signal   rx_done    : std_logic;
signal   start_tx   : std_logic;
signal   RX_data    : std_logic_vector (UART_SAMPLE_SIZE downto 0);
signal   TX_data    : std_logic_vector (UART_SAMPLE_SIZE downto 0);
signal   DAC_RD_Addr  : std_logic_vector (DAC_BUFFER_LOGSIZE downto 0);
signal   DAC_WR_Addr    : std_logic_vector (DAC_BUFFER_LOGSIZE downto 0);
signal   DAC_WR_Data    : std_logic_vector (DAC_SAMPLE_SIZE downto 0); 
signal   DAC_WE         : std_logic;

signal   ADC_RD_Addr  : std_logic_vector (ADC_BUFFER_LOGSIZE downto 0);
signal   ADC_RD_Data    : std_logic_vector (ADC_SAMPLE_SIZE downto 0) :=(others=>'0'); 
signal   ADC_WR_Addr    : std_logic_vector (ADC_BUFFER_LOGSIZE downto 0);
-- for test
signal   ADC_WR_Data    : std_logic_vector (ADC_SAMPLE_SIZE downto 0);
signal   ADC_SE         : std_logic := '1';
signal   ADC_RESET_STO  : std_logic := '0';

-- for futur implementation
signal freq_div  : std_logic_vector (19 downto 0) := "00000000000000000001"; -- 20 bits

type state_type is (Idle, S0, S1, S2, S3, S4);
signal dac_state : state_type := Idle;
signal adc_state : state_type := Idle;

begin

-- SPI_MISO <= SPI_MOSI;
   	
syst_clockman: clockman
	port map(
		clkin => oscclk,
		clk0 => clk
	);

-- clk_div not used here
ClockDivider : clock_divider
	port map (clk_in=>clk,
				 freq_div(19 downto 0)=>freq_div(19 downto 0),
				 clk_out=>clk_div);
				 
DAC_FSM : process(clk)
begin
	if rising_edge(clk) then
		DAC_WE <= '0';
		case(dac_state)is
			when Idle =>
				if(rx_done='1')then
					dac_state <= S0;
				else
					dac_state <= Idle;
				end if;
			when S0 =>
				--WR_Data(DAC_SAMPLE_SIZE downto 8) <= RX_data(4 downto 0);  -- MSB First / Arm
				DAC_WR_Data(UART_SAMPLE_SIZE downto 0) <= RX_data;  -- LSB First / Intel
				-- for test if not using ADC incoming data
				-- ADC_WR_Data  <= "11111110";
				dac_state <= S1;
			when S1 =>
				if(rx_done='1')then
					dac_state <= S2;
				else
					dac_state <= S1;
				end if;	
			when S2 =>
				--WR_Data(UART_SAMPLE_SIZE downto 0) <= RX_data;  -- MSB First / Arm
				DAC_WR_Data(DAC_SAMPLE_SIZE downto 8) <= RX_data(4 downto 0);  -- LSB First / Intel
				dac_state <= S3;				
			when S3 =>
				DAC_WE <= '1';
				dac_state <= S4;
			when S4 =>
				DAC_WR_Addr <= DAC_WR_Addr + 1;
				dac_state <= Idle;
			when others=>
				dac_state <= Idle;
		end case;
	end if;
end process;

TRIGGER_FSM : process(ADC_WR_Addr(0))
begin
	if rising_edge(ADC_WR_Addr(0)) and (ADC_WR_Addr = "11111111111111") then
		-- stop ADC when buffer is full, now wait for UART signal tx_ready
		ADC_SE <= '0';
	end if;
end process;

ADC_FSM : process(clk)
begin
	if rising_edge(clk) then
		ADC_RESET_STO <= '0';
		case(adc_state)is
		   when Idle =>
				adc_state <= S0;
				-- maybe add another conditionnal trigger function here :
			when S0 =>
				if(tx_ready='1') then
					adc_state <= S1;
				else
					adc_state <= S0;
				end if;
			when S1 =>
				TX_data <= ADC_RD_Data(UART_SAMPLE_SIZE downto 0);
				--TX_data <= "00101000";   -- for test : ok
				start_tx <= '1';
				ADC_RD_Addr <= ADC_RD_Addr + 1;
				adc_state <= S2;
			when S2 =>
				if (ADC_RD_Addr = "00000000000000") then
					ADC_SE <= '1';	 -- all data sent to UART, now re-activate the ADC
					ADC_RESET_STO <= '1';
					adc_state <= Idle;
				else
					-- send next byte
					adc_state <= S0;					
				end if;
			when others=>
				adc_state <= Idle;
		end case;
	end if;
end process;


   --! Port map declaration for UART_subsystem
   comp_UART_subsystem : UART_subsystem
      port map (
                clock      => clk,
                reset      => '0',
                tx_ready   => tx_ready,
                rx_done    => rx_done,
                start_tx   => start_tx,
                RX_data    => RX_data,
                TX_data    => TX_data,
                Serial_in  => Serial_in,
                Serial_out => Serial_out
   );
   dac_comp_RAM : RAM
		generic map (
			BUFFER_LOGSIZE => DAC_BUFFER_LOGSIZE,
			SAMPLE_LOGSIZE => DAC_SAMPLE_SIZE
		)	
      port map (
                wr_clk  => clk,
                rd_clk  => exClock,
                WR_Addr => DAC_WR_Addr,   --uart write to DAC memory when data received
                RD_Addr => DAC_RD_Addr,   --sample sent to DAC automatically depend on DAC_WE
                WR_Data => DAC_WR_Data,   
                RD_Data => wave(13 downto 1),
                WE      => DAC_WE
   );
	wave(0 downto 0) <= "0";
	
   adc_comp_RAM : RAM2
		generic map (
			BUFFER_LOGSIZE => ADC_BUFFER_LOGSIZE,
			SAMPLE_LOGSIZE => ADC_SAMPLE_SIZE
		)	
      port map (
                wr_clk  => clk,
                rd_clk  => clk,
                WR_Addr => ADC_WR_Addr,       --sample received from ADC automatically 
                RD_Addr => ADC_RD_Addr,       --uart read address increment according to ADC_FSM
                WR_Data => input(11 downto 4),  --ADC_WR_Data, 
                RD_Data => ADC_RD_Data,       --uart read data in ADC memory
                WE      => ADC_SE
   );	
	
   dac_addr_gen : Address
		generic map (
			BUFFER_LOGSIZE => DAC_BUFFER_LOGSIZE
		)		
      port map (clk=>clk, --exClock
                dout(DAC_BUFFER_LOGSIZE downto 0)=>DAC_RD_Addr(DAC_BUFFER_LOGSIZE downto 0));

   adc_addr_gen : Address2
		generic map (
			BUFFER_LOGSIZE => ADC_BUFFER_LOGSIZE
		)		
      port map (reset=>ADC_RESET_STO,clk=>clk,
                dout(ADC_BUFFER_LOGSIZE downto 0)=>ADC_WR_Addr(ADC_BUFFER_LOGSIZE downto 0));
      

	DAC_SLEEP <= '0';
	DAC_CLK <= exClock;
	
	
-------------------------------------------------------------------
-- This part is for data reception from outside world to FPGA / ADC
-------------------------------------------------------------------
	--adc_clk <= adc_clock; -- set to 80 Mhz DCM = clkin_90 / 5 * 8  -- need some delay for transition stabilization
	adc_clk <= clk;
	ADC_CLKP <= adc_clk; -- this clock command ADC used to sample data

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
	
end BEHAVIORAL;


