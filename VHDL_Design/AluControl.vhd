library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity AluControl is port(
    inm_5_to_0 : in std_logic_vector(5 downto 0);
    alu_op: in std_logic_vector(1 downto 0);
    
    alu_control_out : out std_logic_vector(2 downto 0)
);

end AluControl;

architecture AluControl_arch of AluControl is

begin

process (inm_5_to_0, alu_op)
begin
          if alu_op = "00" then	  --suma
             alu_control_out <= "010";
          elsif alu_op = "01" then    --resta
            alu_control_out <= "110";
		  elsif alu_op = "11" then    --lui
            alu_control_out <= "100";
          elsif alu_op = "10" then	--tipo R
              if inm_5_to_0 = "100000" then
                  alu_control_out <= "010";
              elsif inm_5_to_0 = "100010" then
                  alu_control_out <= "110";
              elsif inm_5_to_0 = "100100" then
                  alu_control_out <= "001";
              elsif inm_5_to_0 = "100101" then
                  alu_control_out <= "000";
              elsif inm_5_to_0 = "101010" then
                  alu_control_out <= "111";
              else alu_control_out <= "010"; --si no sabe suma
              end if;
          else alu_control_out <= "010"; --si no sabe suma
          end if;
end process;
     

end AluControl_arch;


