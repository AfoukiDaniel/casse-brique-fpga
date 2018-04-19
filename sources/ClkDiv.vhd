----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:17:10 02/26/2016 
-- Design Name: 
-- Module Name:    ClkDiv - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ClkDiv is
    Port ( Clk50 : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           Clk25 : out  STD_LOGIC);
end ClkDiv;

architecture Behavioral of ClkDiv is
signal q: std_logic;
signal d: std_logic;

begin
Clk25<= d;
q <=d;
	process(Clk50,Reset)
	begin
		if Reset='0' then d<='0' ;
		elsif rising_edge (Clk50) then d <= not q ;
		
		end if;
	end process;

end Behavioral;

