LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 

ENTITY TESTBENCH IS
END TESTBENCH;
 
ARCHITECTURE behavior OF TESTBENCH IS 
 

    COMPONENT NEANDER
    PORT(
         clock : IN  std_logic;
         reset : IN  std_logic;
         acumulador : OUT  std_logic_vector(7 downto 0);
         halt : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal acumulador : std_logic_vector(7 downto 0);
   signal halt : std_logic;

   -- Clock period definitions
   constant clock_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: NEANDER PORT MAP (
          clock => clock,
          reset => reset,
          acumulador => acumulador,
          halt => halt
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      reset <= '1';
		
      wait for 100 ns;

		reset <= '0'; 
			
		wait for 20000 ns;

      wait;
		
		-- wait for clock_period*10;
   end process;

END;
