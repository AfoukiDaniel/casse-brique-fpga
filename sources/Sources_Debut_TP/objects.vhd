----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Gestion des Objets du Jeu (Balle, Raquette, Briques, Decor)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.pong_pack.ALL;

entity objects is
    Port ( 	clk25 : in  STD_LOGIC;								-- Horloge 25 MHz
				reset : in  STD_LOGIC;								-- Reset Asynchrone
				
				-- SIGNAUX DU CTRL VGA
				endframe : in  STD_LOGIC;							-- Signal de Fin de l'Image Visible
				xpos : in  STD_LOGIC_VECTOR (9 downto 0);		-- Coordonnee X du Pixel Courant
				ypos : in  STD_LOGIC_VECTOR (9 downto 0);		-- Coordonnee Y du Pixel Courant
				
				-- SIGNAUX ENCODEUR ROTATIF
				own_rot_left: in std_logic;						-- Commande Deplacement Codeur Carte
				own_rot_right: in std_logic;						-- Commande Deplacement Codeur Carte
				other_rot_left: in std_logic;						-- Commande Deplacement Codeur Autre Carte
				other_rot_right: in std_logic;					-- Commande Deplacement Codeur Autre Carte
				
				-- MODES DU JEU
				game_type: in std_logic;							-- Type de Jeu
				taille: in std_logic;								-- Paramètre Taille
				speed : in  STD_LOGIC;								-- Vitesse du Jeu
				obstacle: in std_logic;								-- Presence d'un Obstacle (Pong)
				pause: in std_logic;									-- Commande Mode Pause
				game_lost: in std_logic;							-- Mode Echec

				-- OBJETS CORRESPONDANT AU PIXEL COURANT
				bluebox : out  STD_LOGIC;							-- Pixel Courant = Case Bleue
				left : out  STD_LOGIC;								-- Pixel Courant = Gauche de l'Ecran
				right : out  STD_LOGIC;								-- Pixel Courant = Droite de l'Ecran
				bottom : out  STD_LOGIC;							-- Pixel Courant = Bas de l'Ecran
				wall_pong : out  STD_LOGIC;						-- Pixel Courant = Mur pour Jeu Pong
				wall_brick: out  STD_LOGIC;						-- Pixel Courant = Mur pour Jeu Casse Briques
				barrier: out STD_LOGIC;								-- Pixel Courant = Obstacle (Jeu Pong)
				pad: out std_logic;									-- Pixel Appartient a la Raquette
				brick: out tableau;									-- Pixel Courant = Brique
				brick_bounce : out tableau;						-- Rebond Contre une Brique
				ball : out  STD_LOGIC								-- Pixel Courant = Balle
			  );
end objects;

architecture Behavioral of objects is

-- OBJETS DU DECOR ET REBONDS ASSOCIES
signal wall_top : STD_LOGIC;					-- Pixel Courant = Mur du Haut
signal wall_bottom : STD_LOGIC;				-- Pixel Courant = Mur du Bas
signal wall_left :STD_LOGIC;					-- Pixel Courant = Mur de Gauche
signal wall_right: STD_LOGIC;					-- Pixel Courant = Mur de Droite
signal barrier_tmp: STD_LOGIC;				-- Pixel Courant = Obstacle (Pong)

signal leftbounce : STD_LOGIC;				-- Rebond Mur Gauche
signal rightbounce : STD_LOGIC;				-- Rebond Mur Droit
signal ybounce : STD_LOGIC;					-- Rebond Contre une Brique ou Mur du Haut ou du Bas
signal barrier_bounce: STD_LOGIC;			-- Rebond Contre Obstacle

-- RAQUETTE DU JEU CASSE BRIQUES ET REBONDS ASSOCIES
signal pad_tmp: std_logic;						-- Pixel Courant = Raquette
signal pad_far_left: std_logic;				-- Pixel Courant = Zone Extreme Gauche Raquette
signal pad_left: std_logic;					-- Pixel Courant = Zone Gauche Raquette
signal pad_center: std_logic;					-- Pixel Courant = Zone Centrale Raquette
signal pad_right: std_logic;					-- Pixel Courant = Zone Droite Raquette
signal pad_far_right: std_logic;				-- Pixel Courant = Zone Extreme Droite Raquette

signal pad_far_left_bounce : STD_LOGIC;	-- Rebond Contre Zone Extreme Gauche de Raquette
signal pad_left_bounce : STD_LOGIC;			-- Rebond Contre Zone Gauche de Raquette
signal pad_center_bounce : STD_LOGIC;		-- Rebond Contre Zone Centrale de Raquette
signal pad_right_bounce : STD_LOGIC;		-- Rebond Contre Zone Droite de Raquette
signal pad_far_right_bounce : STD_LOGIC;	-- Rebond Contre Zone Extreme Droite de Raquette

-- RAQUETTE DU JEU PONG ET REBONDS ASSOCIES
signal pong_left: std_logic;					-- Pixel Courant = Raquette Gauche
signal pong_right: std_logic;					-- Pixel Courant = Raquette Droite

