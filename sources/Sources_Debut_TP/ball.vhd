----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Gestion de la Balle
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ball is
	Port(	clk25 : in  STD_LOGIC;								-- Horloge
			reset : in  STD_LOGIC;								-- Reset Asynchrone
           
			-- PARAMETRES D'AFFICHAGE
			xpos : in  STD_LOGIC_VECTOR(9 downto 0);		-- Coordonnees X du Pixel Courant
			ypos : in  STD_LOGIC_VECTOR(9 downto 0);		-- Coordonnees Y du Pixel Courant
			endframe : in  STD_LOGIC;							-- Fin de l'Image Visible
           
			-- PARAMETRES DU JEU
			pause : in  STD_LOGIC;								-- Commande Pause
			speed : in  STD_LOGIC;								-- Vitesse du Jeu
			game_lost: in std_logic;							-- Mode Echec
			  
			-- PARAMETRES DE REBOND
			leftbounce : in  STD_LOGIC;						-- Rebond Contre Mur Gauche
			rightbounce : in  STD_LOGIC;						-- Rebond Contre Mur Droit
			ybounce : in  STD_LOGIC;							-- Rebond Contre Brique ou Mur Haut ou Mur Bas
			barrier_bounce: in STD_LOGIC;						-- Rebond Contre l'Obstacle (Pong)
			pong_left_bounce : in STD_LOGIC;					-- Rebond sur Raquette Gauche (Pong)
			pong_right_bounce : in STD_LOGIC;				-- Rebond sur Raquette Droite (Pong)
			pad_far_left_bounce : in STD_LOGIC;				-- Rebond sur Partie Extreme Gauche de Raquette
			pad_left_bounce : in  STD_LOGIC;					-- Rebond sur Partie Gauche Raquette
			pad_center_bounce : in  STD_LOGIC;				-- Rebond sur Partie Centrale Raquette
			pad_right_bounce : in  STD_LOGIC;				-- Rebond sur Partie Droite Raquette
			pad_far_right_bounce : in  STD_LOGIC;			-- Rebond sur Partie Extreme Droite Raquette
           
			-- BALLE
			ball : out  STD_LOGIC);								-- Pixel Courant = Balle
end ball;

architecture Behavioral of ball is

-- Gestion de la Balle
signal xball,yball: std_logic_vector(9 downto 0);		-- Coordonnees de la Balle
signal inc_type: integer range 0 to 15;					-- Choix du Pas de Deplacement de la Balle
signal xinc: integer range -5 to 5;							-- Pas de Deplacement Horizontal de la Balle
signal yinc: integer range -5 to 5;							-- Pas de Deplacement Vertical de la Balle

-- Raquette Casse Briques et Rebonds
signal zone_pad_bounce: std_logic_vector(4 downto 0);	-- Zone de la Raquette ou a Lieu le Rebond (Casse Briques)
signal lock: std_logic;											-- Verrou: Evite de Multiples Rebonds sur la Raquette

-- Raquettes Pong et Rebonds
signal pong_bounce: std_logic_vector(1 downto 0);		-- Rebond Detecte sur une des Deux Raquettes
signal tempo: std_logic_vector(2 downto 0);				-- Temporisation: Evite des Rebonds Multiples
signal tempo_start: std_logic;								-- Gestion de la Temporisation

signal barrier_bounce_ok: std_logic;						-- Indicateur de Rebond Contre l'Obstacle (Pong)


