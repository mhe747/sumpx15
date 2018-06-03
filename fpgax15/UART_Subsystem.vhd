--======== to transmit data =======--
--wait untill tx_ready=1 then apply data to TX_data and triger statr_tx

--======== to receiv data ==========--
-- wait untill RX_done=1 then sample the data at RX_data

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity UART_subsystem is
generic(baudrate:integer:=115200;      --- Baudrate
        freq     :integer:=50000000);--- frequency
   port ( clock      : in    std_logic; 
	       reset      : in    std_logic; 
			 -- control signals
			 tx_ready   : out   std_logic;
			 rx_done    : out   std_logic;
			 start_tx   : in    std_logic; 
			 -- data ports
          RX_data    : out   std_logic_vector (7 downto 0); -- received data 
			 TX_data    : in    std_logic_vector (7 downto 0); -- received data
			 -- UART ports
			 Serial_in  : in    std_logic; 
          Serial_out : out   std_logic);
			 
end UART_subsystem;

architecture BEHAVIORAL of UART_subsystem is
   component RX
	generic(baudrate:integer:=baudrate;freq:integer:=freq);
      port ( reset     : in    std_logic; 
             clk       : in    std_logic; 
             Serial_in : in    std_logic; 
				 RX_done   : out    std_logic;
             Data_out  : out   std_logic_vector (7 downto 0));
   end component;
   
   component TX
	generic(baudrate:integer:=baudrate;freq:integer:=freq);
      port ( clk        : in    std_logic; 
             reset      : in    std_logic; 
             start      : in    std_logic; 
             TX_data    : in    std_logic_vector (7 downto 0); 
				 tx_ready   : out STD_LOGIC;
             Serial_out : out   std_logic);
   end component;
   
begin
   receiver : RX
      port map (clk=>clock,
                reset=>reset,
                Serial_in=>Serial_in,
					 RX_done=>rx_done,
                Data_out(7 downto 0)=>RX_data(7 downto 0));
   
   transmitter : TX
      port map (clk=>clock,
                reset=>reset,
                start=>start_tx,
                TX_data(7 downto 0)=>TX_data,
					 tx_ready =>tx_ready,
                Serial_out=>Serial_out);
--      assert (TX_data=x"33") report "Data = " & integer'image(TX_data);   
end BEHAVIORAL;


