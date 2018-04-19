----------------------------------------------------------------------------------
--	Company: UPMC
--	Engineer: Julien Denoulet
-- 
--	Module Principal - Casse Briques
--
----------------------------------------------------------------------------------
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use work.pong_pack.all;

entity top is
    Port (	clk50 : in	STD_LOGIC;						-- Horloge 50 Mhz
				ouest : in	STD_LOGIC; 						-- Reset Asynchrone (Bouton Ouest)
				nord,sud,est: in STD_LOGIC;				-- Boutons Poussoir
				led: out STD_LOGIC_VECTOR(7 downto 0);	-- LEDs
				S3,S2,S1,S0	: in STD_LOGIC;				-- Switchs
				rot_a,rot_b,rot_button: in STD_LOGIC;	-- Encodeur Rotatif
				txd:	out std_logic;							-- Sortie RS232
				rxd: in std_logic;							-- Entree RS232
				hsync : out  STD_LOGIC;						-- Synchro Horizontale VGA
				vsync : out  STD_LOGIC;						-- Synchro Verticale VGA
				VGA_red : out  STD_LOGIC;					-- Rouge VGA
				VGA_green : out  STD_LOGIC;				-- Vert VGA
				VGA_blue : out  STD_LOGIC);				-- Bleu VGA
end top;

architecture Behavioral of top is

signal clk25: std_logic;									-- Horloge 25 Mhz
signal reset: std_logic;									-- Reset Asynchrone

signal display: std_logic_vector(7 downto 0);		-- Pour Affichage des LEDs

-- PARAMETRES DE JEU
signal game_rqt: std_logic;								-- Demande de Changement de Jeu (Appui sur un Bouton Poussoir)
signal master_slave: std_logic;							-- Mode Maitre (Console) ou Esclave (Manette)
signal master_slave_rqt: std_logic;						-- Demande de Changement de Mode (Appui sur un Bouton Poussoir)


-- SIGNAUX D'AFFICHAGE
signal xpos,ypos: std_logic_vector(9 downto 0);		-- Coordonnees Pixel Courant
signal visible: std_logic;									-- Zone Visible de l'Image
signal endframe: std_logic;								-- Fin Image Visible
signal red,green,blue: std_logic;						-- Couleurs RGB du VGA

-- SIGNAUX DES MANETTES DE JEU
signal own_rot_left,own_rot_right: std_logic;		-- Mouvement de l'Encodeur Rotatif de la Carte
signal other_rot_left,other_rot_right: std_logic;	-- Mouvement de l'Encodeur Rotatif de l'Autre Carte
signal own_press,other_press: std_logic;				-- Appui sur Bouton Encodeur
signal pause_rqt: std_logic;								-- Demande de Pause

-- SIGNAUX OPTIONS DE JEU
signal game_type: std_logic;								-- Type de Jeu (0 = Casse Brique / 1 = Pong)
signal taille: std_logic;									-- Parametre Taille de la Raquette
signal speed: std_logic;									-- Parametre Vitesse de la Balle
signal obstacle: std_logic;								-- Presence d'un Obstacle (Pong)
signal game_lost: std_logic;								-- Drapeau Partie Perdue
signal pause: std_logic;									-- Mode Pause

-- SIGNAUX OBJETS DU JEU
signal bluebox: std_logic;									-- Pixel Courant = Case Bleue du Decor
signal left: std_logic;										-- Pixel Courant = Bord Gauche de L'Ecran
signal right: std_logic;									-- Pixel Courant = Bord Droit de L'Ecran
signal bottom: std_logic;									-- Pixel Courant = En Bas de L'Ecran
signal lost: std_logic;										-- La Balle Va Sortir de L'Ecran
signal pad: std_logic;										-- Pixel Courant = Raquette
signal ball: std_logic;										-- Pixel Courant = Balle
signal wall_pong: std_logic;								-- Pixel Courant = Mur Jeu Pong
signal wall_brick: std_logic;								-- Pixel Courant = Mur Jeu Casse Briques
signal barrier: std_logic;									-- Pixel Courant = Obstacle (Jeu Pong)
signal brick: tableau;										-- Pixel Courant = Brique(i)(j)
signal brick_bounce: tableau;								-- Pixel Courant Rebondit Contre une Brique(i)(j)


begin