signal pong_left_bounce : STD_LOGIC;		-- Rebond Contre la Raquette Gauche
signal pong_right_bounce : STD_LOGIC;		-- Rebond Contre la Raquette Droite

-- BRIQUES ET REBONDS ASSOCIES
signal brick_tmp : tableau;					-- Position des Briques
signal brick_bounce_tmp: tableau;			-- Rebond sur des Briques

-- BALLE
signal ball_tmp: std_logic;					-- Pixel Courant = Balle


begin

	-- GESTION DU DECOR
	fond_ecran: entity work.decor
		port map (
			clk25 		=> clk25,			-- Horloge
			reset 		=> reset,			-- Reset Asynchrone
         endframe 	=> endframe,		-- Signal Fin Image Visible
 			xpos 			=> xpos,				-- Coordonnee X du Pixel Courant
         ypos 			=> ypos,				-- Coordonnee Y du Pixel Courant
         game_type	=> game_type,		-- Type de Jeu
			obstacle		=> obstacle,		-- PResence d'un Obstacle (Pong)
			bluebox 		=> bluebox,			-- Pixel Courant = Case Bleue
         left 			=> left,				-- Pixel Courant = Gauche de l'Ecran
         right 		=> right,			-- Pixel Courant = Droite de l'Ecran
         bottom 		=> bottom,			-- Pixel Courant = Bas de l'Ecran
         barrier		=> barrier_tmp,	-- Pixel Courant = Obstacle (Jeu Pong)
			wall_top 	=> wall_top,		-- Pixel Courant = Mur du Haut
			wall_left	=> wall_left,		-- Pixel Courant = Mur de Gauche
			wall_right 	=> wall_right, 	-- Pixel Courant = Mur de Droite
			wall_bottom => wall_bottom,	-- Pixel Courant = Mur du Bas
			wall_pong 	=>	wall_pong,		-- Pixel Courant = Mur Jeu Pong
			wall_brick	=>	wall_brick);	-- Pixel Courant = Mur Jeu Casse Briques

	barrier <= barrier_tmp;

----------------------------------------------------------------------


	pad <= pad_tmp;
	
	-- CONTROLEUR DE RAQUETTE
	pad_ctrl: entity work.pad
		port map (
			clk25 					=> clk25,				-- Horloge
			reset 					=> reset,				-- Reset Asynchrone
         game_type 				=> game_type,			-- Type de Jeu
			taille 					=> taille,				-- Commande de Taille Raquette
			pause 					=> pause,				-- Commande de Pause du Jeu
			rot_left_pad 			=> own_rot_left,		-- Deplacement Gauche Raquette Casse Briques
			rot_right_pad 			=> own_rot_right,		-- Deplacement Droite Raquette Casse Briques
			rot_up_pong_left 		=> own_rot_left,		-- Deplacement Haut Raquette Gauche Pong
			rot_down_pong_left 	=> own_rot_right,		-- Deplacement Bas Raquette Gauche Pong
			rot_up_pong_right 	=> other_rot_left,	-- Deplacement Haut Raquette Droite Pong
			rot_down_pong_right 	=> other_rot_right,	-- Deplacement Bas Raquette Droite Pong
			xpos 						=> xpos,					-- Coordonnee X du Pixel Courant
			ypos 						=> ypos,					-- Coordonnee Y du Pixel Courant
			pad 						=> pad_tmp,				-- Pixel Appartient a la Raquette
			pad_far_left 			=> pad_far_left,		-- Pixel Appartient a la Zone Extreme Gauche
			pad_left 				=> pad_left,			-- Pixel Appartient a la Zone Gauche
			pad_center 				=> pad_center, 		-- Pixel Appartient a la Zone Centrale
			pad_right 				=> pad_right,			-- Pixel Appartient a la Zone Droite
			pad_far_right 			=> pad_far_right,		-- Pixel Appartient a la Zone Extreme Droite
			pong_left				=> pong_left,			-- Pixel Appartient a la Raguette Gauche (Pong)
			pong_right				=> pong_right			-- Pixel Appartient a la Raquette Droite (Pong)
		);			

