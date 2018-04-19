----------------------------------------------------------------------------------
-- Company: UPMC
-- Engineer: Julien Denoulet
-- 
--	Interface Serie RS232
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UARTcomponent is
	Port(	CLK 		: in  std_logic;								-- Clock 50 MHz
			RST		: in  std_logic;								-- Reset Asynchrone
			TXD 		: out std_logic;								-- Sortie Serie RS232
			RXD 		: in  std_logic;								-- Entree Serie RS232
			DBIN 		: in  std_logic_vector (7 downto 0);	-- Octet a Transmettre
			DBOUT 	: out std_logic_vector (7 downto 0);	-- Octet Recu
			INCOMING	: out std_logic;								-- Nouvel Octet Recu
			WR			: in  std_logic								-- Demande de Transfert
		);
end UARTcomponent;

architecture Behavioral of UARTcomponent is

------------------------------------------------------------------------
--  Declarations
------------------------------------------------------------------------
	-- Etats pour la MAE de la Reception
	type RX_State is (					  
		IDLE,			-- Repos
		DELAY,		-- Decalage de 8 Cycles d'Horloge pour Echantillonner au milieu du Bit Time
		GET_DATA,	-- Acquisition des 8 Bits du Message et du Bit de Parite
		STOP			-- Bit de Stop
	);

	-- Etats pour la MAE de la Transmission
	type TX_STATE is (
		IDLE,			-- Repos
		TRANSFER,	-- Chargement de la Donnee dans le Buffer d'Emission
		SEND_DATA	-- Envoi du Message
	);

	-- Etats pour la MAE du bit Start_TX
	type STX_STATE is (
		IDLE,			-- Repos
		SET_STX,		-- Debut de la Transmission
		WAIT_LOAD,	-- Attente du Chargement de la Donnee
		WAIT_WRITE	-- Attente du Passage a 0 de la Demande de Transmission
	);

	-- Signaux d'Etat Present et Futur des 3 MAE
	signal RX_EF,	RX_EP		:  RX_STATE	:= IDLE;
	signal TX_EF,	TX_EP		:  TX_STATE	:= IDLE;
	signal STX_EF,	STX_EP	:  STX_STATE:= IDLE;
		
	signal BaudDivide : std_logic_vector(7 downto 0); -- Diviseur D'Horloge pour le Debit de Transmission

	signal RD_REG: std_logic_vector(7 downto 0);		-- Registre de Sortie
	signal RX_BUF: std_logic_vector(9 downto 0);		-- Buffer de Reception
	signal RX_SHIFT: std_logic;							-- Commande de Decalage du Buffer de Reception

	signal WR_REG: std_logic_vector(7 downto 0);		-- Registre d'Entree
	signal TX_BUF: std_logic_vector(10 downto 0);	-- Buffer d'Emission
	signal TX_LOAD: std_logic;								-- Chargement du Buffer d'Emission
	signal TX_SHIFT: std_logic;							-- Decalage du Buffer d'Emission

	signal ClkDiv: std_logic_vector(8 downto 0);		-- Diviseur pour l'Horloge de Reception
	signal RX_CLK: std_logic;								-- Horloge de Reception
	signal TX_CLK: std_logic;								-- Horloge d'Emission

	signal TX_BIT_TIME: std_logic_vector(3 downto 0); 	-- Compteur des 16 cycles du Bit Time en Emission

	signal RX_BIT_TIME: std_logic_vector(3 downto 0);	-- Compteur des 16 cycles du Bit Time en Reception
	signal RX_BIT_TIME_RAZ: std_logic;						-- RAZ du Bit Time en Reception

	signal RX_BIT_NB: std_logic_vector(3 downto 0);	-- Nombre de Bits Recus
	signal RX_BIT_NB_RAZ: std_logic;						-- RAZ du Nombre de Bit Recus
	signal RX_BIT_NB_INC: std_logic;						-- Incrementation du Nombre de Bits Recus

	signal TX_BIT_NB: std_logic_vector(3 downto 0);	-- Nombre de Bits Transmis
   signal TX_BIT_NB_RAZ: std_logic;						-- RAZ du Nombre de Bit Transmis

	signal Start_TX: std_logic;							-- Signal de Debut de Transmission
	signal RX_End: std_logic;								-- Signal de Fin de Transmission
	signal Parity: std_logic;								-- Bit de Parite