-----------------------------------------------------------------------------------------
	-- DIVISEUR D'HORLOGE
	clkgen: entity work.ClkDiv
			port map (
				clk50 => clk50,		-- Horloge 50 MHz
				reset => reset,		-- Reset Asynchrone
				clk25 => clk25);		-- Horloge 25 MHz
				
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------
	-- GESTION DES ENTREES/SORTIES DE LA CARTE

	-- Switch S0: 0 = Systeme OFF / 1 = Systeme ON
	-- Reset Asynchrone COnnecte au Bouton Ouest 
	reset <= (not ouest) and S0 ;

	-- CONTROLEUR DES INTERRUPTEURS
	switch: entity work.switch_mgr
		port map(
			S3			=> S3,
			S2			=> S2,
			S1			=> S1,
			taille	=> taille,
			speed		=> speed,
			obstacle	=> obstacle
		);
		
		
	-- CONTROLEUR DES BOUTONS POUSSOIRS
	buttons: entity work.button_mgr
		port map (
			clk25 			=> clk25,				-- Horloge
			reset 			=> reset,				-- Reset Asynchrone
			nord				=> nord,					-- Bouton Nord
			sud 				=> sud,					-- Bouton Sud
			est 				=> est,					-- Bouton Est
			press_sud		=> master_slave_rqt,	-- Demande de Changement de Mode (Bouton Sud)
			press_nord_est	=> game_rqt				-- Demande de Changement de Jeu (Bouton Nord ou Est)
		);		


	-- CONTROLEUR DE L'ENCODEUR ROTATIF DE LA CARTE
	codeur: entity work.ip_rotary
		port map (
			clk25 		=> clk25,				-- Horloge
			reset 		=> reset,				-- Reset Asynchrone
			rot_a 		=> rot_a,				-- Switch A du Codeur
			rot_b 		=> rot_b,				-- Switch B du Codeur
			rot_button 	=> rot_button,			-- Bouton du Codeur
			press 		=> own_press,			-- Detection Appui du Bouton du Codeur
			rot_left 	=> own_rot_left,		-- Commande de Rotation a Gauche
			rot_right 	=> own_rot_right);	-- Commande de Rotation a Droite


	-- CONTROLEUR DU PORT SERIE
	--		(TRANSMET LES COMMANDES DE L'ENCODEUR ROTATIF DE L'AUTRE CARTE)
	RS232: entity work.ip_uart
		port map(
			clk25					=> clk25,				-- Horloge 25 MHz
			reset					=> reset,				-- Reset Asynchrone
			master_slave		=> master_slave,		-- Motre Maitre/Console(=1) ou Esclave/Manette (=0)
			own_rot_left 		=> own_rot_left,		-- Commande Rotation a Gauche du Codeur de la Carte
			own_rot_right 		=> own_rot_right,		-- Commande Rotation a Droite du Codeur de la Carte
			own_press 			=> own_press,			-- Appui Bouton du Codeur de la Carte
			txd 					=> txd,					-- Sortie RS232
			rxd 					=> rxd,					-- Entree RS232
			other_rot_left		=> other_rot_left,	-- Rotation Gauche du Codeur de l'Autre Carte
			other_rot_right	=> other_rot_right,	-- Rotation Droite du Codeur de l'Autre Carte
			other_press			=> other_press			-- Appui Bouton du Codeur de l'Autre Carte
	);

	pause_rqt <= own_press;							-- Seule la Carte Maitre Peut Mettre le Jeu en Pause

	
	-- GESTION DES LEDS
		-- LED Allumees Si On Est en Mode Maitre (Console)
		-- LED Eteintes Si On Est en Mode Esclave (Manette)

	display <= (others => '1') when (S0 = '1' and master_slave = '1')
	else (others => '0');

	-- Envoi de la Valeur a Afficher sur les LEDs
	led <= display;

