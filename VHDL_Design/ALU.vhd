-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_signed.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity alu is port(
	a : in std_logic_vector(31 downto 0);
    b : in std_logic_vector(31 downto 0);
    control: in std_logic_vector(2 downto 0);
    result : out std_logic_vector(31 downto 0);
    z : out std_logic);
end alu;

architecture logic of alu is
 
 --signals
 signal set: std_logic_vector(31 downto 0);
 signal r : std_logic_vector(31 downto 0);

	

begin
	
  set <= x"00000001" when (a < b) else x"00000000";
  
  pro: process (a,b,control)
  begin
    case control is 
          when "000" => r <= a and b ;
          when "001" => r <= a or b ;
          when "010" => r <= a + b ;
          when "110" => r <= a - b ;

                  --(a < b) when sel = "111", NO NOS SIRVE,  (a < b) devuelve un bit

                  --"1" when sel = "111" and (a < b),
                  --"0" when sel = "111" and not(a < b),

          when "111" => r <= set ;
          when "100" => r <= b(15 downto 0) & x"0000" ;
          when others => r <= x"00000000" ; 
    end case;
  end process;

	z <= '1' when r = x"00000000" else '0';
    
    result <= r;

end logic;
