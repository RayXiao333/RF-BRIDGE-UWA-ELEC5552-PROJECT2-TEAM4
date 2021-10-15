-------------------------------------------------------------
-- UART loopback program with FIFO
-- Board: DE10-Lite
-- Author :Ray Xiao Team 4
-- IO: 			RX_X <- GPIO(0)
--					TX_X <- GPIO(1)
-- 	 			RX_C <- GPIO(10)
--					TX_C <- GPIO(11)
-- Function: 	Reset <- Key(0)
--					CTS_X <- GPIO(2)
--					RTS_X <- GPIO(3)
--					CTS_C <- GPIO(28)
--					RTS_C <- GPIO(29)
-- Debug use:	FIFO_FULL <- LEDR(9)
--					FIFO_EMPTY <- LEDR(8)
--------------------------------------------------------------					 

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity FPGA_MAX10 is
  port (
    -- Main Clock (50 MHz)
    MAX10_CLK1_50         : in std_logic;
 
    -- UART Data
	 GPIO 			: inout std_logic_vector(35 downto 0);
	 
	 --Reset Button
	 SW 	: in std_logic_vector(9 downto 0);
	 KEY 	: in std_logic_vector(1 downto 0);
     
    -- Segment1 is upper digit, Segment2 is lower digit
	 HEX0	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Lower num
	 HEX1	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Higher num
	 HEX2	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Lower num
	 HEX3, HEX4, HEX5	:OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--Higher num
	 LEDR	:OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
		
    );
end entity FPGA_MAX10;
 
architecture RTL of FPGA_MAX10 is


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
	component ss_decoder is
	port(
		ssd_in :in std_logic_vector(3 downto 0);
		ssd_out:out std_logic_vector(6 downto 0)
		);
	END component;
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
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			usedw		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	END component;
	component clk_gen is
		generic(
					GENBITS : integer;     -- Needs to be set correctly
					high_rate_cnt : integer;     -- Needs to be set correctly
					low_rate_cnt  : integer     -- Needs to be set correctly
			 );
		port(
				rst_L 	:in std_logic;
				clk_in	:in std_logic;
				rate		:in std_logic;
				clk		:out std_logic
			);
	end component;
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
  -- Signal for UART
  signal w_RX_DV     : std_logic;
  signal w_RX_Byte   : std_logic_vector(7 downto 0);
  signal w_TX_Active : std_logic;
  signal w_TX_Serial : std_logic;
  
  signal C_RX_DV     : std_logic;
  signal C_RX_Byte   : std_logic_vector(7 downto 0);
  signal C_TX_Byte   : std_logic_vector(7 downto 0);
  signal C_TX_Active : std_logic;
  signal C_TX_Serial : std_logic;
  signal C_TX_EN 		: std_logic;
  
  -- Signal for FIFO
  constant	 g_WIDTH : natural := 8;
  constant	 g_DEPTH : integer := 2000;
  Signal reset, wr_en, rd_en	:std_logic;
  Signal fifo_f, fifo_e			:std_logic;
  signal wr_data, rd_data		:std_logic_vector(g_WIDTH-1 downto 0);
  
  -- Signal for FSM
  signal Reset_f, tx_dv, rx_dv, tx_done, clk_g, tx_ac		:std_logic;
  signal reset_state :std_logic := '1';
  signal CTS_C, RTS_C, CTS_X, RTS_X		:std_logic;
  type state_type is (rx, tx, int, tx_ready, idle);
  SIGNAL PS, NS :state_type;
  
 
begin
  --RX from XPORT
  UART_RX_XP :  UART_RX
	 generic map(integer(54))	--54 for 921600bps Baudrate
    port map (
      MAX10_CLK1_50,
      GPIO(0),
      rx_dv,
      wr_data);
		
  -- TX to XPORT
  UART_TX_XP :  UART_TX
    generic map(integer(54))
    port map (
      MAX10_CLK1_50,
      C_RX_DV,
      C_TX_Byte,
      C_TX_Active,
      C_TX_Serial,
      OPEN
      );
		
  --RX from CC1310
  UART_RX_CC :  UART_RX
	 generic map(integer(77))	--77 for 650kbps Baudrate 
    port map (
      MAX10_CLK1_50,
      GPIO(10),
      C_RX_DV,
      C_RX_Byte);
 
 
  -- TX to CC1310
  UART_TX_CC :  UART_TX
	 generic map(integer(77))
    port map (
      MAX10_CLK1_50,
      tx_dv,
      rd_data,
      w_TX_Active,
      w_TX_Serial,
      tx_done
      );
		
	fifo_b: FIFO_BRAM PORT MAP
		(
			aclr => Reset_f,
			clock => MAX10_CLK1_50,
			data => wr_data,
			rdreq => rd_en,
			wrreq	=> wr_en,
			empty	=> fifo_e,
			full	=> fifo_f,
			q	=> rd_data,
			usedw	=> OPEN	
		);
		
	
  -- Drive UART line high when transmitter is not active
  GPIO(11) <= w_TX_Serial when w_TX_Active = '1' else '1';
  GPIO(1) <= C_TX_Serial when C_TX_Active = '1' else '1';
  C_TX_Byte <= C_RX_Byte;
   
  -- Binary to 7-Segment Converter for Lower Digit 
  rx_lower: ss_decoder port map(wr_data(3 downto 0), HEX0(6 downto 0));
  -- Binary to 7-Segment Converter for Upper Digit 
  rx_upper: ss_decoder port map(wr_data(7 downto 4), HEX1(6 downto 0));
  
  -- Binary to 7-Segment Converter for Lower Digit 
  tx_lower: ss_decoder port map(rd_data(3 downto 0), HEX2(6 downto 0));
  -- Binary to 7-Segment Converter for Upper Digit 
  tx_upper: ss_decoder port map(rd_data(7 downto 4), HEX3(6 downto 0));
  
  -- Binary to 7-Segment Converter for Lower Digit 
  MID_lower: ss_decoder port map(C_RX_Byte(3 downto 0), HEX4(6 downto 0));
  -- Binary to 7-Segment Converter for Upper Digit 
  MID_upper: ss_decoder port map(C_RX_Byte(7 downto 4), HEX5(6 downto 0));
  
  clkgen: clk_gen 	Generic map (GENBITS, integer(1), integer(434))
						port map (Reset_f, MAX10_CLK1_50, '0', clk_g);
						
  -- Controller connection
  con: Controller port map(
			CTS_X=>CTS_X, CTS_C=>CTS_C, 
			Reset=>Reset_f, clk=>MAX10_CLK1_50,
			rx_dv=>rx_dv, tx_ac=>tx_ac,
			fifo_f=>fifo_f, fifo_e=>fifo_e,
			wr_en=>wr_en, rd_en=>rd_en,
			tx_dv=>tx_dv,
			RTS_X=>RTS_X, RTS_C=>RTS_C
		 );
	-- Debounce for reset button
	debounce_rst: debounce port map(MAX10_CLK1_50, KEY(0), Reset_f);
   
	-- Active when TX module is not done. Use for controller
	tx_ac <= '1' when tx_done='1' or w_TX_Active='1' else '0';
	CTS_X <= GPIO(2);
	GPIO(3) <= RTS_X;
	CTS_C <= GPIO(28);
--	CTS_C <= SW(0);
	GPIO(29) <= RTS_C;
	
	LEDR(0)<=RTS_X;
	LEDR(1)<=RTS_C;
	
	LEDR(9) <= fifo_f;
	LEDR(8) <= fifo_e;
	LEDR(7) <= wr_en;
	LEDR(6) <= rd_en;
  
 
   
end architecture RTL;
