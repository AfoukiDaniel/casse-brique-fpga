----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
-- Generation des Commandes Issues de l'Encodeur de l'Autre Carte
--		A Partir des Messages RS232 Recus
--
----------------------------------------------------------------------------------
library IEEE;use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity move_RS232 is
    Port ( 	clk25 				: in STD_LOGIC;							-- Horloge
				reset 				: in STD_LOGIC;							-- Reset Asynchrone
				
				master_slave		: in STD_LOGIC;							-- Selection Mode Console (Master) ou Manette (Esclave)
				
				-- COMMANDES ENCODEUR ROTATIF DE LA CARTE
				own_rot_left 		: in STD_LOGIC;							-- Rotation a Gauche
				own_rot_right		: in STD_LOGIC;							-- Rotation a Droite
				own_press 			: in STD_LOGIC;							-- Appui Bouton
				
				-- COMMANDES IP RS232
				byte_RX				: in STD_LOGIC_VECTOR(7 downto 0);	-- Donnee Recue par l'UART
				byte_TX				: out STD_LOGIC_VECTOR(7 downto 0);	-- Donnee a Envoyer a l'UART
				send					: out STD_LOGIC;							-- Demande de Transmission RS232
				incoming				: in STD_LOGIC;							-- Nouvelle Donnee Recue par l'UART
				
				-- COMMANDES ENCODEUR ROTATIF DE L'AUTRE CARTE
				other_rot_left 	: out STD_LOGIC;							-- Rotation a Gauche
				other_rot_right	: out STD_LOGIC;							-- Rotation a Droite
				other_press 		: out STD_LOGIC);							-- Appui Bouton
end move_RS232;

architecture Behavioral of move_RS232 is

-- Les Temporisations Permettent d'Eviter des "Fausses" Transmissions (A Cause des Rebonds...)

-- Gestion de l'Emission RS232
signal rqt_TX: std_logic;										-- Requete de Transmission RS232
signal ready_TX: std_logic;									-- Transmission RS232 Prete a Etre Effectuee
signal start_TX: std_logic;									-- Commande de Demarrage de Transmission RS232
signal message_TX: std_logic_vector(7 downto 0);		-- Message a Envoyer via le RS232
signal data_TX: std_logic_vector(7 downto 0);			-- Message a Envoyer au Buffer d'Emission du RS232
signal tempo_UART_TX:std_logic_vector(7 downto 0);		-- Temporisation pour la Réception de l'UART

-- Gestion de la Reception RS232
signal start_tempo_UART_RX: std_logic;						-- Gestion de la Temporisation en Réception de l'UART
signal tempo_UART_RX:std_logic_vector(8 downto 0);		-- Temporisation pour la Réception de l'UART
signal RS232_left: std_logic;									-- Commande Rotation a Gauche Recue par le RS232
signal RS232_right: std_logic;								-- Commande Rotation a Droite Recue par le RS232
signal RS232_press: std_logic;								-- Commande Appui Bouton Recue par le RS232


begin

-----------------------------------------------------------------------------------------------
	-- ACTIVATION / DESACTIVATION
	-- DE L'EMISSION OU DE LA RECEPTION RS232
	-- EN FONCTION DU MODE MAITRE OU ESCLAVE
	
	process(master_slave,data_TX,start_TX,RS232_left,RS232_right,RS232_press)
	
	begin
	
		-- Mode Esclave (Manette)
			-- Transmission d'Info vers une Autre Carte Possible via le RS232
			-- Pas de Reception d'Infos Possible via le RS232
		if master_slave = '0' then
		
			byte_TX 				<=	data_TX;
			send 					<= start_TX;
			other_rot_left 	<= '0';
			other_rot_right 	<= '0';
			other_press 		<= '0';
	
		-- Mode Maitre (Console)
			-- Pas de Transmission d'Info Possible via le RS232 Est Possible
			-- Reception d'Infos d'une Autre Carte Possible via le RS232
		else
		
			byte_TX 				<=	(others => '0');
			send 					<= '0';
			other_rot_left 	<= RS232_left;
			other_rot_right 	<= RS232_right;
			other_press 		<= RS232_press;
			
		end if;
	end process;
-----------------------------------------------------------------------------------------------
	