begin


	-- DETECTION DU REBOND DE LA BALLE SUR LA RAQUETTE
	process(clk25,reset)
	
	begin
		
		if reset='0' then 
		
			zone_pad_bounce <= "00000"; 
			pong_bounce <= "00";
			lock <= '0'; 
			tempo <= "000"; 
			tempo_start <= '0';
			barrier_bounce_ok <= '0';
			
		elsif rising_edge(clk25) then
	
		-- REBOND DES RAQUETTES OU DE L'OBSTACLE DU PONG
			
			-- A Chaque Cycle D'Horloge
				--	Si On A Pas Encore Detecte de Rebond Contre les Raquettes
				--	Et que l'on Est Pas En Mode Temporisation
			if (pong_bounce = "00") and (tempo = "000") then
			
				-- On Echantillonne les Indicateurs de Rebond sur les Raquetes
				pong_bounce <= pong_left_bounce & pong_right_bounce;
				
			end if;			
			
				--	Si On A Pas Encore Detecte de Rebond Contre l'Obstacle
				--	Et que l'on Est Pas En Mode Temporisation
			if (barrier_bounce_ok = '0') and (tempo = "000") then
			
				-- On Echantillonne l'Indicateur de Rebond Contre l'Obstacle
				barrier_bounce_ok <= barrier_bounce;
				
			end if;			
			

			-- A la Fin de Chaque Image
			if endframe = '1' then
			
				-- Si On A Detecte un Rebond Contre une Raquette au Cours de l'Image
				if pong_bounce /= "00" then
					-- RAZ du Detecteur de Rebond et Debut de la Temporisation
					pong_bounce <= "00"; 
					tempo_start <= '1'; 
					tempo <= "001";
				end if;
				
				-- Si On A Detecte un Rebond contre l'Obstacle au Cours de l'Image
				if barrier_bounce_ok = '1'  then
					-- RAZ du Detecteur de Rebond et Debut de la Temporisation
					barrier_bounce_ok <= '0'; 
					tempo_start <= '1'; 
					tempo <= "001";
				end if;

				-- Gestion de la Temporisation
				if tempo_start='1' then 
					tempo <= tempo+1;
				end if;
			
				-- Arret de la Temporisation
				if tempo = "111" then 
					tempo <= "000"; 
					tempo_start <= '0';
				end if;
			
			end if;
			
		-- REBOND DE LA RAQUETTE DU CASSE BRIQUE
			
			-- A Chaque Cycle D'Horloge
				-- Si On A Pas Encore Detecte de Rebond sur la Raquette
			if (zone_pad_bounce = "00000") then
	
				-- Echantillonnage des flags de rebond
				-- Concatenation dans un  Vecteur Zone de la Raquette
				zone_pad_bounce <= 	pad_far_left_bounce 	& pad_left_bounce 	& 
											pad_center_bounce 	& pad_right_bounce 	& pad_far_right_bounce;

			-- Si on a Detecte un Rebond, alors...
			else
			
				-- A la Fin de Chaque Image
				if endframe = '1' then
				
					-- RAZ du Detecteur de Rebond et Verrouillage
					--		Le Verrou Empeche la Detection de Rebonds Multiples sur la Raquette
					zone_pad_bounce <= "00000"; 
					lock <= '1'; 
				end if;
			end if;
			
			-- Deverrouillage si la Balle Touche un Mur ou une Brique
			if (leftbounce or rightbounce or ybounce) = '1' then
				
				lock<='0';
			end if;
		end if;
	
	end process;
	