begin
	
--------------------------------------------------------------------------
-- 									SIGNAUX DIVERS										--
--------------------------------------------------------------------------
	BaudDivide <= "10100011"; -- 163 (25 MHz / 163 / 16 = 9600 Bauds)
	
	-- Sortie de l'Octet Recu
	DBOUT <= RD_REG;
	-- Entree de l'Octet a Transmettre
	WR_REG <= DBIN;
	-- Calcul du Bit de Parite
	Parity <=  not ( 	((WR_REG(0) xor WR_REG(1)) xor 
							(WR_REG(2) xor WR_REG(3))) xor 
							((WR_REG(4) xor WR_REG(5)) xor 
							(WR_REG(6) xor WR_REG(7))) );

	
------------------------------------------------------------------
	-- Generation du Signal INCOMING
	process(CLK,RST)
		begin
		
			if RST = '0' then
				INCOMING <= '0';
			elsif rising_edge(CLK) then
				INCOMING <= RX_End;
			end if;
	end process;
------------------------------------------------------------------
	
--------------------------------------------------------------------------
-- 						SIGNAUX D'HORLOGE ET BIT TIME 							--
--------------------------------------------------------------------------

	-- Compteur pour Generer l'Horloge de Reception
	process (CLK,RST)
		begin
			if RST = '0' then
				ClkDiv <= (others => '0');
			elsif rising_edge(CLK) then
				if (ClkDiv = BaudDivide) then
					ClkDiv <= (others => '0');
				else
					ClkDiv <= ClkDiv +1;
				end if;
			end if;
	end process;
------------------------------------------------------------------

	-- Horloge de Reception
	process (RST,CLK)
		begin
			if RST = '0' then
				RX_CLK <= '0';
			elsif rising_edge(CLK) then
				-- Changement d'Etat de RX_CLK tous les 163 Cycles
				if ClkDiv = "10100011" then
					RX_CLK <= not RX_CLK;
				end if;
			end if;
	end process;	
------------------------------------------------------------------

	-- Generation du RX_BIT_TIME (15 Periodes de RX_CLK)
	process (RX_CLK,RST)
		begin
			if RST = '0' then
				RX_BIT_TIME <= "0000";
			elsif rising_edge(RX_CLK) then
				-- Reinitialisation
				if RX_BIT_TIME_RAZ = '1' then
					RX_BIT_TIME <= "0000";
				-- Incrementation
				else
					RX_BIT_TIME <= RX_BIT_TIME +1;
				end if;
			end if;
	end process;
------------------------------------------------------------------

	-- Generation du TX_BIT_TIME (16 Periodes de RX_CLK)
	process (RST,RX_CLK)
		begin
			if RST = '0' then
				TX_BIT_TIME <= "0000";
			elsif rising_edge(RX_CLK) then
				TX_BIT_TIME <= TX_BIT_TIME +1;
			end if;
	end process;
