library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PLACA is
	Port (
		clock : in  STD_LOGIC;

		display : out  STD_LOGIC_VECTOR (7 downto 0); -- 11111111 = PGFEDCBA
		anode : out  STD_LOGIC_VECTOR (3 downto 0); -- 1111 = f12 j12 m13 k14
		led : out  STD_LOGIC_VECTOR (7 downto 0); -- 11111111 = g1 p4 n4 n5 p6 p7 m11 m5
		
		button : in  STD_LOGIC_VECTOR (3 downto 0);
		switch : in  STD_LOGIC_VECTOR (7 downto 0) -- 11111111 = n3 e2 f3 g3 b4 k3 l3 p11
	);
end PLACA;

architecture Behavioral of PLACA is

	signal reset : STD_LOGIC;
	
	-- para guardar o dado no formato binarioo
	signal theByte : STD_LOGIC_VECTOR (7 downto 0);
	
	-- para guardar o dado no formato bcd
	signal mybcd : STD_LOGIC_VECTOR (11 downto 0);
	signal myuni : STD_LOGIC_VECTOR (3 downto 0);
	signal mydec : STD_LOGIC_VECTOR (3 downto 0);
	signal mycen : STD_LOGIC_VECTOR (3 downto 0);
	
	-- para guardar o dado no formato 7seg
	signal display1 :   STD_LOGIC_VECTOR (7 downto 0);
	signal display2 :   STD_LOGIC_VECTOR (7 downto 0);
	signal display3 :   STD_LOGIC_VECTOR (7 downto 0);

	signal counter : STD_LOGIC_VECTOR (31 downto 0);
	type state_type2 is (t0,t1,t2);
	signal ATUAL_S2, NEXT_S2: state_type2;
	
	-- NEANDER COMPONENT
	COMPONENT NEANDER
		PORT (
			clock : in  STD_LOGIC;
			reset : in  STD_LOGIC;
			halt : out std_logic;
			acumulador : out  STD_LOGIC_VECTOR (7 downto 0)
		);
	END COMPONENT;
	
	-- debounched button as clock2
	signal clock2 : STD_LOGIC;
	SIGNAL SHIFT_PB : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL debouncedButton     :    STD_LOGIC;
	SIGNAL theButton     :    STD_LOGIC;
	signal lastButtonState    : std_logic := '0';
	
