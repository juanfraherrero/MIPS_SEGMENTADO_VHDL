library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.numeric_std.all;

entity unidadControl is port(
    instruccion : in std_logic_vector(5 downto 0);
    
    alu_op: out std_logic_vector(1 downto 0);
    branch: out std_logic;
    reg_dst: out std_logic;
    mem_read: out std_logic;
    mem_to_reg: out std_logic;
    mem_write: out std_logic;
    alu_src: out std_logic;
    reg_write: out std_logic
);
end unidadControl;

architecture unidadControl_arch of unidadControl is

begin

process (instruccion)
begin
          if (instruccion = "000000") then
             alu_op <= "10";
             branch <= '0';
             reg_dst <= '1';
             mem_read <= '0';
             mem_to_reg <= '0';
             mem_write <= '0';
             alu_src <= '0';
             reg_write <= '1';
          elsif (instruccion = "100011") then	-- load word 
             branch <= '0';
             reg_dst <= '0';
             mem_read <= '1';
             mem_to_reg <= '1';
             mem_write <= '0';
             alu_src <= '1';
             reg_write <= '1'; 
             alu_op <= "00";
          elsif instruccion = "101011" then	--- store word 
             branch <= '0';
             reg_dst <= 'X';
             mem_read <= '0';
             mem_to_reg <= 'X';
             mem_write <= '1';
             alu_src <= '1';
             reg_write <= '0'; 
             alu_op <= "00";
          elsif instruccion = "000100" then			--- BEQ
             branch <= '1';
             reg_dst <= 'X';
             mem_read <= '0';
             mem_to_reg <= 'X';
             mem_write <= '0';
             alu_src <= '1';
             reg_write <= '0'; 
             alu_op <= "01";
          elsif instruccion = "001111" then			--- Lui
             branch <= '0';
             reg_dst <= '0';
             mem_read <= '0';
             mem_to_reg <= '0';
             mem_write <= '0';
             alu_src <= '1';
             reg_write <= '1'; 
             alu_op <= "11";           
           else									--si no coincide con ninguna instrucción es un nop
             branch <= '0';
             reg_dst <= '0';
             mem_read <= '0';
             mem_to_reg <= '0';
             mem_write <= '0';
             alu_src <= '0';
             reg_write <= '0'; 
             alu_op <= "00";
           end if;
end process;
     

end unidadControl_arch;


