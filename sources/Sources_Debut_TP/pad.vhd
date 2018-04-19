----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien
-- 
-- Gestion de la Raquette
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity pad is
    Port ( 	clk25 : in  STD_LOGIC;							-- Horloge
				reset: in std_logic;								-- Reset Asynchrone
				
				-- COORDONNEES DU PIXEL COURANT
				xpos: in std_logic_vector(9 downto 0);		-- Coordonnees X du Pixel Courant
				ypos: in std_logic_vector(9 downto 0);		-- Coordonnees Y du Pixel Courant

				-- PARAMETRES DE JEU
				game_type: in std_logic;						-- Type de Jeu
				taille: in std_logic;							-- Paramètre Taille
				pause: in std_logic;							-- Commande Mode Pause
				
				-- CONSIGNES DE DEPLACEMENT DES RAQUETTES
				rot_left_pad: in std_logic;					-- Deplacement Gauche Raquette Casse Briques
				rot_right_pad: in std_logic;					-- Deplacement Droite Raquette Casse Briques
				rot_up_pong_left: in std_logic;				-- Deplacement Haut Raquette Gauche Pong
				rot_down_pong_left: in std_logic;			-- Deplacement Bas Raquette Gauche Pong
				rot_up_pong_right: in std_logic;				-- Deplacement Haut Raquette Droite Pong
				rot_down_pong_right: in std_logic;			-- Deplacement Bas Raquette Droite Pong

				-- GENERATION DES RAQUETTES
				pad: out std_logic;								-- Pixel Appartient a la Raquette (Casse-Briques)
				pad_far_left: out std_logic;					-- Pixel Appartient a la Zone Extreme Gauche
				pad_left: out std_logic;						-- Pixel Appartient a la Zone Gauche
				pad_center: out std_logic;						-- Pixel Appartient a la Zone Centrale
				pad_right: out std_logic;						-- Pixel Appartient a la Zone Droite
				pad_far_right: out std_logic;					-- Pixel Appartient a la Zone Extreme Droite
				pong_left: out std_logic;						-- Pixel Appartient a la Raquette Gauche (Pong)
				pong_right: out std_logic						-- Pixel Appartient a la Raquette Droite (Pong)
	 );
end pad;

architecture Behavioral of pad is

-- PARAMETRES COMMUN AUX RAQUETTES DES DEUX JEUX
signal longueur: integer range 0 to 120;				-- Longueur en Pixels de la Raquette

-- PARAMETRES DE LA RAQUETTE DU CASSE BRIQUES
signal xpad: std_logic_vector(9 downto 0);			-- Coordonnees en X de la Raquette
signal ypad: std_logic;										-- Coordonnees en Y de la Raquette

signal far_left_zone: integer range 0 to 10;			-- Zone Extreme Gauche de la Raquette
signal left_zone: integer range 0 to 40;				-- Zone Gauche de la Raquette
signal center_zone: integer range 0 to 80;			-- Zone Centrale de la Raquette
signal right_zone: integer range 0 to 110;			-- Zone Droite de la Raquette
signal far_right_zone: integer range 0 to 120;		-- Zone Extreme Droite de la Raquette

-- PARAMETRES DES RAQUETTES DU PONG
signal xpong_left: std_logic;								-- Coordonnees en X de la Raquette Gauche
signal ypong_left: std_logic_vector(8 downto 0);	-- Coordonnees en Y de la Raquette Gauche
signal xpong_right: std_logic;							-- Coordonnees en X de la Raquette Droite
signal ypong_right: std_logic_vector(8 downto 0);	-- Coordonnees en Y de la Raquette Droite

begin

--------------------------------------------------------------------------
	-- Calcul de la Taille et des Zones de la Raquette
	--		En Fonction du Parametre de Taille
	longueur 		<= 120 	when taille = '1' else 60;

	far_left_zone 	<= 10 	when taille = '1' else 5;
	left_zone 		<= 40 	when taille = '1' else 20;
	center_zone 	<= 80 	when taille = '1' else 40;
	right_zone 		<= 110 	when taille = '1' else 55;
	far_right_zone <= 120 	when taille = '1' else 60;

