--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
USE ieee.math_real.ALL;
package UART_RS232 is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
	constant baudrate : real := 115200.0;
	constant t :real := 1.0 / baudrate;
   constant period : time := t * 1 sec;
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--
function max_count(constant baudrate : integer;  constant freq : integer) return integer;
procedure uart_send(constant Data : in std_logic_vector; signal serial_out : out std_logic);
procedure uart_get (signal  serial_in : in std_logic; signal dout : out std_logic_vector);
end UART_RS232;

package body UART_RS232 is

	procedure uart_send(constant Data : in std_logic_vector; signal serial_out : out std_logic) is
	begin		
		serial_out <= '0';
		wait for period;
		--for i in 23*8-1 downto 0 loop 
		for i in 7 downto 0 loop
			serial_out   <= Data(i);
			wait for period;
		end loop;
		serial_out <= '1';	
      wait for period;		
	end uart_send;

	procedure uart_get(signal  serial_in : in std_logic; signal dout : out std_logic_vector) is
		variable reg : std_logic_vector(8 downto 0);
	begin		
		while(serial_in='1')loop
			wait for 1  ns;
		end loop;
		wait for period/2;
		for i in 0 to 8 loop
		   wait for period;
			reg(i) := serial_in;
		end loop;
		dout <= reg(7 downto 0);
	end uart_get; 
	
	function max_count(constant baudrate : integer;  constant freq : integer) return integer is
		variable remainder : real;
		variable i : integer := 15;
	begin
	while(i<32) loop
		remainder := real(freq) /(real(i+1) * real(baudrate));
		remainder := (remainder - floor(remainder)) * 10.0;
		if(remainder < 1.0 )then
			exit;
		end if;
		i := i + 2;
	end loop;
	return (i+1);
	end function max_count;
end UART_RS232;