-----------------------------------------------------------------------------------------------
-- GESTION DE L'EMISSION RS232

	process(clk25,reset)

	begin

		if reset='0' then 
			
			message_TX		<= "00000000"; 
			data_TX 			<= "00000000";
			start_TX			<= '0'; 
			ready_TX			<= '0'; 
			tempo_UART_TX 	<= "00000000";
			rqt_TX			<= '0';
	
		elsif rising_edge(clk25) then
	
			-- Si On Est en Mode Manette (Emission RS232 Possible)
			-- 	Emission RS232 Impossible en Mode Console
			if master_slave = '0' then
			
				-- Si on a une Rotation a Gauche du Codeur de la Carte
				--	Generation du Message Correspondant et Demande de Transmission
				if own_rot_left = '1' then 
					message_TX <= "11110000"; 
					rqt_TX <= '1';
				end if;
			
				-- Si on a une Rotation a Droite du Codeur d la Carte
				--	Generation du Message  Correspondant et Demande de Transmission
				if own_rot_right = '1' then 
					message_TX <= "00001111"; 
					rqt_TX <= '1';
				end if;

				-- Si on Appuie sur le Bouton du Codeur
				--	Generation du Message  Correspondant et Demande de Transmission
				if own_press = '1' then 
					message_TX <= "10000001";
					rqt_TX <= '1';
				end if;

				-- Si on a une Requete de Transmission
				--	Chargement du Message et Indication Message Pret a Partir
				if rqt_TX = '1' then
					data_TX <= message_TX;
					ready_TX <= '1';
				end if;
			
				-- Si la Transmission RS232 Est Prete
					-- Activation de la Commande de Demarrage
					-- Demarrage de la Temporisation (pour Eviter des Envois Multiples)
				if ready_TX = '1' then
					start_TX <= '1';
					tempo_UART_TX <= tempo_UART_TX + 1;
				-- Sinon On Desactive la Commande de Demarrage
				else start_TX <= '0';
				end if;
			
				-- Quand on Arrive au Bout de la Temporisation
				--	On Reamorce le Dispositif de Gestion de la Transmission
				if tempo_UART_TX = "11111111" then
					tempo_UART_TX <= "00000000";
					ready_TX <= '0'; 
					rqt_TX <= '0';
					message_TX <= "00000000";
				end if;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------------------------
	

-----------------------------------------------------------------------------------------------
-- GESTION DE LA RECEPTION RS232
	
	-- GENERATION DES COMMANDES ISSUES DE L'ENCODEUR DE L'AUTRE CARTE
	--		A PARTIR DES MESSAGES RS232 RECUS

	process(clk25,reset)

	begin

		if reset='0' then 
			
			RS232_right <= '0';
			RS232_left <= '0';
			RS232_press <= '0';
			start_tempo_UART_RX <= '0';
			tempo_UART_RX <= (others => '0');
		
		elsif rising_edge(clk25) then
	
			-- Par Defaut, Pas de Commandes de Deplacement
			RS232_right <= '0';
			RS232_left <= '0';
			RS232_press <= '0';
			
			-- Si On Est en Mode Console (Reception RS232 Possible)
			-- 	Reception RS232 Impossible en Mode Manette
			if master_slave = '1' then
				
				-- Si On N'Est Pas Dans une Phase de Temporisation
				if start_tempo_UART_RX = '0' then
					
					-- Si une Nouvelle Donnee Est Disponible
					if incoming ='1' then
					
						-- Reception de la Commande Deplacement A Droite
						--		Demarrage de la Temporisation
						if byte_RX = "00001111" then
							RS232_right <= '1';
							start_tempo_UART_RX <= '1';
		
						-- Reception de la Commande Deplacement A Gaiche
						--		Demarrage de la Temporisation
						elsif byte_RX = "11110000" then
							RS232_left <= '1';
							start_tempo_UART_RX <= '1';
		
						-- Reception de la Commande Appui du Bouton
						--		Demarrage de la Temporisation
						elsif byte_RX = "10000001" then
							RS232_press <= '1';
							start_tempo_UART_RX <= '1';
						end if;
					end if;
				
				-- Si On Est dans une Phase de Temporisation
				else
					
					
					-- On Incremente le Compteur de Temporisation
					-- A la Valeur Max, on Sort de la Temporisation
					tempo_UART_RX <= tempo_UART_RX + 1;
					
					if tempo_UART_RX = "111111111" then

						tempo_UART_RX <= (others => '0');
						start_tempo_UART_RX <= '0';

					end if;
				end if;

				-- Remise a 0 des Commandes Recues par le RS232
				if RS232_left = '1' then
					RS232_left <= '0';
				end if;

				if RS232_right = '1' then
					RS232_right <= '0';
				end if;

				if RS232_press = '1' then
					RS232_press <= '0';
				end if;

			end if;
		end if;
	end process;


end Behavioral;

