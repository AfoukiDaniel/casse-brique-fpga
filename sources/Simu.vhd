--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:59:20 02/26/2016
-- Design Name:   
-- Module Name:   H:/Documents/PMC_E201/Simu.vhd
-- Project Name:  PMC_E201
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ClkDiv
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
 
ENTITY Simu IS
END Simu;
 
ARCHITECTURE behavior OF Simu IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ClkDiv
    PORT(
         Clk50 : IN  std_logic;
         Reset : IN  std_logic;
         Clk25 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Clk50 : std_logic := '0';
   signal Reset : std_logic := '0';

 	--Outputs
   signal Clk25 : std_logic;

   -- Clock period definitions
   constant Clk50_period : time := 10 ns;
   constant Clk25_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ClkDiv PORT MAP (
          Clk50 => Clk50,
          Reset => Reset,
          Clk25 => Clk25
        );

Clk50<= not Clk50 after 10ns;
reset <= '1' after 15 ns;

END;