begin 

	-- MYNEANDER
	MYNEANDER : NEANDER
		PORT MAP (
			clock => clock2,
			reset => reset,
			halt => led(1),
			acumulador => theByte
		);
		
		
	-- clock2 = 50,000,000 Hz to 2 Hza
	
	
		
	-- debounched button as clock2
	theButton <= button(1);
	
	process 
	begin
	  wait until (clock'event) and (clock = '1');
			SHIFT_PB(2 Downto 0) <= SHIFT_PB(3 Downto 1);
			SHIFT_PB(3) <= NOT theButton;
			If SHIFT_PB(3 Downto 0)="0000" THEN
			  debouncedButton <= '1';
			ELSE 
			  debouncedButton <= '0';
			End if;
	end process;
	
	process (clock,reset)
	begin
		if (clock'event and clock='1') then
			if(debouncedButton = '1' and lastButtonState = '0') then 
				clock2 <= debouncedButton;
			else
				clock2 <= '0';
			end if;
			lastButtonState <= debouncedButton;
		end if;
	end process;

	-- setup inicial
	reset <= button(0);
	-- clock2 <= button(1) debounced!
	-- theByte <= acc do neander
	
	led(0) <= reset;
	led(7 downto 2) <= "000000";
	
	-- CONVERT 8BITS TO 3x BCD
	process(theByte)
	
		variable i : integer:=0;
		variable temp : std_logic_vector(7 downto 0) := theByte;
		variable bcd : std_logic_vector(11 downto 0) := (others => '0');

	begin

		bcd := B"000000000000";
		temp := theByte;

		for i in 0 to 7 loop
		
			-- shit bcd
			bcd(11 downto 1) := bcd(10 downto 0);
			bcd(0) := temp(7);

			-- shit temp
			temp(7 downto 1) := temp(6 downto 0);
			temp(0) := '0';

			-- add 3 se coluna > 4
			if(i < 7 and bcd(3 downto 0) > "0100") then
				bcd(3 downto 0) := bcd(3 downto 0) + "0011";
			end if;	

			-- add 3 se coluna > 4
			if(i < 7 and bcd(7 downto 4) > "0100") then
				bcd(7 downto 4) := bcd(7 downto 4) + "0011";
			end if;

			-- add 3 se coluna > 4
			if(i < 7 and bcd(11 downto 8) > "0100") then
				bcd(11 downto 8) := bcd(11 downto 8) + "0011";
			end if;

		end loop;

		--cen <= bcd(11 downto 8);
		--dez <= bcd(7  downto 4);
		--uni <= bcd(3  downto 0);	
		-- saida <= "00" & bcd(11 downto 0);
		mybcd <= bcd;
		mycen <= bcd(11 downto 8);
		mydec <= bcd(7  downto 4);
		myuni <= bcd(3  downto 0);	
	end process;

	-- BCD to 7SEGMENT para UNIDADE, DEZENA e CENTENA
	process(mycen,mydec,myuni)
	begin
	
		case myuni is
			when "0000"=> display1 <="11000000";  -- '0'
			when "0001"=> display1 <="11111001";  -- '1' 
			when "0010"=> display1 <="10100100";  -- '2' 
			when "0011"=> display1 <="10110000";  -- '3' 
			when "0100"=> display1 <="10011001";  -- '4' 
			when "0101"=> display1 <="10010010";  -- '5' 
			when "0110"=> display1 <="10000010";  -- '6' 
			when "0111"=> display1 <="11111000";  -- '7' 
			when "1000"=> display1 <="10000000";  -- '8'
			when "1001"=> display1 <="10010000";  -- '9' 
			when others=> display1 <="01111111";
		end case;
	
		case mydec is
			when "0000"=> display2 <="11000000";  -- '0'
			when "0001"=> display2 <="11111001";  -- '1' 
			when "0010"=> display2 <="10100100";  -- '2' 
			when "0011"=> display2 <="10110000";  -- '3' 
			when "0100"=> display2 <="10011001";  -- '4' 
			when "0101"=> display2 <="10010010";  -- '5' 
			when "0110"=> display2 <="10000010";  -- '6' 
			when "0111"=> display2 <="11111000";  -- '7' 
			when "1000"=> display2 <="10000000";  -- '8'
			when "1001"=> display2 <="10010000";  -- '9' 
			when others=> display2 <="01111111";
		end case;
	
		case mycen is
			when "0000"=> display3 <="11000000";  -- '0'
			when "0001"=> display3 <="11111001";  -- '1' 
			when "0010"=> display3 <="10100100";  -- '2' 
			when "0011"=> display3 <="10110000";  -- '3' 
			when "0100"=> display3 <="10011001";  -- '4' 
			when "0101"=> display3 <="10010010";  -- '5' 
			when "0110"=> display3 <="10000010";  -- '6' 
			when "0111"=> display3 <="11111000";  -- '7' 
			when "1000"=> display3 <="10000000";  -- '8'
			when "1001"=> display3 <="10010000";  -- '9' 
			when others=> display3 <="01111111";
		end case;
	
	end process;

	-- maquina de estado para exibir o visor
	process (clock,reset)
	begin
		if (reset='1') then
			ATUAL_S2 <= t0;
			counter <= (others => '0');
		else
			if(clock'event and clock='1') then
				if(counter = "11001011011100110101") then -- divide a frequencia de 50,000,000 Hz para 60 Hz
					ATUAL_S2 <= NEXT_S2;
					counter <= (others => '0');
				else
					counter <= counter + 1;
				end if;
			end if;
		end if;
	end process;
			
	process (ATUAL_S2)
	begin
		case ATUAL_S2 is
		
			when t0 =>
				NEXT_S2 <= t1;
				display <= display1;
				anode <= "1110";
			
			when t1 =>
				NEXT_S2 <= t2;
				display <= display2;
				anode <= "1101";
			
			when t2 =>
				NEXT_S2 <= t0;
				display <= display3;
				anode <= "1011";	
				
		end case;
	end process;

end Behavioral;