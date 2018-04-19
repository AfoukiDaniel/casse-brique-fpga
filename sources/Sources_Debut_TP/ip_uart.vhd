----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
-- Gestion du Port Serie RS232
--		Transmission des Commandes de l'Encodeur ROtatif d l'Autre Carte
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ip_uart is
    Port ( clk25 				: in  STD_LOGIC;		-- Horloge
           reset 				: in  STD_LOGIC;		-- Reset Asynchrone
           master_slave		: in STD_LOGIC;		-- Motre Maitre/Console(=1) ou Esclave/Manette (=0)
           own_rot_left 	: in STD_LOGIC;		-- Commande Rotation a Gauche du Codeur de la Carte
           own_rot_right	: in STD_LOGIC;		-- Commande Rotation a Droite du Codeur de la Carte
           own_press 		: in STD_LOGIC;		-- Appui Bouton du Codeur de la Carte
			  txd 				: out STD_LOGIC;		-- Sortie RS232
           rxd 				: in  STD_LOGIC;		-- Entree RS232
           other_rot_left 	: out STD_LOGIC;		-- Commande Rotation a Gauche du Codeur Autre Carte
           other_rot_right	: out STD_LOGIC;		-- Commande Rotation a Droite du Codeur Autre Carte
           other_press 		: out STD_LOGIC);		-- Appui Bouton du Codeur Autre Carte
end ip_uart;

architecture Behavioral of ip_uart is

signal byte_RX: std_logic_vector(7 downto 0);		-- Donnee Recue par l'UART
signal byte_TX: std_logic_vector(7 downto 0);		-- Donnee a Envoyer a l'UART
signal send: std_logic;										-- Demande de Transmission RS232
signal incoming: std_logic;								-- Nouvelle Donnee Recue par l'UART

begin

-----------------------------------------------------------------------------------------
	-- UART CONTROLLER
	RS232: entity work.UARTcomponent
		port map(
			CLK		=> clk25,		-- Horloge
			RST		=> reset,		-- Reset Asynchrone
			TXD 		=> txd,			-- Sortie RS232
			RXD 		=> rxd,			-- Entree RS232
			DBIN 		=> byte_TX,		-- Donnee a Transmettre par l'UART
			DBOUT 	=> byte_RX,		-- Donnee Recue par l'UART
			INCOMING => incoming,	-- Nouvelle Donnee Recue
			WR			=> send			-- Demande de Transmission
	);


-----------------------------------------------------------------------------------------
	-- GENERATION DES COMMANDES ISSUES DE L'ENCODEUR DE L'AUTRE CARTE
	--		A PARTIR DES MESSAGES RS232 RECUS
	direction: entity work.move_RS232
		port map(
			clk25					=> clk25,				-- Horloge
			reset					=> reset,				-- Reset Asynchrone
			master_slave 		=> master_slave,		-- Motre Maitre/Console(=1) ou Esclave/Manette (=0)
			own_rot_left		=> own_rot_left,		-- Commande Rotation a Gauche du Codeur de la Carte
			own_rot_right		=> own_rot_right,		-- Commande Rotation a Droite du Codeur de la Carte
			own_press			=> own_press,			-- Appui Bouton du Codeur de la Carte
			byte_TX				=> byte_TX,				-- Donnee a Transmettre par l'UART
			byte_RX 				=> byte_RX,				-- Donnee Recue par l'UART
			incoming 			=> incoming,			-- Nouvelle Donnee Recue
			send					=> send,					-- Demande de Transmission
			other_rot_left		=> other_rot_left,	-- Commande Rotation a Gauche du Codeur Autre Carte
			other_rot_right	=> other_rot_right,	-- Commande Rotation a Droite du Codeur Autre Carte
			other_press			=> other_press			-- Appui Bouton du Codeur Autre Carte
	);

-----------------------------------------------------------------------------------------

end Behavioral;

