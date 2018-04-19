----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
-- Generation du Decor et Gestion de l'Obstacle du Jeu Pong
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity decor is
    Port (	clk25: in STD_LOGIC;								-- Horloge 25 MHz
				reset: in STD_LOGIC;								-- Reset Asynchrone
				
				-- INDICATIONS D'AFFICHAGE DES PIXELS
				endframe: in  STD_LOGIC;						-- Fin de l'Image Visible 
				xpos : in  STD_LOGIC_VECTOR (9 downto 0);	-- Coordonnee X du Pixel Courant
				ypos : in  STD_LOGIC_VECTOR (9 downto 0);	-- Coordonnee Y du Pixel Courant
				
				-- PARAMETRES DE JEU
				game_type: in STD_LOGIC;						-- Type de Jeu
				obstacle: in STD_LOGIC;							-- Parametre Obstacle
			  
				-- ELEMENTS DE DECOR
				bluebox : out  STD_LOGIC;						-- Pixel Courant = Case Bleue
				left: out STD_LOGIC;								-- Pixel Courant = Gauche de l'Ecran
				right: out STD_LOGIC;							-- Pixel Courant = Droite de l'Ecran
				bottom : out  STD_LOGIC;						-- Pixel Courant = Bas de l'Ecran
				barrier: out std_logic;							-- Pixel Courant = Obstacle (Jeu Pong)
				wall_top : out  STD_LOGIC;						-- Pixel Courant = Mur du Haut
				wall_bottom : out  STD_LOGIC;					-- Pixel Courant = Mur du Bas
				wall_left : out  STD_LOGIC;					-- Pixel Courant = Mur de Gauche
				wall_right : out  STD_LOGIC;					-- Pixel Courant = Mur de Droite
				wall_pong : out  STD_LOGIC;					-- Pixel Courant = Mur Jeu Casse Briques
				wall_brick : out  STD_LOGIC);					-- Pixel Courant = Mur Jeu Pong
end decor;

architecture Behavioral of decor is

signal xbarrier: std_logic;									-- Coordonnees en X de l'Obstacle
signal ybarrier: std_logic_vector(8 downto 0);			-- Corrdonnees en Y de l'Obstacle
signal direction: std_logic;									-- Sens de Deplacement de l'Obstacle

begin

-------------------------------------------------------------------------------------------

	-- GESTION DU DECOR
		-- Damier Bleu et Noir de Fond d'Ecran
		-- Generation des Murs (En Fonction du Jeu Choisi)
		-- Signal de Bas de l'Ecran
	process (xpos,ypos,game_type)

	begin

		wall_pong	<= '0';
		wall_brick	<= '0';
		wall_left	<=	'0';
		wall_right	<=	'0';
		wall_top 	<=	'0';
		wall_bottom	<=	'0';
		left			<= '0';
		right			<= '0';
		bottom 		<=	'0';
		bluebox		<=	'0';

		
		-- Delimitation des Cases Bleues
			-- Tous les 32x32 Pixels
		bluebox <= xpos(5) xor ypos(5);
		
		
		-- Mur Haut (Present dans Pong et Casse Briques)
		if (ypos < 4) then 
			wall_top <= '1'; wall_brick <= '1'; wall_pong <= '1';
		end if;

		-- Si on Joue au Casse Briques
		if game_type = '0' then
			
			-- Mur Gauche
			if (xpos <= 4) then 
				wall_left <= '1'; wall_brick <= '1';
			end if;
		
			-- Mur Droit
			if (xpos > 635) then 
				wall_right <= '1'; wall_brick <= '1';
			end if;
	
			-- Bas de l'ecran
			if (ypos > 475) then 
				bottom <= '1'; 
			end if;
						
		-- Si on Joue a Pong
		else

			-- Mur du Bas
			if (ypos > 475) then 
				wall_bottom <= '1'; wall_pong <= '1';
			end if;

			-- Bord Gauche de L'Ecran
			if (xpos <= 4) then 
				left <= '1';
			end if;
		
			-- Bord Droit de l'Ecran
			if (xpos > 635) then 
				right <= '1';
			end if;


		end if;
	
	end process;

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

	-- AJOUTER ICI LE CODE POUR LA GESTION DE L'OBSTACLE

	xbarrier	<= '0';
	ybarrier	<= (others => '0');
	barrier	<= '0';

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

end Behavioral;

