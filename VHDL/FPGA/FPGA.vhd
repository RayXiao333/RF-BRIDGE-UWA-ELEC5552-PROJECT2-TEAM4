library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity FPGA is
  port (
    -- Main Clock (50 MHz)
    MAX10_CLK1_50         : in std_logic;
 

	 
	 tx_x, tx_c		: out std_logic;
	 rx_x, rx_c		: in std_logic;
	 RTS_X, CTS_C	: in std_logic;
	 CTS_X, RTS_C	: out std_logic;
	 
	 --Reset Button
	 SW : in std_logic_vector(9 downto 0)
     
--    -- UART Data
--	 GPIO 			: inout std_logic_vector(35 downto 0);
    -- Segment1 is upper digit, Segment2 is lower digit
--	 HEX0	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Lower num
--	 HEX1	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Higher num
--	 HEX2	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Lower num
--	 HEX3	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Higher num
--	 LEDR	:OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
		
    );
end entity FPGA;
 
architecture RTL of FPGA is


	component UART_RX is
	  port (
		 i_Clk       : in  std_logic;
		 i_RX_Serial : in  std_logic;
		 o_RX_DV     : out std_logic;
		 o_RX_Byte   : out std_logic_vector(7 downto 0)
		 );
	end component;
	component UART_TX is
	  port (
		 i_Clk       : in  std_logic;
		 i_TX_DV     : in  std_logic;
		 i_TX_Byte   : in  std_logic_vector(7 downto 0);
		 o_TX_Active : out std_logic;
		 o_TX_Serial : out std_logic;
		 o_TX_Done   : out std_logic
		 );
	end component;
--	component ss_decoder is
--	port(
--		ssd_in :in std_logic_vector(3 downto 0);
--		ssd_out:out std_logic_vector(6 downto 0)
--		);
--	END component;
	component FIFO_NandLand is
	  generic (
		 g_WIDTH : natural;
		 g_DEPTH : integer
		 );
	  port (
		 i_rst_sync : in std_logic;
		 i_clk      : in std_logic;
	 
		 -- FIFO Write Interface
		 i_wr_en   : in  std_logic;
		 i_wr_data : in  std_logic_vector(g_WIDTH-1 downto 0);
		 o_full    : out std_logic;
	 
		 -- FIFO Read Interface
		 i_rd_en   : in  std_logic;
		 o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
		 o_empty   : out std_logic
		 );
	end component;
	component Controller is
	  port (
			RTS_X, CTS_C 	:in std_logic;
			Reset, clk		:in std_logic;
			rx_dv				:in std_logic;
			fifo_f, fifo_e	:in std_logic;
			wr_en, rd_en	:out std_logic;
			tx_dv				:out std_logic;
			CTS_X, RTS_C	:out std_logic
			--wr_byte, rd_byte 	:in std_logic_vector(7 downto 0)
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
  signal Reset_f, tx_dv, rx_dv, tx_done, clk_g		:std_logic;
--  signal CTS_C, RTS_C, CTS_X, RTS_X		:std_logic;
  type state_type is (rx, tx, int, tx_ready, idle);
  SIGNAL PS, NS :state_type;
  
 
begin
  --Route from Xport to CC1310
  UART_RX_Xport :  UART_RX
    port map (
      MAX10_CLK1_50,
      rx_x,
      rx_dv,
      wr_data);
		
  UART_TX_CC1310 :  UART_TX
    port map (
      MAX10_CLK1_50,
      tx_dv,
      rd_data,
      w_TX_Active,
      w_TX_Serial,
      tx_done
      );
 
  --Route from CC1310 to Xport
  UART_RX_CC1310 :  UART_RX
    port map (
      MAX10_CLK1_50,
      rx_c,
      C_RX_DV,
      C_RX_Byte);
		
  UART_TX_XPORT :  UART_TX
    port map (
      MAX10_CLK1_50,
      C_RX_DV,
      C_RX_Byte,
      C_TX_Active,
      C_TX_Serial,
      open
      );
		
	fifo_fpga: FIFO_NandLand 	Generic map(g_WIDTH, g_DEPTH)
										port map(Reset_f, MAX10_CLK1_50,
													wr_en, wr_data, fifo_f,
													rd_en, rd_data, fifo_e);
		
  -- Drive UART line high when transmitter is not active
  tx_c <= w_TX_Serial when w_TX_Active = '1' else '1';
  tx_x <= C_TX_Serial when C_TX_Active = '1' else '1';
   
--  -- Binary to 7-Segment Converter for Lower Digit 
--  rx_lower: ss_decoder port map(wr_data(3 downto 0), HEX0(6 downto 0));
--  -- Binary to 7-Segment Converter for Upper Digit 
--  rx_upper: ss_decoder port map(wr_data(7 downto 4), HEX1(6 downto 0));
--  
--  -- Binary to 7-Segment Converter for Lower Digit 
--  tx_lower: ss_decoder port map(rd_data(3 downto 0), HEX2(6 downto 0));
--  -- Binary to 7-Segment Converter for Upper Digit 
--  tx_upper: ss_decoder port map(rd_data(7 downto 4), HEX3(6 downto 0));
--						
  -- Controller connection
  con: Controller port map(
			RTS_X=>RTS_X, CTS_C=>CTS_C,
			Reset=>Reset_f, clk=>MAX10_CLK1_50,
			rx_dv=>rx_dv,
			fifo_f=>fifo_f, fifo_e=>fifo_e,
			wr_en=>wr_en, rd_en=>rd_en,
			tx_dv=>tx_dv,
			CTS_X=>CTS_X, RTS_C=>RTS_C
		 );
   
	
--	RTS_X <= GPIO(2);
--	CTS_C <= GPIO(5);
	Reset_f <= SW(0);
	
--  LEDR(9) <= fifo_f;
--  LEDR(8) <= fifo_e;
--  --LEDR(7) <= rx_dv;
--  --LEDR(6) <= tx_dv;
--  LEDR(7 downto 5) <= "001" when wr_en = '0' and rd_en = '0' else
--							 "010" when wr_en = '1' and rd_en = '0' else
--							 "100" when wr_en = '0' and rd_en = '1' else
--							 "000";
-- 
   
end architecture RTL;