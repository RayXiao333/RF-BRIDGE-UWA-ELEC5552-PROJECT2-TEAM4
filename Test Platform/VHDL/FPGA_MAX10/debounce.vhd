LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debounce is
	port(
				Clock 	:in std_logic; --50MHz clock
				button	:in std_logic;	--noisy signal
				debounce	:buffer std_logic
	);
end debounce;

architecture arc of debounce is

	signal count :std_logic_vector(2 downto 0);
	signal done, counting :std_logic;

begin 
	process
	begin 
		wait until clock'event and clock = '1';
		if(done = '1' and button = '1')then
			debounce <= '0';
		elsif(button = '0') then
			debounce <= '1';
		end if;
	end process;
	
	process
	begin 
		wait until clock'event and clock = '1';
		if(done = '1')then
			count <= "000";
		elsif(debounce = '1')then
			count <= count + '1';
		end if;
	end process;
	
	done <= '1' when count = "111" else '0'; 

end arc;
