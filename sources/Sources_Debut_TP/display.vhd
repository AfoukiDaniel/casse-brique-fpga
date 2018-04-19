----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Selection des Couleurs des Pixels a Afficher
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.pong_pack.ALL;

entity display is
    Port ( 	visible: in STD_LOGIC;			-- Zone Visible de l'Image
				master_slave: in STD_LOGIC;	-- Mode Console ou Manette
				pad : in  STD_LOGIC;				-- Pixel Courant = Raquette
				wall_pong : in  STD_LOGIC;		-- Pixel Courant = Mur Jeu Pong
				wall_brick : in  STD_LOGIC;	-- Pixel Courant = Mur Jeu Casse Briques
				barrier: in STD_LOGIC;			-- Pixel Courant = Obstacle (Jeu Pong)
				bluebox : in  STD_LOGIC;		-- Pixel Courant = Case Bleue
				ball : in  STD_LOGIC;			-- Pixel Courant = Balle
				brick : in  tableau;				-- Pixel Courant = Brique
				brick_win : in  STD_LOGIC;		-- Partie Gagnee (Jeu Casse Briques)
				lost_game : in  STD_LOGIC;		-- Partie Perdue
				red : out  STD_LOGIC;			-- Commande Affichage Rouge
				green : out  STD_LOGIC;			-- Commande Affichage Vert
				blue : out  STD_LOGIC);			-- Commande Affichage Bleu
end display;

architecture Behavioral of display is

begin

	process (pad,wall_brick,wall_pong,bluebox,ball,brick,brick_win,lost_game,barrier,master_slave,visible)

	begin

		-- SI ON EST DANS LA ZONE VISIBLE DE L'IMAGE
		if visible = '1' then
		
			-- LE PIXEL COURANT APPARTIENT AU DECOR

			-- Si le Pixel Courant Appartient a un Mur ou a l'Obstacle
			--	Couleur = Blanc
			if (wall_brick or wall_pong or barrier) = '1' then
				red <= '1'; green <= '1'; blue <= '1'; 
	
			-- Sinon, si le Pixel Courant Appartient a une case Bleue du Decor
			--	Couleur = Bleu
			elsif bluebox = '1' then
				red <= '0'; green <= '0'; blue <= '1'; 
		
			else
			-- Sinon, le Pixel Courant Est Noir S'Il Fait Partie du Decor
			--	Couleur = Bleu
				red <= '0'; green <= '0'; blue <= '0'; 
			end if;


			-- LE PIXEL COURANT EST UNE BRIQUE

			-- Couleur = Blanc
			for i in 0 to 1 loop
				for j in 0 to 8 loop
					if brick(i)(j)='1' then 
						red<='1'; green<='1'; blue<='1'; 
					end if;
				end loop;
			end loop;

			-- LE PIXEL COURANT APPARTIENT A LA BALLE OU LA RAQUETTE

			-- Couleur = Jaune
			if (pad or ball) = '1' then 
				red <= '1'; green <= '1'; blue <= '0'; 
			end if;

			-- PARTIE GAGNEE -> Couleur Vert
			-- PARTIE PERDUE -> Couleur Rouge
	
			if brick_win = '1' then 
				red <= '0'; green <= '1'; blue <= '0'; 
			elsif lost_game = '1' then 
				red <= '1'; green <= '0'; blue <= '0'; 
			end if;

		
			-- PAS D'AFFICHAGE SI ON EST EN MODE MANETTE
			if master_slave = '0' then
				red <= '0'; green <= '0'; blue <= '0'; 
			end if;
		
		-- Si on Est dans la Zone Non Visible (Synchro)
		--		Les Sorties RGB Sont Mise a Zero
		else
			red <= '0'; green <= '0'; blue <= '0'; 
		end if;
end process;


end Behavioral;

