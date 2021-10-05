library ieee;				
use ieee.std_logic_1164.all; 


entity ss_decoder is
port(
	ssd_in :in std_logic_vector(3 downto 0);
	ssd_out:out std_logic_vector(6 downto 0)
	);
END ss_decoder;

architecture arc of ss_decoder is
begin
	ssd_out <=  "1000000" when ssd_in = "0000" else 
					"1111001" when ssd_in = "0001" else 
					"0100100" when ssd_in = "0010" else 
					"0110000" when ssd_in = "0011" else 
					"0011001" when ssd_in = "0100" else 
					"0010010" when ssd_in = "0101" else 
					"0000010" when ssd_in = "0110" else 
					"1111000" when ssd_in = "0111" else 
					"0000000" when ssd_in = "1000" else 
					"0011000" when ssd_in = "1001" else 
					"0001000" when ssd_in = "1010" else 
					"0000011" when ssd_in = "1011" else 
					"1000110" when ssd_in = "1100" else 
					"0100001" when ssd_in = "1101" else 
					"0000110" when ssd_in = "1110" else 
					"0001110" when ssd_in = "1111" else 
					"1000000";


end arc;
