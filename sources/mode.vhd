----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:36:03 03/18/2016 
-- Design Name: 
-- Module Name:    mode - Behavioral 
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

entity mode is
    Port ( pause_rqt : in  STD_LOGIC;
           endframe : in  STD_LOGIC;
           lost : in  STD_LOGIC;
           no_brick : in  STD_LOGIC;
           clk25 : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           game_lost : out  STD_LOGIC;
           brick_win : out  STD_LOGIC;
           pause : out  STD_LOGIC);
end mode;

architecture Behavioral of mode is
	-- definition d'un type etat
	type etat is (e0, e1, e2, e3,e4, e5, e6);
	signal EP, EF: etat;
	signal raz_tempo_pause, update_tempo_pause, fin_tempo_pause, load_timer_lost, update_timer_lost: std_logic;
	signal timer_lost : std_logic_vector (5 downto 0); --6bits
	
begin
	-- process du registre d'états
	process (clk25, reset)
	begin 
		if reset='0' then EP <=e0;
		elsif rising_edge (clk25) then EP <= EF;
		end if,
	end process;
	
	-- Combinatoire des etats
	process (EP, game_rqt)0
	begin
	raz_tempo_pause <= '0';
	update_tempo_pause <= '0';
	load_timer_lost <= '0';
	update_timer_lost <= '0';
	Brick_Win <= '0';
	Pause <= '0';
		case (EP) is
			when e0 =>
							raz_tempo_pause <= '1';
							pause <= '1';
							EF <= e0;
							if pause_rqt = '1' then EF<=e1;
							elsif (timer_lost and endframe) > 0 then EF <= e6;
							end if;
							
			when e1 =>
							pause <= '1';
							update_tempo_pause <= '1';
							EF <= e1;
							if pause_rqt = '0' and fin_tempo_pause = '1' then EF<=e2;
							end if; 
							
			when e2 => 
							raz_tempo_pause<= '1';
							EF <=e2;
							if pause_rqt='1' then EF<=e3;
							elsif no_brick='1' then EF<= e4;
							elsif lost='1' then  EF <= e5;
							end if; 
							
			when e3 => 
							updtate_tempo_pause <= '1';
							EF <=e3;
							if fin_tempo_pause = '1' and pause_rqt ='0' then EF <= e0;
							end if;
							
			when e4 => 
							brick_win <='1';
							EF <= e4;
							
			when e5 =>
							load_timer_lost <='1';
							EF <= e0;
							
			when e6 => 
							update_timer_lost <= '1';
							EF <= e0; 
							
							
							

		end case; 
	end process;
	
	
	
end Behavioral;

