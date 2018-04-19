----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Gestion des Interrupteurs de la Carte
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity switch_mgr is
    Port ( S3 : in  STD_LOGIC;
           S2 : in  STD_LOGIC;
           S1 : in  STD_LOGIC;
           taille : out  STD_LOGIC;
           speed : out  STD_LOGIC;
           obstacle : out  STD_LOGIC);
end switch_mgr;

architecture Behavioral of switch_mgr is

begin

-- Connection du Parametre Taille Raquette au Swtich S3 
	taille <= S3;
	
	-- Connection du Parametre Vitesse Balle au Swtich S2 
	speed <= S2;

	-- Connection du Parametre Presence Obstacle au Swtich S1 
	obstacle <= S1;

end Behavioral;