---------------------------------------------------------------------------------------------------------------------


	-- CALCUL DE LA TRAJECTOIRE DE LA BALLE
	
		-- 12 Trajectoires Possibles
			--	INC_TYPE		DIRECTION 		DIRECTION		ANGLE PAR RAPPORT
			--					HORIZONTALE		VERTICALE		A LA VERTICALE
			--------------------------------------------------------------------------------------------------------------
			--		0				GAUCHE			BAS				70°
			--		1				GAUCHE			BAS				45°
			--		2				GAUCHE			BAS				20°
			--		3				DROITE			BAS				20°
			--		4				DROITE			BAS				45°
			--		5				DROITE			BAS				70°
			--		10				GAUCHE			HAUT				70°
			--		11				GAUCHE			HAUT				45°
			--		12				GAUCHE			HAUT				20°
			--		13				DROITE			HAUT				20°
			--		14				DROITE			HAUT				45°
			--		15				DROITE			HAUT				70°

	process(clk25,reset)
	
	begin
	
		if reset='0' then 

			inc_type <= 4;
			-- Position Intiale de la Balle
			xball <= "0101100000"; -- 352
			yball <= "0010100000"; -- 160
			
		elsif rising_edge(clk25) then
		
			-- Si On N'Est pas en Mode Pause
			if pause = '0' then
			
				-- A la Fin de Chaque Trame
					-- On Va Verifier S'il Y a Eu un Rebond
				if endframe = '1' then
			
					-- Si la Balle Rebondit sur le Mur Gauche ou la Raquette Gauche (Pong)
					if (leftbounce or pong_bounce(1))= '1' then
				
						-- Inversion de la Direction Horizontale
						-- Conservation de la Direction Verticale et de l'Angle
						case inc_type is
					
							when 3		=>	inc_type <= 2;	
												xball <= xball + 2; 
												yball <= yball + 4;

							when 4		=>	inc_type <= 1;	
												xball <= xball + 4; 
												yball <= yball + 4;

							when 5		=>	inc_type <= 0;	
												xball <= xball + 4; 
												yball <= yball + 2;

							when 13		=>	inc_type <= 12;
												xball <= xball + 2;
												yball <= yball - 4;

							when 14		=>	inc_type <= 11;
												xball <= xball + 4;
												yball <= yball - 4;

							when 15		=>	inc_type <= 10; 
												xball <= xball + 4;
												yball <= yball - 2;

							when others	=>	NULL;
						end case;
				
					-- Si la Balle Rebondit sur le Mur Droit ou la Raquette Droite (Pong)
					elsif (rightbounce or pong_bounce(0))= '1' then
				
						-- Inversion de la Direction Horizontale
						-- Conservation de la Direction Verticale et de l'Angle
						case inc_type is
					
							when 0		=>	inc_type <= 5;
												xball <= xball - 4;
												yball <= yball + 2;

							when 1		=>	inc_type <= 4;
												xball <= xball - 4;
												yball <= yball - 4;

							when 2		=>	inc_type <= 3;
												xball <= xball - 2;
												yball <= yball + 4;

							when 10		=>	inc_type <= 15;
												xball <= xball - 4;
												yball <= yball - 2;

							when 11		=>	inc_type <= 14;
												xball <= xball - 4;
												yball <= yball - 4;

							when 12		=>	inc_type <= 13;
												xball <= xball - 2;
												yball <= yball - 4;
							
							when others	=>	NULL;
						end case;

					-- Si la Balle Rebondit Contre le Mur du Haut, du Bas ou une Brique 
					elsif ybounce = '1' then
				
						-- Inversion de la Direction Verticale
						-- Conservation de la Direction Horizontale et de l'Angle
						case inc_type is
					
							when 0		=>	inc_type <= 10;
												xball <= xball + 4;
												yball <= yball - 2;

							when 1		=>	inc_type <= 11;
												xball <= xball + 4;
												yball <= yball - 4;

							when 2		=>	inc_type <= 12;
												xball <= xball + 2;
												yball <= yball - 4;

							when 3		=>	inc_type <= 13;
												xball <= xball - 2;
												yball <= yball - 4;

							when 4		=>	inc_type <= 14;
												xball <= xball - 4;
												yball <= yball - 4;

							when 5		=>	inc_type <= 15;
												xball <= xball - 4;
												yball <= yball - 2;

							when 10		=>	inc_type <= 0;
												xball <= xball + 4;
												yball <= yball + 2;

							when 11		=>	inc_type <= 1;
												xball <= xball + 4;
												yball <= yball + 4;

							when 12		=>	inc_type <= 2;
												xball <= xball + 2;
												yball <= yball + 4;

							when 13		=>	inc_type <= 3;
												xball <= xball - 2;
												yball <= yball + 4;

							when 14		=>	inc_type <= 4;
												xball <= xball - 4;
												yball <= yball + 4;

							when 15		=>	inc_type <= 5;
												xball <= xball - 4;
												yball <= yball + 2;

							when others	=>	NULL;
						end case;

					-- Si la Balle Rebondit Contre la Barriere (Jeu Pong)
					elsif barrier_bounce_ok = '1' then
				
						-- Inversion de la Direction Horizontale
						-- Conservation de la Direction Verticale et de l'Angle
						case inc_type is
					
							when 0		=>	inc_type <= 5;
												xball <= xball + 4;
												yball <= yball + 2;

							when 1		=>	inc_type <= 4;
												xball <= xball + 4;
												yball <= yball + 4;

							when 2		=>	inc_type <= 3;
												xball <= xball + 2;
												yball <= yball + 4;

							when 3		=>	inc_type <= 2;
												xball <= xball - 2;
												yball <= yball + 4;

							when 4		=>	inc_type <= 1;
												xball <= xball - 4;
												yball <= yball + 4;

							when 5		=>	inc_type <= 0;
												xball <= xball - 4;
												yball <= yball + 2;

							when 10		=>	inc_type <= 15;
												xball <= xball + 4;
												yball <= yball - 2;

							when 11		=>	inc_type <= 14;
												xball <= xball + 4;
												yball <= yball - 4;

							when 12		=>	inc_type <= 13;
												xball <= xball + 2;
												yball <= yball - 4;

							when 13		=>	inc_type <= 12;
												xball <= xball - 2;
												yball <= yball - 4;

							when 14		=>	inc_type <= 11;
												xball <= xball - 4;
												yball <= yball - 4;

							when 15		=>	inc_type <= 10;
												xball <= xball - 4;
												yball <= yball - 2;

							when others	=>	NULL;
						end case;

					-- Si la Balle Rebondit Contre la Raquette (Casse Briques)
					elsif (zone_pad_bounce /= "00000") and (lock = '0') then
					
						case zone_pad_bounce is
				
							-- Si on Rebondit sur la Partie Extreme Gauche de la Raquette
							when "10000"	=> 
								case inc_type is

									when 0		=>	inc_type <= 13;
														xball <= xball - 2;
														yball <= yball - 4;
									
									when 1		=>	inc_type <= 14;
														xball <= xball - 4;
														yball <= yball - 4;
									
									when others	=>	inc_type <= 15;
														xball <= xball - 4;
														yball <= yball - 2;
								end case;
				
							-- Si on Rebondit sur la Partie Gauche de la Raquette
							when "01000"	=> 
								case inc_type is
									
									when 0		=>	inc_type <= 11;
														xball <= xball + 4;
														yball <= yball - 4;

									when 1		=>	inc_type <= 12;
														xball <= xball + 2;
														yball <= yball - 4;

									when 2		=>	inc_type <= 13;
														xball <= xball - 2;
														yball <= yball - 4;

									when 3		=>	inc_type <= 14;
														xball <= xball - 4;
														yball <= yball - 4;

									when 4		=>	inc_type <= 15;
														xball <= xball - 4;
														yball <= yball - 2;

									when others	=>	inc_type <= 15;
														xball <= xball - 4;
														yball <= yball - 2;
								end case;

							-- Si on Rebondit sur la Partie Centrale de la Raquette
							when "00100"	=> 
								case inc_type is
									
									when 0		=>	inc_type <= 10;
														xball <= xball + 4;
														yball <= yball - 2;
									
									when 1		=>	inc_type <= 11;
														xball <= xball + 4;
														yball <= yball - 4;
									
									when 2		=>	inc_type <= 12;
														xball <= xball + 2;
														yball <= yball - 4;
									
									when 3		=>	inc_type <= 13;
														xball <= xball - 2;
														yball <= yball - 4;
									
									when 4		=>	inc_type <= 14;
														xball <= xball - 4;
														yball <= yball - 4;
									
									when others	=>	inc_type <= 15;
														xball <= xball - 4;
														yball <= yball - 2;
								end case;

							-- Si on Rebondit sur la Partie Droite de la Raquette
							when "00010"	=> 
								case inc_type is
										
									when 0		=>	inc_type <= 10;
														xball <= xball + 4;
														yball <= yball - 2;
										
									when 1		=>	inc_type <= 10;
														xball <= xball + 4;
														yball <= yball - 2;
										
									when 2		=>	inc_type <= 11;
														xball <= xball + 4;
														yball <= yball - 4;
										
									when 3		=>	inc_type <= 12;
														xball <= xball + 2;
														yball <= yball - 4;
										
									when 4		=>	inc_type <= 13;
														xball <= xball - 2;
														yball <= yball - 4;
										
									when others	=>	inc_type <= 14;
														xball <= xball - 4;
														yball <= yball - 4;
									end case;

							-- Si on Rebondit sur la Partie Extreme Droite de la Raquette
							when "00001"	=> 
								case inc_type is
								
									when 0		=>	inc_type <= 10;
														xball <= xball - 4;
														yball <= yball - 2;
				
									when 1		=>	inc_type <= 10;
														xball <= xball - 4;
														yball <= yball - 2;

									when 2		=>	inc_type <= 10;
														xball <= xball - 4;
														yball <= yball - 2;

									when 3		=>	inc_type <= 10;
														xball <= xball - 4;
														yball <= yball - 2;

									when 4		=>	inc_type <= 11;
														xball <= xball - 4;
														yball <= yball - 2;

									when others	=>	inc_type <= 12;
														xball <= xball - 4;
														yball <= yball - 2;
								end case;
						
							when others			=> NULL;
						end case;

					-- Si la Balle ne Rebondit Pas,  Elle Conserve Sa Trajectoire
					else 
						xball <= xball + xinc;
						yball <= yball + yinc;
				
					end if;
				end if;
			end if;
			
			-- Si on Est en Mode "Perdu"
			-- On Remet la Balle en Position Initiale
			if (endframe = '1') and (game_lost = '1') then 
				xball <= "0101100000";
				yball <= "0010100000";
			end if;
		end if;
	end process;