---------------------------------------------------------------------------

	-- CALCUL DES COORDONNEES "FIXES" DES RAQUETTES

	-- Position en Ordonnee de la Raquette Casse Briques
	ypad <= '1' when 	(ypos > 440) and (ypos < 448) and 
							(game_type = '0')
	else '0';

	-- Position en Abscisses de la Raquette Gauche (Pong)
	xpong_left <= '1' when 	(xpos > 32) and (xpos < 40) and
									(game_type='1')
	else '0';

	-- Position en Abscisses de la Raquette Droite (Pong)
	xpong_right <= '1' when (xpos > 600) and (xpos < 608) and 
									(game_type='1')
	else '0';



	-- CALCUL DES COORDONNEES "VARIABLES" DES RAQUETTES
	process(clk25,reset)

	begin

		if reset='0' then 
				xpad 			<= "0110001001";	-- (X = 393)
				ypong_left 	<= "011001000"; 	-- (X = 200)
				ypong_right <= "011001000"; 	-- (X = 200)

		elsif rising_edge(clk25) then
	
			-- Si on n'Est pas en Mode Pause
			if pause='0' then
		
			-- Si le Jeu est Casse Briques
				if game_type = '0' then
				
					-- Si Commande de Rotation Gauche
						-- Deplacement a Gauche de la Raquette
					if rot_left_pad='1' then 
						if (xpad > 3) then		-- Pour ne pas Sortir de l'Ecran
							xpad<=xpad-4;
						end if;
		
					-- Si Commande de Rotation Droite
						-- Deplacement a Droite de la Raquette
					elsif rot_right_pad='1' then
						if (xpad < 632-longueur) then 	-- Pour ne pas Sortir de l'Ecran
							xpad<=xpad+4; 
						end if;
					end if;
			
				-- Si le Jeu Est Pong
				else
				-- Si Commande de Rotation vers le Haut
					-- Deplacement vers le Haut de la Raquette
					if rot_up_pong_left='1' then 
						if (ypong_left > 5) then		-- Pour ne pas Sortir de l'Ecran
							ypong_left<=ypong_left-4;
						end if;
					end if;
					
				-- Si Commande de Rotation vers le Haut
					-- Deplacement vers le Haut de la Raquette
					if rot_up_pong_right='1' then 
						if (ypong_right > 5) then		-- Pour ne pas Sortir de l'Ecran
							ypong_right<=ypong_right-4;
						end if;
					end if;
					
				-- Si Commande de Rotation vers le Bas
					-- Deplacement vers le Bas de la Raquette
					if rot_down_pong_left='1' then
						if (ypong_left < 474-longueur) then 	-- Pour ne pas Sortir de l'Ecran
							ypong_left<=ypong_left+4; 
						end if;
					end if;

				-- Si Commande de Rotation vers le Bas
					-- Deplacement vers le Bas de la Raquette
					if rot_down_pong_right='1' then 
						if (ypong_right < 474-longueur) then 	-- Pour ne pas Sortir de l'Ecran
							ypong_right<=ypong_right+4; 
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
-----------------------------------------------------------------

	-- DETERMINATION DES PIXELS ET DES ZONES DE LA RAQUETTE

	process (xpos,ypos,xpad,ypad,far_left_zone,left_zone,center_zone,right_zone,far_right_zone,
				xpong_left,ypong_left,xpong_right,ypong_right)

		begin

			-- Par Defaut, le Pixel Courant n'Appartient pas a la Raquette
			pad_far_left <= '0'; pad_left <= '0'; 			pad_center <= '0';
			pad_right <= '0'; 	pad_far_right <= '0'; 	pad <= '0';
			pong_left <= '0'; 	pong_right <= '0';
	
			-- Si l'Ordonnee Appartient a la Zone de la Raquette Casse Briques
			if ypad='1' then
		
				-- Si l'Abscisse Correspond a l'Extreme Gauche de la Raquette
				if (xpos > xpad) and (xpos <= (xpad+far_left_zone)) then
					pad_far_left <= '1';	pad <= '1';
				
				-- Si l'Abscisse Correspond a la Partie Gauche de la Raquette
				elsif (xpos > xpad+far_left_zone) and (xpos <= (xpad+left_zone)) then
					pad_left <= '1'; pad <= '1';

				-- Si l'Abscisse Correspond a la Partie Centrale de la Raquette
				elsif (xpos > xpad+left_zone) and (xpos <= (xpad+center_zone)) then
					pad_center <= '1'; pad <= '1';

				-- Si l'Abscisse Correspond a la Moitie Gauche de la Raquette
				elsif (xpos > xpad+center_zone) and (xpos <= (xpad+right_zone)) then
					pad_right <= '1'; pad <= '1';

				-- Si l'Abscisse Correspond a la Moitie Gauche de la Raquette
				elsif (xpos > xpad+right_zone) and (xpos < (xpad+far_right_zone)) then
					pad_far_right <= '1'; pad <= '1';

				end if;
			end if;
			
			-- Si l'Abscisse Appartient a la Zone de la Raquette Gauche de Pong
			if xpong_left = '1' then
				
				-- Si l'Ordonnee Correspond a la Zone de la Raquette
				if (ypos > ypong_left) and (ypos <= (ypong_left+longueur)) then
					pad <= '1'; pong_left <= '1';
				end if;
			end if;	
			
			-- Si l'Abscisse Appartient a la Zone de la Raquette Droite de Pong
			if xpong_right = '1' then

				-- Si l'Ordonnee Correspond a la Zone de la Raquette
				if (ypos > ypong_right) and (ypos <= (ypong_right+longueur)) then
					pad <= '1'; pong_right <= '1';
				end if;
			end if;
	end process;

---------------------------------------------------------



end Behavioral;

