----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Gestion des Rebonds
--
----------------------------------------------------------------------------------
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.pong_pack.all;


entity bounce is
    Port (	clk25 : in  STD_LOGIC;						-- Horloge
				reset : in  STD_LOGIC;						-- Reste Asynchrone
				endframe : in  STD_LOGIC;					-- Signal de Fin de l'Image Visible
				game_type : in  STD_LOGIC;					-- Type de Jeu
				
				-- OBJETS DU JEU
				ball : in  STD_LOGIC;						-- Pixel Courant = Balle
				
				pong_left: in std_logic;					-- Pixel Appartient a la Raguette Gauche (Pong)
				pong_right: in std_logic;					-- Pixel Appartient a la Raquette Droite (Pong)
				
				pad_far_left: in std_logic;				-- Pixel Appartient a la Zone Extreme Gauche
				pad_left: in std_logic;						-- Pixel Appartient a la Zone Gauche
				pad_center: in std_logic;					-- Pixel Appartient a la Zone Centrale
				pad_right: in std_logic;					-- Pixel Appartient a la Zone Droite
				pad_far_right: in std_logic;				-- Pixel Appartient a la Zone Extreme Droite
				
				wall_left : in  STD_LOGIC;					-- Pixel Courant = Mur Gauche
				wall_right : in  STD_LOGIC;				-- Pixel Courant = Mur Droit
				wall_top : in  STD_LOGIC;					-- Pixel Courant = Mur Haut
				wall_bottom : in  STD_LOGIC;				-- Pixel Courant = Mur Bas
				
				barrier: in std_logic;						-- Pixel Courant = Obstacle (Pong)
				brick: in tableau;							-- Pixel Courant = Brique
            
				-- GENERATION DES REBONDS
				leftbounce : out  STD_LOGIC;				-- Rebond Mur Gauche
            rightbounce : out  STD_LOGIC;				-- Rebond Mur Droit
				ybounce : out  STD_LOGIC;					-- Rebond Brique ou Murs du Haut ou du Bas
				
				barrier_bounce: out STD_LOGIC;			-- Rebond Contre l'Obstacle
				brick_bounce : out  tableau;				-- Rebond Contre une Brique
				
				pong_left_bounce : out STD_LOGIC;		-- Rebond Contre Raquette Gauche (Pong)
				pong_right_bounce : out STD_LOGIC;		-- Rebond Contre Raquette Droite (Pong)
				
				pad_far_left_bounce : out STD_LOGIC;	-- Rebond Contre Partie Extreme Gauche de Raquette
				pad_left_bounce : out STD_LOGIC;			-- Rebond Contre Partie Gauche de Raquette
				pad_center_bounce : out STD_LOGIC;		-- Rebond Contre PArtie Centrale de Raquette
				pad_right_bounce : out STD_LOGIC;		-- Rebond Contre Partie Droite de Raquette
				pad_far_right_bounce : out STD_LOGIC	-- Rebond Contre Partie Extreme Droite de Raquette
			);
end bounce;

architecture Behavioral of bounce is

begin

	-- GESTION DES REBONDS
	process(clk25,reset)

		begin
	
			-- Au Reset, pas de Rebond sur les Murs, 
			--		la Raquette ou les Briques
			if reset = '0' then
	
				leftbounce <= '0';
				rightbounce <= '0';
				ybounce <= '0';
				pad_far_left_bounce <= '0';
				pad_left_bounce <= '0';
				pad_center_bounce <= '0';
				pad_right_bounce <= '0';
				pad_far_right_bounce <= '0';
				pong_left_bounce <= '0';
				pong_right_bounce <= '0';
				barrier_bounce <= '0';
		
				for i in 0 to 1 loop
					for j in 0 to 8 loop
						brick_bounce(i)(j) <= '0';
					end loop;
				end loop;
		
			elsif rising_edge(clk25) then
	
				-- Si on n'Est pas a la Fin de l'Image
				if endframe = '0' then
			
					-- Si le Pixel Courant Appartient a la Balle...
					if ball = '1' then	
					
						-- ... Et au Mur Droit
							-- Collision avec le Mur Droit
						if wall_right = '1' then 
							rightbounce <= '1'; 
						end if;
			
						-- ... Et au Mur Gauche
							-- Collision avec le Mur Gauche
						if wall_left = '1' then 
							leftbounce <= '1'; 
						end if;

						-- ... Et le Mur du Haut ou du Bas
							-- Collision avec ces Murs
						if (wall_top or wall_bottom) = '1' then 
							ybounce <= '1'; 
						end if;

						-- ... Et la Raquette Droite du Jeu Pong
							-- Collision avec Cette Raquette
						if pong_right = '1' then 
							pong_right_bounce <= '1'; 
						end if;

						-- ... Et la Raquette Gauche du Jeu Pong
							-- Collision avec Cette Raquette
						if pong_left = '1' then 
							pong_left_bounce <= '1'; 
						end if;
			
						
						-- ... Et la Zone Extreme Gauche de la Raquette Casse Briques
							-- Collision avec Cette Zone de la Raquette
						if pad_far_left = '1' then 
							pad_far_left_bounce <= '1';
						end if;

						-- ... Et la Zone Gauche de la Raquette Casse Briques
							-- Collision avec Cette Zone de la Raquette
						if pad_left = '1' then 
							pad_left_bounce <= '1';
						end if;
				
						-- ... Et la Zone Centrale de la Raquette Casse Briques
							-- Collision avec Cette Zone de la Raquette
						if pad_center = '1' then 
							pad_center_bounce <= '1';
						end if;

						-- ... Et la Zone Droite de la Raquette Casse Briques
							-- Collision avec Cette Zone de la Raquette
						if pad_right = '1' then 
							pad_right_bounce <= '1';
						end if;
			
						-- ... Et la Zone Extreme Droite de la Raquette Casse Briques
							-- Collision avec Cette Zone de la Raquette
						if pad_far_right = '1' then 
							pad_far_right_bounce <= '1';
						end if;
						
						-- ... Et a l'Obstacle (Jeu Pong)
							-- Collision avec l'Obstacle
						if barrier = '1' then 
							barrier_bounce <= '1'; 
						end if;

						-- ... Et avec une Brique (Si le Jeu Est Bien Casse Briques)
							-- Collision avec une Brique
						if game_type = '0' then
							for i in 0 to 1 loop
								for j in 0 to 8 loop
									if brick(i)(j) = '1' then 
										brick_bounce(i)(j) <= '1'; 
										ybounce <= '1'; 
									end if;
								end loop;
							end loop;
						end if;
					end if;
					
			-- Si on Est a la Fin de l'Image
			else
				
				-- Reinitialisation des Flags de Rebond
				barrier_bounce <= '0';
				leftbounce <= '0';
				rightbounce <= '0';
				ybounce <= '0'; 
				pad_far_left_bounce <= '0';
				pad_left_bounce <= '0';
				pad_center_bounce <= '0';
				pad_right_bounce <= '0';
				pad_far_right_bounce <= '0';
				pong_right_bounce <= '0';
				pong_left_bounce <= '0';
			
			end if;
		end if;
	end process;


end Behavioral;