-------------------------------------------------------------------------------------------------------------

	-- CALCUL DE L'INCREMENT DE LA POSITION DE LA BALLE EN FONCTION DU TYPE DE TRAJECTOIRE
	process (inc_type,speed)
	
		begin

			-- Increment par Défaut
			xinc <= -4; yinc <= 4;

			-- Si on Est en Mode Rapide
			if speed ='1' then
			
				case inc_type is
			
--					when 0		=>		xinc <= 5;	yinc <= 2;
--					when 1		=>		xinc <= 4;	yinc <= 4;
--					when 2		=>		xinc <= 2;	yinc <= 5;
--					when 3		=>		xinc <= -2;	yinc <= 5;
--					when 4		=>		xinc <= -4;	yinc <= 4;
--					when 5		=>		xinc <= -5;	yinc <= 2;
--					when 10		=>		xinc <= 5;	yinc <= -2;
--					when 11		=>		xinc <= 4;	yinc <= -4;
--					when 12		=>		xinc <= 2;	yinc <= -5;
--					when 13		=>		xinc <= -2;	yinc <= -5;
--					when 14		=>		xinc <= -4;	yinc <= -4;
--					when 15		=>		xinc <= -5;	yinc <= -2;

					when 0		=>		xinc <= 4;	yinc <= 2;
					when 1		=>		xinc <= 4;	yinc <= 4;
					when 2		=>		xinc <= 2;	yinc <= 4;
					when 3		=>		xinc <= -2;	yinc <= 4;
					when 4		=>		xinc <= -4;	yinc <= 4;
					when 5		=>		xinc <= -4;	yinc <= 2;
					when 10		=>		xinc <= 4;	yinc <= -2;
					when 11		=>		xinc <= 4;	yinc <= -4;
					when 12		=>		xinc <= 2;	yinc <= -4;
					when 13		=>		xinc <= -2;	yinc <= -4;
					when 14		=>		xinc <= -4;	yinc <= -4;
					when 15		=>		xinc <= -4;	yinc <= -2;

					when others	=>		NULL;
				end case;

			-- Mode Lent
			else
			
				case inc_type is
			
					when 0		=>		xinc <= 2;	yinc <= 1;
					when 1		=>		xinc <= 2;	yinc <= 2;
					when 2		=>		xinc <= 1;	yinc <= 2;
					when 3		=>		xinc <= -1;	yinc <= 2;
					when 4		=>		xinc <= -2;	yinc <= 2;
					when 5		=>		xinc <= -2;	yinc <= 1;
					when 10		=>		xinc <= 2;	yinc <= -1;
					when 11		=>		xinc <= 2;	yinc <= -2;
					when 12		=>		xinc <= 1;	yinc <= -2;
					when 13		=>		xinc <= -1;	yinc <= -2;
					when 14		=>		xinc <= -2;	yinc <= -2;
					when 15		=>		xinc <= -2;	yinc <= -1;
					when others	=>		NULL;
				end case;
			end if;
	end process;

------------------------------------------------------------------

	-- GESTION DU FLAG BALLE
		-- Flag = 1 si le Pixel Courant
		-- Est un des 64 Pixels de la Balle
	process (xball,yball,xpos,ypos)

		begin

			ball <= '0';
	
			if (xpos >= xball) and (xpos <= xball+7) and
				(ypos >= yball) and (ypos <= yball+7) then
					ball<='1';
			end if;

	end process;

------------------------------------------------------------------


end Behavioral;