--------------------------------------------------------------------------------------------------------
	
	-- GESTION DES OBJETS
	obj_ctrl: entity work.objects
			port map (
				clk25 				=> clk25,				-- Horloge 25 MHz
				reset					=> reset,				-- Reset Asynchrone
				endframe				=> endframe,			-- Fin de l'Image Visible
				xpos 					=> xpos,					-- Coordonnee X du Pixel Courant
				ypos 					=> ypos,					-- Coordonnee Y du Pixel Courant
				own_rot_left		=> own_rot_left,		-- Commande Deplacement Gauche Codeur de la Carte
				own_rot_right		=> own_rot_right,		-- Commande Deplacement Droite Codeur de la Carte
				other_rot_left		=> other_rot_left,	-- Commande Deplacement Gauche Codeur Autre Carte
				other_rot_right	=> other_rot_right,	-- Commande Deplacement Droite Codeur Autre Carte
				game_type			=> game_type,			-- Choix du Type de Jeu
				taille				=> taille,				-- Paramètre Taille
				speed 				=> speed,				-- Vitesse du Jeu
				obstacle 			=> obstacle,			-- Presence d'un Obstacle (Pong)
				pause					=> pause,				-- Commande Mode Pause
				game_lost			=> game_lost,			-- Mode Echec
				bluebox 				=> bluebox,				-- Pixel Courant = Case Bleue
				left 					=> left,					-- Pixel Courant = Gauche de l'Ecran
				right 				=> right,				-- Pixel Courant = Droite de l'Ecran
				bottom 				=> bottom,				-- Pixel Courant = Bas de l'Ecran
				wall_pong			=> wall_pong,			-- Pixel Courant = Mur Jeu Pong
				wall_brick 			=> wall_brick,			-- Pixel Courant = Mur Jeu Casse Briques
				barrier				=> barrier,				-- Pixel Courant = Obstacle (Jeu Pong)
				pad 					=> pad,					-- Pixel Appartient a la Raquette
				brick					=> brick,				-- Pixel Courant = Brique
				brick_bounce		=> brick_bounce,		-- Rebond Contre une Brique
				ball 					=> ball 					-- Pixel Courant = Balle
			 );

------------------------------------------------------------------

	lost <= ball and (bottom or left or right);	-- La Balle Sort de L'Exran Si Elle Atteint un des Bords

	-- GESTION DU JEU
	game_ctrl: entity work.game
			port map (
				clk25 				=> clk25,				-- Horloge 25 MHz
				reset 				=> reset,				-- Reset Asynchrone
				master_slave_rqt 	=> master_slave_rqt,	-- Demande de Changement de Mode (Console / Manette)
				game_rqt 			=> game_rqt,			-- Demande de Changement de Jeu (Pong / Casse Briques)
				
				-- ************** REMPLACER L'INSTRUCTION CI-DESSOUS PAR CELLE EN COMMENTAIRE *****************
				--pause_rqt 			=> S1,					-- Demande de Pause - Appui sur Bouton Encodeur
				pause_rqt 			=> pause_rqt,					-- Demande de Pause - Appui sur Bouton Encodeur
				-- ********************************************************************************************

				endframe 			=> endframe,			-- Fin de l'Image Visible
				visible 				=> visible,				-- Zone Visible de l'Image
				wall_pong			=> wall_pong,			-- Pixel Courant = Mur Jeu Pong
				wall_brick 			=> wall_brick,			-- Pixel Courant = Mur Jeu Casse Briques
				barrier				=> barrier,				-- Pixel Courant = Obstacle (Jeu Pong)
				lost 					=> lost,					-- La Balle Sort de L'Ecran
				bluebox 				=> bluebox,				-- Pixel Courant = Case Bleue
				pad 					=> pad,					-- Pixel Courant = Raquette
				ball					=> ball,					-- Pixel Courant = Balle
				brick 				=> brick,				-- Pixel Courant = Brique
				red 					=> red,					-- Commande Affichage Rouge
				green 				=> green,				-- Commande Affichage Vert
				blue 					=> blue,					-- Commande Affichage Bleu
				brick_bounce 		=> brick_bounce,		-- Rebond Contre une Brique
				master_slave		=>	master_slave,		-- Selection Mode Esclave / Maitre
				game_type			=>	game_type,			-- Selection du Type de Jeu
				game_lost 			=> game_lost,			-- Timer du Mode Partie Perdue
				pause 				=> pause					-- Mode Pause
			);


-----------------------------------------------------------------------------------

	-- CONTROLEUR VGA
	vga_ctrl: entity work.VGA
			port map (
				clk25 	=> clk25,		-- Horloge 25 MHz
				reset 	=> reset,		-- Reset Asynchrone
				r			=> red,			-- Commande Affichage Rouge
				g 			=> green,		-- Commande Affichage Vert
				b 			=> blue,			-- Commande Affichage Bleu
				red 		=> VGA_red,			-- Affichage Pixel Rouge
				green 	=> VGA_green,		-- Affichage Pixel Vert
				blue 		=> VGA_blue,			-- Affichage Pixel Bleu
				vsync 	=> vsync,		-- Synchro Verticale
				hsync 	=> hsync,		-- Synchro Horizontale
				visible 	=> visible,		-- Zone Visible de l'Image
				endframe	=> endframe,	-- Fin de l'Image Visible
				xpos  	=> xpos,			-- Coordonnee X du Pixel Courant
				ypos  	=> ypos);		-- Coordonnee Y du Pixel Courant


-----------------------------------------------------------------


end Behavioral;

