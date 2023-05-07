library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity processor is
port(
	Clk         : in  std_logic;
	Reset       : in  std_logic;
	
    -- Instruction memory
	I_Addr      : out std_logic_vector(31 downto 0);
	I_RdStb     : out std_logic;
	I_WrStb     : out std_logic;
	I_DataOut   : out std_logic_vector(31 downto 0);
	I_DataIn    : in  std_logic_vector(31 downto 0);
	
    -- Data memory
	D_Addr      : out std_logic_vector(31 downto 0);
	D_RdStb     : out std_logic;
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end processor;

architecture processor_arq of processor is 

--signals IF

signal pc_src: std_logic;  						--selector entre next_mem y pc+4
signal reg_pc: std_logic_vector(31 downto 0); 	--registro PC
signal pc_add_4: std_logic_vector(31 downto 0); --PC+4
signal next_mem: std_logic_vector(31 downto 0); --dirección para el PC que viene de la etapa MEM
signal next_pc: std_logic_vector(31 downto 0); 	--entrada entre el multiplexor y el PC
signal IF_ID_inst: std_logic_vector(31 downto 0); --resgistro que almacena la instrucción
signal IF_ID_addr: std_logic_vector(31 downto 0); --registro que almacena la dirección del PC+4


--signals ID
 
-- señales del registro pipeline
signal ID_EXE_inst: std_logic_vector(31 downto 0);
signal ID_EXE_alu_op: std_logic_vector(1 downto 0);
signal ID_EXE_reg_dst: std_logic; 
signal ID_EXE_alu_src: std_logic;
signal ID_EXE_mem_read: std_logic;
signal ID_EXE_mem_to_reg: std_logic;
signal ID_EXE_mem_write: std_logic;
signal ID_EXE_reg_write: std_logic;

signal extended_inmediato:std_logic_vector(31 downto 0);

component unidadControl is port(
    instruccion : in std_logic_vector(5 downto 0);
    
    alu_op: out std_logic_vector(1 downto 0);
    branch: out std_logic;
    reg_dst: out std_logic;
    mem_read: out std_logic;
    mem_to_reg: out std_logic;
    mem_write: out std_logic;
    alu_src: out std_logic;
    reg_write: out std_logic);
end component;

--señales que salen de la unidad de control	
signal unidad_alu_op : std_logic_vector(1 downto 0);
signal unidad_reg_dst: std_logic;
signal unidad_mem_read: std_logic;
signal unidad_mem_to_reg: std_logic;
signal unidad_mem_write: std_logic;
signal unidad_alu_src: std_logic;
signal unidad_reg_write: std_logic;
signal branch : std_logic;

component Register_32b is port(
	clk,reset,wr: in std_logic;
    reg1_rd,reg2_rd,reg_wr: in std_logic_vector(4 downto 0);
    data_wr: in std_logic_vector(31 downto 0);
    data1_rd,data2_rd: out std_logic_vector(31 downto 0));
end component;

signal data1_rd : std_logic_vector(31 downto 0);
signal data2_rd : std_logic_vector(31 downto 0);

signal comparacion_beq : std_logic; --Se resta reg1_rd con reg2_rd y si queda 0 esta señal se vuelve 1 sino 0

--signals EXE
signal ID_EXE_data1_rd :  std_logic_vector(31 downto 0);
signal ID_EXE_data2_rd :  std_logic_vector(31 downto 0);

signal ID_EXE_rt: std_logic_vector(4 downto 0);
signal ID_EXE_rd: std_logic_vector(4 downto 0);
signal reg_destino: std_logic_vector(4 downto 0);

component alu is port(
    a : in std_logic_vector(31 downto 0);
    b : in std_logic_vector(31 downto 0);
    control: in std_logic_vector(2 downto 0);
    result : out std_logic_vector(31 downto 0);
    z : out std_logic);
end component;

signal entrada_b_alu : std_logic_vector(31 downto 0);
signal salida_z_alu : std_logic;
signal resultado_alu : std_logic_vector(31 downto 0);
signal alu_control_out : std_logic_vector(2 downto 0);

component AluControl is port(
    inm_5_to_0 : in std_logic_vector(5 downto 0);
    alu_op: in std_logic_vector(1 downto 0);
    alu_control_out : out std_logic_vector(2 downto 0));
end component;

--signal MEM
signal EXE_MEM_reg_destino : std_logic_vector(4 downto 0);
signal EXE_MEM_resultado_alu : std_logic_vector(31 downto 0);
signal EXE_MEM_data2_rd : std_logic_vector(31 downto 0);
signal EXE_MEM_mem_read : std_logic;
signal EXE_MEM_mem_to_reg : std_logic;
signal EXE_MEM_mem_write : std_logic;
signal EXE_MEM_reg_write : std_logic;

component memory is Port ( 
	Addr : in std_logic_vector(31 downto 0);
	DataIn : in std_logic_vector(31 downto 0);
  	RdStb : in std_logic ;
   	WrStb : in std_logic ;
	Clk : in std_logic ;						  
	DataOut : out std_logic_vector(31 downto 0));
end memory;

--signals WB

signal MEM_WB_reg_write: std_logic;
signal MEM_WB_mem_to_reg: std_logic;
signal MEM_WB_data_out: std_logic_vector(31 downto 0);
signal MEM_WB_resultado_alu: std_logic_vector(31 downto 0);
signal MEM_WB_reg_destino : std_logic_vector(4 downto 0);

signal MEM_WB_data_wr : std_logic_vector(31 downto 0);

--------------------------------------------------------------  
begin 	

--Sección IF

process(Clk, Reset) --proceso que maneja el registro PC y el registro IF_ID_inst y el registro IF_ID_addr con reset asíncrono con activo en alto y flanco alto de reloj
begin
	if (Reset = '1') then 
    	reg_pc <= x"00000000";
        IF_ID_inst <= x"00000000";
        IF_ID_addr <= x"00000000";
    elsif
    	rising_edge(Clk) then
        	reg_pc <= next_pc;
        if (pc_src = '1') then 
        	IF_ID_inst <= x"00000000";
        	IF_ID_addr <= x"00000000";
        else 
	    	IF_ID_inst <= I_DataIn;     --guardamos la instrucción que sale de la memoria de instrucciones
	        IF_ID_addr <= pc_add_4;
    	end if;
    end if;
end process;

next_pc <= pc_add_4 when pc_src = '0' else next_mem; 	--multiplexor que rige la entrada del PC
I_Addr <= reg_pc; 						--la memoria obtiene el valor de la señal reg_pc
I_RdStb <= '1'; 			--siempre leemos
I_WrStb <= '0';				--nunca escribimos en la memoria de instrucción

-- I_DataOut no es necesario setearlo porque nunca escribimos!!

pc_add_4 <= reg_pc + 4;

--Sección ID ---------------------------------------------------------



extended_inmediato <= (x"0000" & IF_ID_inst(15 downto 0))  when (IF_ID_inst(15) = '0') else (x"1111" & IF_ID_inst(15 downto 0)); --extensión del inmediato

next_mem <= ((extended_inmediato(29 downto 0) & "00") + IF_ID_addr); --next_mem es el inmediato extendido * 4 + PC+4 próxima instrucción a leer si se salta

UnidadDeControl: unidadControl port map(    		-- unidad de control combinacional dada una isntrucción devuelve las señales
    instruccion => IF_ID_inst(31 downto 26),
    alu_op => unidad_alu_op,
    branch => branch,
    reg_dst => unidad_reg_dst,
    mem_read => unidad_mem_read,
    mem_to_reg => unidad_mem_to_reg,
    mem_write => unidad_mem_write,
    alu_src => unidad_alu_src,
    reg_write => unidad_reg_write
);

process (clk, Reset) 
begin
	if (Reset = '1') then		--si Reset = 1 ponemos todo en 0
    	 ID_EXE_alu_op <= "00";
         ID_EXE_reg_dst <= '0';
         ID_EXE_mem_read <= '0';
         ID_EXE_mem_to_reg <= '0';
         ID_EXE_mem_write <= '0';
         ID_EXE_alu_src <= '0';
         ID_EXE_reg_write <= '0';
         ID_EXE_inst <= x"00000000";
         ID_EXE_data1_rd <= x"00000000";
         ID_EXE_data2_rd <= x"00000000";
         ID_EXE_rt <= "00000";
         ID_EXE_rd <= "00000";

	elsif rising_edge(Clk) then
    	 ID_EXE_alu_op <= unidad_alu_op;
         ID_EXE_reg_dst <= unidad_reg_dst;
         ID_EXE_mem_read <= unidad_mem_read;
         ID_EXE_mem_to_reg <= unidad_mem_to_reg;
         ID_EXE_mem_write <= unidad_mem_write;
         ID_EXE_alu_src <= unidad_alu_src;
         ID_EXE_reg_write <= unidad_reg_write;
         ID_EXE_inst <= extended_inmediato;			--guardamos el inmediato para la próxima etapa
         ID_EXE_data1_rd <= data1_rd;				--guardamos los datos de la salida del banco de registros (data1 y data2)
		 ID_EXE_data2_rd <= data2_rd;
         ID_EXE_rt <= IF_ID_inst(20 downto 16);		--guardamos rt y rd para hacer el regdst en la próxima etapa
         ID_EXE_rd <= IF_ID_inst(15 downto 11);
   	end if;
end process;
     
BancoDeRegistros: Register_32b port map(
    	clk => Clk,
        reset => Reset,
        wr => MEM_WB_reg_write,   	--ESTE VIENE DE LA ETAPA WRITE BACKING el regWrite
        reg1_rd => IF_ID_inst(25 downto 21),
        reg2_rd => IF_ID_inst(20 downto 16),
        reg_wr => MEM_WB_reg_destino,	--ESTE VIENE DE LA ETAPA WRITE BACKING registro destino
        data_wr => MEM_WB_data_wr,	--ESTE VIENE DE LA ETAPA WRITE BACKING data to write
        data1_rd => data1_rd,
		data2_rd => data2_rd
);


--branch sección
comparacion_beq <= '1' when (data1_rd = data2_rd) else '0'; --hacemos la comparación
pc_src <= branch and comparacion_beq; 						--si branch y los registros son iguales saltamos

-- Sección EXE ---------------------------------------------------------------


reg_destino <= ID_EXE_rt when ID_EXE_reg_dst = '0' else ID_EXE_rd;

entrada_b_alu <= ID_EXE_data2_rd when ID_EXE_alu_src = '0' else ID_EXE_inst;

aluu: alu port map(    		
    a => ID_EXE_data1_rd,
    b => entrada_b_alu,
    control => alu_control_out,
    result => resultado_alu,
    z => salida_z_alu
);

alucontroll: AluControl port map(		-- unidad de control combinacional dada una isntrucción devuelve las señales		
    inm_5_to_0 => ID_EXE_inst(5 downto 0),
    alu_op => ID_EXE_alu_op,
    alu_control_out => alu_control_out
);

process (clk, Reset) 
begin
	if (Reset = '1') then		--si Reset = 1 ponemos todo en 0
        EXE_MEM_reg_destino <= "00000"; 
		EXE_MEM_resultado_alu <= x"00000000";
        EXE_MEM_data2_rd <= x"00000000";
        EXE_MEM_mem_read <= '0';
        EXE_MEM_mem_to_reg <= '0';
        EXE_MEM_mem_write <= '0';
        EXE_MEM_reg_write <= '0';
	elsif rising_edge(Clk) then
		EXE_MEM_reg_destino <= reg_destino; 
		EXE_MEM_resultado_alu <= resultado_alu;
        EXE_MEM_data2_rd <= ID_EXE_data2_rd;
        EXE_MEM_mem_read <= ID_EXE_mem_read;
        EXE_MEM_mem_to_reg <= ID_EXE_mem_to_reg;
        EXE_MEM_mem_write <= ID_EXE_mem_write;
        EXE_MEM_reg_write <= ID_EXE_reg_write;
    end if;
end process;
 
-- Sección MEM --------------------------------------------------------------- 

D_Addr <= EXE_MEM_resultado_alu;
D_RdStb <= EXE_MEM_mem_read;
D_WrStb <= EXE_MEM_mem_write;
D_DataOut <= EXE_MEM_data2_rd;
MEM_WB_data_out <= D_DataIn;

process (clk, Reset) 
begin
	if (Reset = '1') then		--si Reset = 1 ponemos todo en 0
        MEM_WB_reg_destino <= "00000"; 
        MEM_WB_mem_to_reg <= '0';
        MEM_WB_reg_write <= '0';
        MEM_WB_resultado_alu <= x"00000000";
	elsif rising_edge(Clk) then
		MEM_WB_reg_destino <= EXE_MEM_reg_destino; 
        MEM_WB_mem_to_reg <= EXE_MEM_mem_to_reg;
        MEM_WB_reg_write <= EXE_MEM_reg_write;
        MEM_WB_resultado_alu <= EXE_MEM_resultado_alu;
	end if;
end process;
 
-- Sección WB ---------------------------------------------------------------  
 
MEM_WB_data_wr <= MEM_WB_data_out when MEM_WB_mem_to_reg = '1' else MEM_WB_resultado_alu;
 
-- FIN ---------------------------------------------------------------  
 
 
end processor_arq;
