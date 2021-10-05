library ieee;
use ieee.std_logic_1164.all;
 
entity UART_Loopback_Top_Assign is
  port (
    -- Main Clock (25 MHz)
    MAX10_CLK1_50         : in std_logic;
 
    -- UART Data
    GPIO : inout  std_logic_vector(35 downto 0);
     
    -- Segment1 is upper digit, Segment2 is lower digit
	 HEX0 :out std_logic_vector(7 downto 0);
	 HEX1 :out std_logic_vector(7 downto 0)
    );
end entity UART_Loopback_Top_Assign;

architecture arc of UART_Loopback_Top_Assign is

	component UART_Loopback_Top is
	  port (
		 -- Main Clock (25 MHz)
		 i_Clk         : in std_logic;
	 
		 -- UART Data
		 i_UART_RX : in  std_logic;
		 o_UART_TX : out std_logic;
		  
		 -- Segment1 is upper digit, Segment2 is lower digit
		 o_Segment1_A  : out std_logic;
		 o_Segment1_B  : out std_logic;
		 o_Segment1_C  : out std_logic;
		 o_Segment1_D  : out std_logic;
		 o_Segment1_E  : out std_logic;
		 o_Segment1_F  : out std_logic;
		 o_Segment1_G  : out std_logic;
		  
		 o_Segment2_A  : out std_logic;
		 o_Segment2_B  : out std_logic;
		 o_Segment2_C  : out std_logic;
		 o_Segment2_D  : out std_logic;
		 o_Segment2_E  : out std_logic;
		 o_Segment2_F  : out std_logic;
		 o_Segment2_G  : out std_logic
		 );
	end component UART_Loopback_Top;

begin 
	u1: UART_Loopback_Top port map (MAX10_CLK1_50, GPIO(0), GPIO(1),
												HEX1(0), HEX1(1), HEX1(2), HEX1(3), HEX1(4),
												HEX1(5), HEX1(6),
												HEX0(0), HEX0(1), HEX0(2), HEX0(3), HEX0(4),
												HEX0(5), HEX0(6));

end arc;
