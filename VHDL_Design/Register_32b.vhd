library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Register_32b is port(
	clk,reset,wr: in std_logic;
    reg1_rd,reg2_rd,reg_wr: in std_logic_vector(4 downto 0);
    data_wr: in std_logic_vector(31 downto 0);
    data1_rd,data2_rd: out std_logic_vector(31 downto 0)
);
end Register_32b;

architecture registers_arch of Register_32b is

type t_reg is ARRAY (0 to 31) of std_logic_vector(31 downto 0);
signal regs:t_reg;

begin

	process(reset,clk)
    begin
    	if (reset = '1') then
        	regs <= (others => x"00000000");
        elsif (falling_edge(clk) and wr = '1') then
        	regs(to_integer(unsigned(reg_wr))) <= data_wr;
        end if;
    end process;
    
    data1_rd <= (others => '0') when reg1_rd = "00000" else regs(to_integer(unsigned(reg1_rd)));
    data2_rd <= (others => '0') when reg2_rd = "00000" else regs(to_integer(unsigned(reg2_rd)));

end registers_arch;