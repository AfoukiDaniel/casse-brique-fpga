--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:32:52 03/11/2016
-- Design Name:   
-- Module Name:   H:/Documents/PMC_E201/simu_move.vhd
-- Project Name:  PMC_E201
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: move
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
 
ENTITY simu_move IS
END simu_move;
 
ARCHITECTURE behavior OF simu_move IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT move
    PORT(
         qa : IN  std_logic;
         qb : IN  std_logic;
         rot_left : OUT  std_logic;
         rot_right : OUT  std_logic;
         clk25 : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal qa : std_logic := '0';
   signal qb : std_logic := '0';
   signal clk25 : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal rot_left : std_logic;
   signal rot_right : std_logic;

   -- Clock period definitions
   constant clk25_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: move PORT MAP (
          qa => qa,
          qb => qb,
          rot_left => rot_left,
          rot_right => rot_right,
          clk25 => clk25,
          reset => reset
        );

   -- Stimulus process

      -- insert stimulus here 
	clk25 <= not clk25 after 25 ns ;
	reset <='1' after 5 ns;
	qa <='1' after 30 ns ; qb <='1' after 20 ns;
      


END;