---------------------------------------------------------------------------

	-- GESTION DES REBONDS
	bounce_ctrl: entity work.bounce
		port map (
			clk25 					=> clk25,					-- Horloge
         reset 					=> reset,					-- Reset Asynchrone
			endframe 				=> endframe,				-- Signal Fin Image Visible
         ball 						=> ball_tmp,				-- Pixel Courant = Balle
			game_type 				=> game_type,				-- Type de Jeu
			pong_left				=> pong_left,				-- Pixel Appartient a la Raguette Gauche (Pong)
			pong_right				=> pong_right,				-- Pixel Appartient a la Raquette Droite (Pong)
			pad_far_left 			=> pad_far_left,			-- Pixel Appartient a la Zone Extreme Gauche
			pad_left 				=> pad_left,				-- Pixel Appartient a la Zone Gauche
			pad_center 				=> pad_center, 			-- Pixel Appartient a la Zone Centrale
			pad_right 				=> pad_right,				-- Pixel Appartient a la Zone Droite
			pad_far_right 			=> pad_far_right,			-- Pixel Appartient a la Zone Extreme Droite
			wall_left 				=> wall_left,				-- Pixel Courant = Mur Gauche
			wall_right 				=> wall_right,				-- Pixel Courant = Mur Droit
			wall_top 				=> wall_top,				-- Pixel Courant = Mur Haut
			wall_bottom 			=> wall_bottom,			-- Pixel Courant = Mur Haut
			barrier					=> barrier_tmp,			-- Pixel Courant = Obstacle (Pong)
			brick 					=> brick_tmp,				-- Pixel Courant = Brique
			leftbounce 				=> leftbounce,				-- Rebond Contre le Mur Gauche
			rightbounce 			=> rightbounce,			-- Rebond Contre le Mur Droit
         ybounce 					=> ybounce,					-- Rebond Contre une Brique ou Mur du Haut ou du Bas
			barrier_bounce			=> barrier_bounce,		-- Rebond Contre l'Obstacle
         brick_bounce 			=> brick_bounce_tmp,		-- Rebond COntre une Brique
 			pong_left_bounce 		=> pong_left_bounce,		-- Rebond Contre Raquette Gauche (Pong)
			pong_right_bounce 	=> pong_right_bounce,	-- Rebond Contre Raquette Droite (Pong)
			pad_far_left_bounce 	=> pad_far_left_bounce,	-- Rebond Contre Zone Extreme Gauche de Raquette
         pad_left_bounce 		=> pad_left_bounce,		-- Rebond Contre Zone Gauche de Raquette
         pad_center_bounce 	=> pad_center_bounce,	-- Rebond Contre Zone Centrale de Raquette
         pad_right_bounce		=> pad_right_bounce,		-- Rebond Contre Zone Droite de Raquette
			pad_far_right_bounce	=> pad_far_right_bounce	-- Rebond Contre Zone Extreme Droite de Raquette
		);

---------------------------------------------------------------------------------------

	ball <= ball_tmp;

	-- GESTION DE LA BALLE
	ball_ctrl: entity work.ball
		port map (
			clk25 					=> clk25,					-- Horloge
         reset 					=> reset,					-- Reset Asynchrone
			endframe 				=> endframe,				-- Signal Fin Image Visible
         pause						=> pause,					-- Mode Pause
         speed						=> speed,					-- Vitesse du Jeu
			game_lost 				=> game_lost,				-- Partie Perdue
			leftbounce 				=> leftbounce,				-- Rebond Contre le Mur Gauche
			rightbounce 			=> rightbounce,			-- Rebond Contre le Mur Droit
         ybounce 					=> ybounce,					-- Rebond Contre une Brique ou Mur du Haut ou du Bas
			barrier_bounce			=> barrier_bounce,		-- Rebond Contre l'Obstacle (Pong)
			pong_left_bounce 		=> pong_left_bounce,		-- Rebond Contre Raquette Gauche (Pong)
         pong_right_bounce 	=> pong_right_bounce,	-- Rebond Contre Raquette Droite (Pong)
         pad_far_left_bounce 	=> pad_far_left_bounce,	-- Rebond Contre Zone Extreme Gauche de Raquette
         pad_left_bounce 		=> pad_left_bounce,		-- Rebond Contre Zone Gauche de Raquette
         pad_center_bounce 	=> pad_center_bounce,	-- Rebond Contre Zone Centrale de Raquette
         pad_right_bounce		=> pad_right_bounce,		-- Rebond Contre Zone Droite de Raquette
			pad_far_right_bounce	=> pad_far_right_bounce,-- Rebond Contre Zone Extreme Droite de Raquette
			xpos 						=> xpos,						-- Coordonnee X du Pixel Courant
         ypos 						=> ypos,						-- Coordonnee Y du Pixel Courant
			ball 						=> ball_tmp					-- Pixel Courant = Balle
		);

-----------------------------------------------------------------------------------

	-- GESTION DES BRIQUES
	
	process(brick_tmp,brick_bounce_tmp)
	
	begin
		
		for i in 0 to 1 loop
			for j in 0 to 8 loop
				brick_bounce(i)(j) <= brick_bounce_tmp(i)(j);
				brick(i)(j) <= brick_tmp(i)(j);
			end loop;
		end loop;
	end process;

	brick_ctrl: entity work.brick_ctrl
		port map (
			xpos 					=> xpos,					-- Coordonnee X du Pixel Courant
         ypos 					=> ypos,					-- Coordonnee Y du Pixel Courant
			game_type			=> game_type,			-- Type de Jeu
			brick_bounce		=> brick_bounce_tmp,	-- Drapeaux des Collisions Briques
			brick 				=> brick_tmp			-- Pixel Courant = Brique
		);

--------------------------------------------------------------------------------------

end Behavioral;