------------------------------------------------------------------

	-- Horloge de Transmission (Periode = 16 Cycles de RX_CLK
	TX_CLK <= TX_BIT_TIME(3);
------------------------------------------------------------------

--------------------------------------------------------------------------
-- 								GESTION DE L'EMISSION 								--
--------------------------------------------------------------------------

	-- MAE de l'Emission
  	-- Registre d'Etat
	process (TX_CLK, RST)
		begin
			if RST = '0' then 
				TX_EP <= IDLE;
			elsif rising_edge(TX_CLK) then
				TX_EP <= TX_EF;
			end if;
	end process;
		
	-- MAE de l'Emission
	-- Calcul de l'Etat Futur et des Sorties
	process (TX_EP, TX_BIT_NB, WR_REG, Start_TX)
		begin   	   

			TX_BIT_NB_RAZ <= '0';
			TX_SHIFT <= '0';
			TX_LOAD <= '0';
			
			case TX_EP is
			
				-- Etat de Repos
					-- Attente de Start_TX
				when IDLE 		=>	TX_EF <= IDLE;
										if Start_TX = '1' then
											TX_EF <= TRANSFER;
										end if;	
				
				-- Etat de Chargement
					-- Chargement du Buffer d'Emission
					-- RAZ du Nombre de Bits Transmis
				when TRANSFER 	=>	TX_LOAD <= '1';
										TX_BIT_NB_RAZ <= '1';		
										TX_EF <= SEND_DATA;
					
				-- Envoi du Message
					-- Decalage du Buffer d'Emission
					-- Tant qu'il y A des Bits a Transmettre
				when SEND_DATA =>	TX_EF <= SEND_DATA;
										TX_SHIFT <= '1';
										if TX_BIT_NB = "1100" then
											TX_EF <= IDLE;
										end if;
			end case;
	end process;						 	
---------------------------------------------------------------------

	-- Calcul du Numero de Bit Transmis
	process (TX_CLK,RST)
		begin
			if RST = '0' then
				TX_BIT_NB <= "0000";
			elsif rising_edge(TX_CLK) then
				-- Reinitialisation
				if TX_BIT_NB_RAZ = '1' then
					TX_BIT_NB <= "0000";
				else
				-- Incrementation
					TX_BIT_NB <= TX_BIT_NB +1;
				end if;
			end if;
	end process;
--------------------------------------------------------------------

	-- Gestion du Buffer d'Emission
	TXD <= TX_BUF(0);

	process (RST,TX_CLK)
		begin
			if RST = '0' then
				TX_BUF <= (others => '1');
			elsif rising_edge(TX_CLK) then
				-- Chargement de la Donnee a Transmettre
				if TX_LOAD = '1' then
					TX_BUF (10 downto 0) <= ('1' & Parity & WR_REG(7 downto 0) &'0');
				end if;
				-- Decalage a Droite
				if TX_SHIFT = '1' then
					TX_BUF (10 downto 0) <= ('1' & TX_BUF(10 downto 1));
				end if;
			end if;
	end process;
---------------------------------------------------------------------

--------------------------------------------------------------------------
-- 								GESTION DE LA RECEPTION								--
--------------------------------------------------------------------------

  	-- MAE de la Reception
	-- Registre d'Etat
	process (RX_CLK, RST)
		begin
			if RST = '0' then 
				RX_EP <= IDLE;
			elsif rising_edge(RX_CLK) then
				RX_EP <= RX_EF;
			end if;
	end process;
			
  	-- MAE de la Reception
	-- Calcul de l'Etat Futur
	process (RX_EP, RX_BIT_TIME, RXD, RX_BIT_NB)
		begin   
			
			RX_BIT_NB_INC <= '0';
			RX_SHIFT <= '0';
			RX_BIT_NB_RAZ <= '0';
			RX_End <= '0';
			RX_BIT_TIME_RAZ <= '0';
			
			case RX_EP is

				-- Etat de Repos
					-- RAZ de RX_BIT_TIME Si on Detecte un Bit de Start
					-- Sinon on Reste dans Cet Etat
				when IDLE 		=>	RX_EF <= IDLE;
										if RXD = '0' then
											RX_BIT_TIME_RAZ <= '1';
											RX_EF <= DELAY;
										end if;
				
				-- Attente de 8 Cycles pour Echantillonner les Bits au Milieu du RX_BIT_TIME
					-- RAZ du RX_BIT_NB Quand on A Atteint les 8 Cycles
				when DELAY 		=>	RX_EF <= DELAY;
										if RX_BIT_TIME(2 downto 0) = "111" then
											RX_BIT_TIME_RAZ <= '1';
											RX_BIT_NB_RAZ <= '1';
											RX_EF <= GET_DATA;
										end if;
				
				-- Acquisition de la Donnee
					-- A Chaque RX_BIT_TIME on Incremente le RX_BIT_NB et on Decale le Buffer de Reception
					-- Au bout de 10 bits, on Passe a l'Etat STOP
				when GET_DATA 	=>	RX_EF <= GET_DATA;
										if RX_BIT_TIME(3 downto 0) = "1111" then
											RX_BIT_TIME_RAZ <= '1';
											RX_BIT_NB_INC <= '1';
											RX_SHIFT <= '1';
										end if;

										if RX_BIT_NB = "1010" then
											RX_EF <= STOP;
										end if;
				
				-- Bit de Stop
					-- Generation du Signal de Fin de Reception
				when STOP 		=>	RX_End <= '1';
										RX_EF <= IDLE;						
			end case;
	end process;
---------------------------------------------------------------------

	-- Calcul du Numero de Bit Recu
	process (RX_CLK,RST)
		begin
			if RST = '0' then
				RX_BIT_NB <= "0000";
			elsif rising_edge(RX_CLK) then
				-- Reinitialisation
				if RX_BIT_NB_RAZ = '1' then
					RX_BIT_NB <= "0000";
				-- Incrementation
				elsif RX_BIT_NB_INC = '1' then
					RX_BIT_NB <= RX_BIT_NB +1;
				end if;
			end if;
	end process;
------------------------------------------------------------------
		
 	-- Gestion du Registre de Sortie
	process (RST,RX_CLK)
		begin
			if RST = '0' then
				RD_REG <= "00000000";
			elsif rising_edge(RX_CLK) then
				-- Chargement du Registre a la Fin de la Reception
				if RX_End = '1' then
					RD_REG(7 downto 0) <= RX_BUF (7 downto 0);
				end if;				
			end if;
	end process;
-------------------------------------------------------------------

	-- Gestion du Buffer de Reception
	process (RX_CLK, RST)
		begin
			if RST = '0' then 
				RX_BUF <= (others => '1');
			elsif rising_edge(RX_CLK) then
				-- Decalage a Droite
				if RX_SHIFT = '1' then
					RX_BUF <= (RXD & RX_BUF(9 downto 1));
				end if;
			end if;
	end process;
-------------------------------------------------------------------

--------------------------------------------------------------------------
-- 								GESTION DU BIT START_TX								--
--------------------------------------------------------------------------

  	-- MAE du Bit Start_TX
	-- Registre d'Etat
	process (RX_CLK, RST)
		begin
			if RST = '0' then 
				STX_EP <= IDLE;
			elsif rising_edge(RX_CLK) then
				STX_EP <= STX_EF;
			end if;
	end process;

  	-- MAE du Bit Start_TX
	-- Calcul de l'Etat Futur
	process (STX_EP, CLK, WR, DBIN, TX_LOAD)
		begin

			Start_TX <= '0';
			
			case STX_EP is

				-- Repos
					-- Attente de la Demande d'Ecriture
				when IDLE 			=>	STX_EF <= IDLE;
											if WR = '1' then
												STX_EF <= SET_STX;
											end if;
				
				-- Debut de la Transmission
					-- On Met Start_TX a 1 jusqu'au Chargement du Buffer d'Emission
				when SET_STX 		=>	STX_EF <= SET_STX;
											Start_TX <= '1';
											if TX_LOAD = '1' then
												STX_EF <= WAIT_LOAD;
											end if;
				
				-- Attente de la Fin du Chargement
					-- Start_TX a 1 jusqu'a ce que la Commande de Chargement Soit Desactivee
				when WAIT_LOAD 	=>	STX_EF <= WAIT_LOAD;
											if TX_LOAD = '0' then
												STX_EF <= WAIT_WRITE;
											else
												Start_TX <= '1';
											end if;

				-- Attente du PAssage a 0 de la Requete d'Ecriture
					-- Pour Eviter des Emissions a Repetition
				when WAIT_WRITE	=>	STX_EF <= WAIT_WRITE;
											if WR = '0' then 
												STX_EF <= IDLE;
											end if;
			end case;
	end process;

end Behavioral;