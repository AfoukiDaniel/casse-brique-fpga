----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Gestion des Boutons Nord / Sud / Est de la Carte
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity button_mgr is
    Port (	clk25 : 				in  STD_LOGIC;		-- Horloge 25 MHz
				reset : 				in  STD_LOGIC;		-- Reset Asynchrone
				nord : 				in  STD_LOGIC;		-- Bouton Nord
				sud : 				in  STD_LOGIC;		-- Bouton Sud
				est : 				in  STD_LOGIC;		-- Bouton Est
				press_sud : 		out  STD_LOGIC;	-- Drapeau Appui sur le Bouton Sud
				press_nord_est : 	out  STD_LOGIC);	-- Drapeau Appui sur le Bouton Nord Ou Est
end button_mgr;

architecture Behavioral of button_mgr is

signal appui_sud,appui_nord_est: std_logic;			-- Appui sur l'un des Trois Boutons
signal compteur: std_logic_vector(21 downto 0);		-- Temporisation pour l'Anti Rebond des Boutons
signal max_value: std_logic_vector(21 downto 0);	-- Valeur Maximale du Compteur
signal lock: std_logic;										-- Verrou pour Lier l'Appui au 1er Front de Bouton

begin

	press_sud <= appui_sud;						-- Connection au Port de Sortie
	press_nord_est <= appui_nord_est;		-- Connection au Port de Sortie

	max_value <= (others => '1');		-- Valeur Max du Compteur

	-- Gestion de l'Anti-Rebond des Boutons
	-- 	Et Generation du Signal Appui
	process(clk25,reset)
	
	begin
	
		-- Le Verrou est Active si on Appuie sur un des Boutons et que le Compteur est au Max
		-- Le Verrou est Desactive si on Relache les Boutons
		
		-- Le Compteur Se Decremente 
		
		if reset = '0' then
		
			compteur <= (others => '1');
			appui_sud <= '0';
			appui_nord_est <= '0';
			lock <= '0';
			
		elsif rising_edge(clk25) then
		
			-- Si on a pas Detecte d'Appui sur un Bouton
				-- ie. Compteur = Valeur Max ET Pas de Verrou
			if (compteur = max_value) and (lock = '0') then
			
				-- Si On Appuie sur le Bouton Sud
				if sud = '1' then
				
					-- Verrouillage et Mise a 1 du Flag Appui
					appui_sud <= '1';
					compteur <= compteur - 1;
					lock <= '1';
				
				end if;

				-- Si On Appuie sur le Bouton Nord ou Est
				if (nord or est) = '1' then
				
					-- Verrouillage et Mise a 1 du Flag Appui
					appui_nord_est <= '1';
					compteur <= compteur - 1;
					lock <= '1';
				
				end if;
			
			end if;
			
			-- Si on a Detecte un Appui sur un des Boutons
				-- ie. Compteur < Valeur Max ET Verrou Actif
			if (lock = '1') and (compteur /= max_value) then
				
				-- Le Compteur se Decremente
				compteur <= compteur - 1;
			
			end if;
			
			-- Si on Attend que l'On Relache le Bouton
				-- ie. Compteur a fini de compter ET Verrou Actif
			if (lock = '1') and (compteur = max_value) then
				
				-- Si les Boutons Sont Relaches
					-- Deverrouillage
				if sud = '0' and (nord or est)= '0' then
					lock <= '0';
				end if;
				
			end if;
			
			-- Mise a 0 de Appui s'Il Etait Auparavant a 1
				-- Appui Ne Reste a 1 que Pendant 1 Cycle
			if appui_sud = '1' then 
				appui_sud <= '0';
			end if;

			if appui_nord_est = '1' then 
				appui_nord_est <= '0';
			end if;
		end if;
	end process;

end Behavioral;

