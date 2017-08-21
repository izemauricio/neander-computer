-- Mauricio Ize 273168
-- Cindy Evelyn Peterson 219155

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY NEANDER IS
	PORT ( 
		clock : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		halt : out std_logic;
		acumulador : out  STD_LOGIC_VECTOR (7 downto 0)
	);
END NEANDER;

ARCHITECTURE Behavioral OF NEANDER IS

	-- BRAM
	COMPONENT RAM
		PORT (
			clka : IN STD_LOGIC;
			ena : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			
			clkb : IN STD_LOGIC;
			enb : IN STD_LOGIC;
			web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			dinb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;
	
	-- DATA BUS
	signal PC : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal DADO : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal OPCODE : STD_LOGIC_VECTOR(3 DOWNTO 0);
	signal ACC : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal ULA : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal NZ_OUT : STD_LOGIC_VECTOR(1 DOWNTO 0);
	signal ULA_Z_OUT : STD_LOGIC;
	signal ULA_N_OUT : STD_LOGIC;
	-- -- bram addr b
	signal DINB : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal ADDRB : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal WEB : STD_LOGIC_VECTOR(0 DOWNTO 0);
	signal MEMOUT_B : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- CONTROL BUS
	signal ENA,ENB : STD_LOGIC;
	signal CARGA_OPCODE : STD_LOGIC;
	signal CARGA_ACC : STD_LOGIC;
	signal CARGA_PC : STD_LOGIC;
	signal CARGA_NZ : STD_LOGIC;
	signal MUX_SEL : STD_LOGIC;
	signal ULA_SEL : STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal INCREMENTA_PC : STD_LOGIC;
	signal RAM_WRITE : STD_LOGIC_VECTOR(0 DOWNTO 0);
	
	-- MUL
	signal set_mux_100 : std_logic;
	signal set_acc_msb : std_logic;
	
	signal ula_mul_step : std_logic;
	signal result : std_logic_vector(15 downto 0);
	signal mul_lsb : std_logic_vector(7 downto 0);
	signal mul_msb : std_logic_vector(7 downto 0);
	

	
	-- STATE MACHINE
	type state_type is (t0,t1,t2,t3,t4,t5,t6,t7,tHALT,t1a,t4a,tMul0,tMul3,tMul1,tMul2);
	signal ATUAL_S, NEXT_S: state_type;

BEGIN

	-- BRAM
	MYRAM : RAM
		PORT MAP (
			clka => clock,
			ena => ENA,
			wea => RAM_WRITE,
			addra => ADDR,
			dina => ACC,
			douta => DADO,

			clkb => clock,
			enb => ENB,
			web => WEB,
			addrb => ADDRB,
			dinb => DINB,
			doutb => MEMOUT_B
		);
		
		
		
		

	-- MUX (COMBINACIONAL MUX)
	process(MUX_SEL,PC,DADO,set_mux_100)
	begin
		if (set_mux_100 = '1') then
			ADDR <= "01100100";
		else
			if (MUX_SEL='0') then
				ADDR <= PC;
			elsif (MUX_SEL='1') then
				ADDR <= DADO;
			end if;
		end if;
	end process;
	
	-- ACC (SEQUENCIAL 8 BITS REGISTER)
	process(clock,reset,set_acc_msb)
	begin
		if (clock'event and clock='1') then
			if (reset='1') then
				ACC <= "00000000";
			else
				if (set_acc_msb = '1') then
					ACC <= mul_msb;
				else
					if (CARGA_ACC='1') then
						ACC <= ULA;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- ULA (COMBINACIONAL ULA)
	process(ACC, DADO, ULA_SEL,ula_mul_step)
	begin
		case ULA_SEL is
		
			-- LDA
			when "100" => 
				ULA <= DADO; 
			
			-- ADD
			when "000" => 
				ULA <= ACC + DADO; 
			
			-- AND
			when "001" => 
				ULA <= ACC and DADO; 
			
			-- OR
			when "010" => 
				ULA <= ACC or DADO; 
			
			-- NOT
			when "011" => 
				ULA <= NOT ACC; 
			
			-- MUL 
			when "101" => 
				if(ula_mul_step = '0') then
					result <= (ACC * DADO);
					
				elsif (ula_mul_step = '1') then
					ULA <= result(7 downto 0);
					mul_lsb <= result(7 downto 0); -- coloca o lsb no acc
					
					mul_msb	<= result(15 downto 8); -- coloca o msb no addr 100 da memoria
					
				end if;
				
			when OTHERS =>
				ULA <= "00000000";
				
		end case;
		
	end process;
	
	-- ULA N SIGNAL
	ULA_N_OUT <= not(ULA(0) or ULA(1) or ULA(2) or ULA(3) or ULA(4) or ULA(5) or ULA(6) or ULA(7));
	
	-- ULA Z SIGNAL
	process(ULA)
	begin
		if(ULA >= 128 and ULA <= 255) then
			ULA_Z_OUT <= '1';
		else
			ULA_Z_OUT <= '0';
		end if;
	end process;
	
	
	
	
	
	-- NZ (SEQUENCIAL 2 BITS REGISTER)
	process(clock,reset)
	begin
		if (clock'event and clock='1') then
			if (reset='1') then
				NZ_OUT <= "00";
			else
				if (CARGA_NZ='1') then
					NZ_OUT <= ULA_Z_OUT & ULA_N_OUT; -- NZ_OUI(0) = Z NZ_OUT(1) = N
				end if;
			end if;
		end if;
	end process;
	
	-- PC (SEQUENCIAL 8 BITS COUNTER)
	process(clock,reset)
	begin
		if (clock'event and clock='1') then
			if (reset='1') then
				PC <= "00000000";
			else
				if (CARGA_PC='1') then
					PC <= DADO;
				elsif (INCREMENTA_PC='1') then
					PC <= PC + 1;
				end if;
			end if;
		end if;
	end process;	
	
	
	
	
	-- OPCODE (SEQUENCIAL 8 BITS REGISTER)
	process(clock,reset)
	begin
		if (clock'event and clock='1') then
			if (reset='1') then
					OPCODE <= "0000";
			else
				if (CARGA_OPCODE='1') then
					OPCODE <= DADO(7 downto 4);
				end if;
			end if;
		end if;
	end process;
		
		
		
		
		
	-- STATE MACHINE CONTROLER
	process (clock,reset)
	begin
		if (reset='1') then
			ATUAL_S <= t0;
		elsif (rising_edge(clock)) then
			ATUAL_S <= NEXT_S;
		end if;
	end process;

	-- STATE MACHINE
	process (ATUAL_S,NZ_OUT,OPCODE)
	begin
	      INCREMENTA_PC <= '0';
			CARGA_PC <= '0';
			CARGA_NZ <= '0';
			ULA_SEL <= "111";
			CARGA_ACC <= '0';
			CARGA_OPCODE <= '0';
			MUX_SEL <= '0';
			RAM_WRITE <= "0";
			ENA <= '0';
			halt <= '0';
			
			set_mux_100 <= '0';
			set_acc_msb <= '0';
			ula_mul_step <= '0';
			
		case ATUAL_S is
		
		when t0 =>
			NEXT_S <= t1;
			MUX_SEL <= '0';
			
		when t1 =>
			NEXT_S <= t1a;
			RAM_WRITE <= "0";
			ENA <= '1';
			INCREMENTA_PC <= '1';	
			
		when t1a =>
			NEXT_S <= t2;
			
		when t2 =>
			NEXT_S <= t3;
			CARGA_OPCODE <= '1';
			
		when t3 =>
			NEXT_S <= t4;
			
		   if (OPCODE="0000") then -- NOP
				NEXT_S <= t0;
			elsif(OPCODE="0001") then --STA
				MUX_SEL <= '0';
			elsif(OPCODE="0010") then --LDA
				MUX_SEL <= '0';
			elsif(OPCODE="0011") then --ADD
				MUX_SEL <= '0';
			elsif(OPCODE="1100") then -- MUL
				MUX_SEL <= '0';
			elsif(OPCODE="0100") then --OR
				MUX_SEL <= '0';
			elsif(OPCODE="0101") then --AND
				MUX_SEL <= '0';
			elsif(OPCODE="0110") then --NOT
				NEXT_S <= t0;
				ULA_SEL <= "011";
				CARGA_ACC <= '1';
				CARGA_NZ <= '1';
			elsif(OPCODE="1000") then --JMP
				MUX_SEL <= '0';
			elsif(OPCODE="1001") then --JN 
				if(NZ_OUT = "10" or NZ_OUT = "11") then
					MUX_SEL <= '0';
				elsif(NZ_OUT = "01" or NZ_OUT = "00") then
					INCREMENTA_PC <= '1';
					NEXT_S <= t0;
				end if;
			elsif(OPCODE="1010") then --JZ
				if(NZ_OUT = "01" or NZ_OUT = "11") then
					MUX_SEL <= '0';
				elsif(NZ_OUT = "00" or NZ_OUT = "10") then
					INCREMENTA_PC <= '1';
					NEXT_S <= t0;
				end if;
			elsif(OPCODE="1111") then --HLT
					NEXT_S <= tHALT;
			end if;
		
		when t4 =>	
			NEXT_S <= t4a;
			
		   if(OPCODE="0001") then --STA
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';
			elsif(OPCODE="0010") then --LDA
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';	
				elsif(OPCODE="1100") then --MUL
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';
			elsif(OPCODE="0011") then --ADD
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';	
			elsif(OPCODE="0100") then --OR
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';	
			elsif(OPCODE="0101") then --AND
				RAM_WRITE <= "0";
				ENA <= '1';
				INCREMENTA_PC <= '1';	
			elsif(OPCODE="1000") then --JMP
				RAM_WRITE <= "0";
				ENA <= '1';
			elsif(OPCODE="1001") then --JN
				if(NZ_OUT = "10" or NZ_OUT = "11") then
					RAM_WRITE <= "0";
					ENA <= '1';
				end if;
			elsif(OPCODE="1010") then --JZ
				if(NZ_OUT = "01" or NZ_OUT = "11") then
					RAM_WRITE <= "0";
					ENA <= '1';
				end if;
			end if;
		
			when t4a =>	
				NEXT_S <= t5;
		
		when t5 =>
			NEXT_S <= t6;
			
			if(OPCODE="0001") then --STA
				RAM_WRITE <= "1";
				ENA <= '1';
				MUX_SEL <= '1';
			elsif(OPCODE="0010") then --LDA
				RAM_WRITE <= "0";
				ENA <= '1';
				MUX_SEL <= '1';
			elsif(OPCODE="1100") then -- MUL
				MUX_SEL <= '1';
				RAM_WRITE <= "0";
				ENA <= '1';
			elsif(OPCODE="0011") then --ADD
				MUX_SEL <= '1';
				RAM_WRITE <= "0";
				ENA <= '1';
			elsif(OPCODE="0100") then --OR
				RAM_WRITE <= "0";
				ENA <= '1';
				MUX_SEL <= '1';
			elsif(OPCODE="0101") then --AND
				RAM_WRITE <= "0";
				ENA <= '1';
				MUX_SEL <= '1';
			elsif(OPCODE="1000") then --JMP
				CARGA_PC <= '1';
				NEXT_S <= t0;
			elsif(OPCODE="1001") then --JN
				if(NZ_OUT = "10" or NZ_OUT = "11") then -- 1 & 0 = 10 ou 01?
					CARGA_PC <= '1';
					NEXT_S <= t0;
				end if;		
			elsif(OPCODE="1010") then --JZ			
				if(NZ_OUT = "01" or NZ_OUT = "11") then
					CARGA_PC <= '1';
					NEXT_S <= t0;
				end if;
			end if;
		
		when t6 =>	
			NEXT_S <= t7;
			
		when t7 =>
			NEXT_S <= t0;
			
			if(OPCODE="0001") then --STA
				NEXT_S <= t0;	
			elsif(OPCODE="0010") then --LDA
				ULA_SEL <= "100";
				CARGA_NZ <= '1';
				CARGA_ACC <= '1';
				NEXT_S <= t0;	
			elsif(OPCODE="1100") then -- MUL
				NEXT_S <= tMul0;
				
				ULA_SEL <= "101";
				ula_mul_step <= '0';
				
			elsif(OPCODE="0011") then --ADD
				ULA_SEL <= "000";
				CARGA_NZ <= '1';
				CARGA_ACC <= '1';
				NEXT_S <= t0;
			elsif(OPCODE="0100") then --OR
				ULA_SEL <= "010";
				CARGA_NZ <= '1';
				CARGA_ACC <= '1';
				NEXT_S <= t0;
			elsif(OPCODE="0101") then --AND
				ULA_SEL <= "001";
				CARGA_NZ <= '1';
				CARGA_ACC <= '1';
				NEXT_S <= t0;
			end if;
			
			
			
			when tMul0 =>
				NEXT_S <= tMul1;
				
				ULA_SEL <= "101";
				CARGA_NZ <= '1';
				ula_mul_step <= '1';
				
			when tMul1 =>
				NEXT_S <= tMul2;
				
				set_acc_msb <= '1';
				set_mux_100 <= '1';
				
			when tMul2 =>
				NEXT_S <= tMul3;
				
				set_acc_msb <= '1';
				set_mux_100 <= '1';
				
				RAM_WRITE <= "1";
				ENA <= '1';
				
			when tMul3 =>
				NEXT_S <= t0;
				
				ULA_SEL <= "101";
				CARGA_NZ <= '1';
				ula_mul_step <= '1';
				CARGA_ACC <= '1';
				
				
				
			when tHALT =>
				NEXT_S <= tHALT;
				
				halt <= '1';
		
				INCREMENTA_PC <= '0';
				CARGA_PC <= '0';
				CARGA_NZ <= '0';
				ULA_SEL <= "000";
				CARGA_ACC <= '0';
				CARGA_OPCODE <= '0';
				MUX_SEL <= '0';
				RAM_WRITE <= "0";
				ENA <= '0';
				
		end case;

	end process;

	acumulador <= ACC;
	
END Behavioral;