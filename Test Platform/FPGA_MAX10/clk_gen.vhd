library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity clk_gen is
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
end clk_gen;

architecture arc of clk_gen is
		
		--to_unsigned( integer, length_of_bits) ie. (4, 3) = 100
		constant RATE_HIGH :std_logic_vector(GENBITS-1 downto 0) := std_logic_vector(to_unsigned(high_rate_cnt, GENBITS));
		constant RATE_LOW :std_logic_vector(GENBITS-1 downto 0) := std_logic_vector(to_unsigned(low_rate_cnt, GENBITS));

		signal rate_control: std_logic_vector(GENBITS-1 downto 0) := (others=> '0');
		signal clk_in_count: std_logic_vector(GENBITS-1 downto 0) := (others=> '0');
		signal int_clk :std_logic :='0';		
begin
		rate_control <= RATE_HIGH when (rate='1') else RATE_LOW;
		
		CLK_IN_CTR: Process(rst_L, clk_in, clk_in_count, int_clk)
		begin
				if(rst_L='1') then
					int_clk <='0';
					clk_in_count <= (others => '0');
				elsif(clk_in'event and clk_in = '1') then
					if clk_in_count = rate_control then
						clk_in_count <= (others => '0');		--force cnt to 0 for case and not in case;
						int_clk <= not int_clk;
					else
						clk_in_count <= clk_in_count+1;
						int_clk <= int_clk;
					end if;
				else
					clk_in_count <= clk_in_count;
					int_clk <= int_clk;
				end if;
				
				clk <= int_clk;
				
		end process;
		
		
end arc;