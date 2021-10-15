library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity Controller is
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
end entity Controller;
 
architecture RTL of Controller is

  type state_type is (rx, rx_done, tx, tx_2, int, tx_ready, idle);
  SIGNAL PS, NS :state_type;

begin 

	syn: process(clk)
	begin 
		if(Reset='1')then 
			PS <= int;
		else
			if(clk'event and clk='1')then
				PS <= NS;
			else
				PS <= PS;
			end if;
		end if;
	end process;
	
	process(PS)
	begin 
		Case PS is 
			--Initialize state
			when int =>
				wr_en <= '0';
				rd_en <= '0';
				tx_dv <= '0';
				NS <= idle;
			-- do nothing but reset rd and wr
			when idle =>
				wr_en <= '0';
				rd_en <= '0';
				tx_dv <= '0';
				if RTS_X = '1' and fifo_f /= '1' then
					NS <= rx;
				elsif CTS_C = '1' and fifo_e /= '1' then
					NS <= tx_ready;
				else NS <= idle;
				end if;
			-- active Fifo to load
			when rx =>
				if rx_dv = '1' then
					wr_en <= '1';
					rd_en <= '0';
				end if;
				NS <= rx_done;
			-- deactive fifo after 1 period
			when rx_done => 
				wr_en <= '0';
				rd_en <= '0';
				NS <= idle;
			-- Active fifo to pull data
			when tx_ready =>
				wr_en <= '0';
				rd_en <= '0';
				tx_dv <= '1';
				NS <= tx;
			--Deactive fifo and trans
			when tx =>
				wr_en <= '0';
				rd_en <= '1';
				tx_dv <= '1';
				NS <= tx_2;
			when tx_2 => 
				wr_en <= '0';
				rd_en <= '1';
				tx_dv <= '0';
				NS <= idle;
			when others => NS <= int;
		end case;
	end process;

end RTL;
