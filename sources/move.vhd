----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:40:55 02/26/2016 
-- Design Name: 
-- Module Name:    move - Behavioral 
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

entity move is
    Port ( qa : in  STD_LOGIC;
           qb : in  STD_LOGIC;
           rot_left : out  STD_LOGIC;
           rot_right : out  STD_LOGIC;
           clk25 : in  STD_LOGIC;
           reset : in  STD_LOGIC);
end move;

architecture Behavioral of move is

	-- definition d'un type etat 
	type etat is(e0, e1, e2, e3, e4, e5, e6);
	signal EP, EF: etat;
	
	begin
	-- Process du registre d'états
	process (clk25, reset)
	begin
		if reset='0' then EP <= e0;
		elsif rising_edge(clk25) then EP <= EF;
		end if;
	end process;
	
-- Combinatoire des etats
	process(EP, qa, qb)
	begin 
	rot_left <= '0'; rot_right <= '0';
		case (EP) is
			when e0 =>
						EF <= e0;
						if qb='1' and qa='1' then EF <= e1;
						elsif qa='1' and qb='0' then EF <= e4;
						end if;
						
			when e1 =>	rot_right <='1';
							 EF <= e2;
			when e2 => EF <= e2 ;
						  if qa='0' and qb='0' then EF <= e3;
						  end if;
			when e3 => rot_right <='1';
							EF <= e0;
			
			when e4 => EF <= e4;
							rot_left <='1';
							if qa='1' and qb='0' then EF <= e5;
							end if;
			when e5 => EF <= e5;
							if qa='0' and qb='1' then EF <= e6;
							end if;
			when e6 => rot_left <='1';
							EF <= e0;
						
	
	end case;
end process; 

end Behavioral;

