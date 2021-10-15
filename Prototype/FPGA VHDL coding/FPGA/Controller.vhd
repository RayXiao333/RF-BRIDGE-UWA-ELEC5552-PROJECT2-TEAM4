library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity Controller is
  port (
		CTS_X, CTS_C 	:in std_logic;
		Reset, clk		:in std_logic;
		rx_dv,tx_ac		:in std_logic;
		fifo_f, fifo_e	:in std_logic;
		wr_en, rd_en	:out std_logic;
		tx_dv				:out std_logic;
		RTS_X, RTS_C	:out std_logic
		--wr_byte, rd_byte 	:in std_logic_vector(7 downto 0)
    );
end entity Controller;
 
architecture RTL of Controller is

  type state_type is (rx,int, idle);
  SIGNAL PS, NS :state_type;
  
  -- For tx
  type state_type_tx is (tx, int, tx_ready, idle, tx_done);
  SIGNAL PS_T, NS_T :state_type_tx;

begin 

	syn: process(clk)
	begin 
		if(Reset='1')then 
			PS <= int;
			PS_T <= int;
		else
			if(clk'event and clk='1')then
				PS <= NS;
				PS_T <= NS_T;
			else
				PS <= PS;
				PS_T <= PS_T;
			end if;
		end if;
	end process;
		
	rx_xport_pro: process(PS)
	begin 
		Case PS is 
			--Initialize state
			when int =>
				wr_en <= '0';
				NS <= idle;
			-- do nothing but reset rd and wr
			when idle =>
				wr_en <= '0';
				if fifo_f = '1' then	--fifo full, tell XPORT stop send
					RTS_X <= '1';
					NS <= idle;
				else 
					RTS_X <= '0';		--FIFO not full, tell XPORT continue send
--					if CTS_X = '0' then 
						NS <= rx;
--					else NS <= idle;
--					end if;
				end if;
			-- active Fifo to load
			when rx =>
				if rx_dv = '1' then
					wr_en <= '1';
--					NS <= rx_done;
--				else NS<= idle;
					NS<= idle;
				else NS<= rx;
				end if;
			-- deactive fifo after 1 period
--			when rx_done => 
--				wr_en <= '0';
--				NS <= idle;
			when others => NS <= int;
		end case;
	end process;
	
	tx_cc1310_pro: process(PS_T)
	begin 
		case PS_T is
			--Initialize state
			when int =>
				rd_en <= '0';
				tx_dv <= '0';
				NS_T <= idle;
			when idle =>
				rd_en <= '0';
				tx_dv <= '0';
				if fifo_e /= '1' then
					if CTS_C = '0' then NS_T <= tx_ready; --CC1310 SAY THEY ARE READY
					else NS_T <= idle; END IF;
				else 
					NS_T <= idle;
				end if;
			-- Active fifo to pull data
			when tx_ready =>
				rd_en <= '1';
				tx_dv <= '0';
				NS_T <= tx;
			-- Active tx to send first
			when tx =>
				rd_en <= '0';
				tx_dv <= '1';
				NS_T <= tx_done;
			when tx_done => 
				if (tx_ac /= '1') then	
					tx_dv <= '0';
					NS_T <= idle;
				else NS_T <= tx_done;
				end if;
			when others => NS_T <= int;
		end case;
	end process; 
	
	--Tell CC1310 stop send message, if XPORT refuse send (CTS_X HIGH). 
	flow_con: PROCESS(CTS_X)
	begin 
		if CTS_X = '0' then 
			RTS_C <= '1';
		else 
			RTS_C <='0';
		end if;
	end process;

end RTL;
