library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity FPGA is
  port (
    -- Main Clock (50 MHz)
    clk         : in std_logic;

	 --Uart
	 tx_x, tx_c		: out std_logic;
	 rx_x, rx_c		: in std_logic;
	 CTS_X, CTS_C	: in std_logic;
	 RTS_X, RTS_C	: out std_logic;
	 
	 --Reset Button
	 res	:in std_logic	
    );
end entity FPGA;
 
architecture RTL of FPGA is


	component UART_RX is
	  generic (
		 g_CLKS_PER_BIT : integer    -- Needs to be set correctly
		 );
	  port (
		 i_Clk       : in  std_logic;
		 i_RX_Serial : in  std_logic;
		 o_RX_DV     : out std_logic;
		 o_RX_Byte   : out std_logic_vector(7 downto 0)
		 );
	end component;
	component UART_TX is
	  generic (
		 g_CLKS_PER_BIT : integer    -- Needs to be set correctly
		 );
	  port (
		 i_Clk       : in  std_logic;
		 i_TX_DV     : in  std_logic;
		 i_TX_Byte   : in  std_logic_vector(7 downto 0);
		 o_TX_Active : out std_logic;
		 o_TX_Serial : out std_logic;
		 o_TX_Done   : out std_logic
		 );
	end component;
	component FIFO_BRAM IS
		PORT
		(
			aclr		: IN STD_LOGIC ;
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			full		: OUT STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END component;
	component Controller is
	  port (
			CTS_X, CTS_C 	:in std_logic;
			Reset, clk		:in std_logic;
			rx_dv, tx_ac	:in std_logic;
			fifo_f, fifo_e	:in std_logic;
			wr_en, rd_en	:out std_logic;
			tx_dv				:out std_logic;
			RTS_X, RTS_C	:out std_logic
			--wr_byte, rd_byte 	:in std_logic_vector(7 downto 0)
		 );
	end component;
	component debounce is
		port(
					Clock 	:in std_logic; --50MHz clock
					button	:in std_logic;	--noisy signal
					debounce	:buffer std_logic
		);
	end component;	
  
  constant GENBITS: integer := integer(ceil(log2(real(integer(434)))));
  -- Signal for UART From Xport to CC1310
  signal w_RX_DV     : std_logic;
  signal w_RX_Byte   : std_logic_vector(7 downto 0);
  signal w_TX_Active : std_logic;
  signal w_TX_Serial : std_logic;
  
    -- Signal for UART From Xport to CC1310
  signal C_RX_DV     : std_logic;
  signal C_RX_Byte   : std_logic_vector(7 downto 0);
  signal C_TX_Active : std_logic;
  signal C_TX_Serial : std_logic;
  
  -- Signal for FIFO
  constant	 g_WIDTH : natural := 8;
  constant	 g_DEPTH : integer := 3;
  Signal reset, wr_en, rd_en	:std_logic;
  Signal fifo_f, fifo_e			:std_logic;
  signal wr_data, rd_data		:std_logic_vector(g_WIDTH-1 downto 0);
  
  -- Signal for FSM
  signal Reset_f, tx_dv, rx_dv, tx_done, clk_g, tx_ac		:std_logic;
	
  attribute chip_pin : string;
  attribute chip_pin of clk : signal is "88";
  attribute chip_pin of tx_x : signal is "43"; 
  attribute chip_pin of rx_X : signal is "50"; 
  attribute chip_pin of cts_x : signal is "44"; 
  attribute chip_pin of rts_x : signal is "46"; 
  attribute chip_pin of res : signal is "47"; 
  attribute chip_pin of tx_c : signal is "33"; 
  attribute chip_pin of rx_c : signal is "57"; 
--  attribute chip_pin of cts_c : signal is "PIN_44"; 
--  attribute chip_pin of rts_c : signal is "PIN_46"; 

  
 
begin
  --Route from Xport to CC1310
  UART_RX_Xport :  UART_RX
	 generic map(integer(54))	--54 for 921600bps Baudrate
    port map (
      clk,
      rx_x,
      rx_dv,
      wr_data);
		
  UART_TX_CC1310 :  UART_TX
	 generic map(integer(54))	--54 for 921600bps Baudrate
    port map (
      clk,
      tx_dv,
      rd_data,
      w_TX_Active,
      w_TX_Serial,
      tx_done
      );
 
  --Route from CC1310 to Xport
  UART_RX_CC1310 :  UART_RX
	 generic map(integer(100))	--100 for 500kbps Baudrate 
    port map (
      clk,
      rx_c,
      C_RX_DV,
      C_RX_Byte);
		
  UART_TX_XPORT :  UART_TX
	 generic map(integer(100))
    port map (
      clk,
      C_RX_DV,
      C_RX_Byte,
      C_TX_Active,
      C_TX_Serial,
      open
      );
		
	
	fifo_b: FIFO_BRAM PORT MAP
		(
			aclr => Reset_f,
			clock => clk,
			data => wr_data,
			rdreq => rd_en,
			wrreq	=> wr_en,
			empty	=> fifo_e,
			full	=> fifo_f,
			q	=> rd_data
		);	
  -- Drive UART line high when transmitter is not active
  tx_c <= w_TX_Serial when w_TX_Active = '1' else '1';
  tx_x <= C_TX_Serial when C_TX_Active = '1' else '1';
		
  -- Controller connection
  con: Controller port map(
			CTS_X=>CTS_X, CTS_C=>CTS_C,
			Reset=>Reset_f, clk=>clk,
			rx_dv=>rx_dv, tx_ac=>tx_ac,
			fifo_f=>fifo_f, fifo_e=>fifo_e,
			wr_en=>wr_en, rd_en=>rd_en,
			tx_dv=>tx_dv,
			RTS_X=>RTS_X, RTS_C=>RTS_C
		 );
	-- Debounce for reset button
	debounce_rst: debounce port map(clk, res, Reset_f);
	
	tx_ac <= '1' when tx_done='1' or w_TX_Active='1' else '0';
   
end architecture RTL;