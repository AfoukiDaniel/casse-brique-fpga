----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:21:04 03/11/2016 
-- Design Name: 
-- Module Name:    game_mgr - Behavioral 
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

entity game_mgr is
    Port ( game_rqt : in  STD_LOGIC;
           clk25 : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           game_type : out  STD_LOGIC);
end game_mgr;

architecture Behavioral of game_mgr is
	-- definition d'un type etat
	type etat is (e0, e1, e2, e3);
	signal EP, EF: etat;

	begin
	-- Process du registre d'états
	process (clk25, reset)
	begin
		if reset='0' then EP <=e0;
		elsif rising_edge (clk25) then EP <= EF;
		end if;
	end process;
	
	-- Combinatoire des etats
	process(EP, game_rqt)
	begin
	game_type <= '0';
		case (EP) is
			when e0 =>
						game_type <= '0';
						EF <= e0;
						if game_rqt='1' then EF<=e1;
						end if;
						
			when e1 => 
						game_type <='1';
						EF <= e1;
						if game_rqt ='0' then EF<= e2;
						end if;
						
			when e2 =>
						game_type <='1';
						EF <= e2;
						if game_rqt ='1' then EF<= e3;
						end if;
						
			when e3 =>
						game_type <='0';
						EF <= e3;
						if game_rqt ='0' then EF<= e0;
						end if;
		end case; 
	end process;
end Behavioral;

