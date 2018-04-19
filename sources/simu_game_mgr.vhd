--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:15:25 03/18/2016
-- Design Name:   
-- Module Name:   H:/Documents/PMC_E201/simu_game_mgr.vhd
-- Project Name:  PMC_E201
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: game_mgr
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY simu_game_mgr IS
END simu_game_mgr;
 
ARCHITECTURE behavior OF simu_game_mgr IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT game_mgr
    PORT(
         game_rqt : IN  std_logic;
         clk25 : IN  std_logic;
         reset : IN  std_logic;
         game_type : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal game_rqt : std_logic := '0';
   signal clk25 : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal game_type : std_logic;

   -- Clock period definitions
   constant clk25_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: game_mgr PORT MAP (
          game_rqt => game_rqt,
          clk25 => clk25,
          reset => reset,
          game_type => game_type
        );

   -- Stimulus process

      -- insert stimulus here 
	clk25 <= not clk25 after 5 ns ;
	reset <='1' after 5 ns;
	game_rqt <='1' after 28 ns, '0' after 80 ns, '1' after 100 ns, '0' after 140 ns, '1' after 200 ns, '0' after 250 ns, '1' after 400ns,'0' after 450 ns;
	

END;
