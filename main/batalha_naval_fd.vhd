library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;


entity batalha_naval_fd is
    port (clock, reset: 		       in STD_LOGIC;
			 vez:						       in STD_LOGIC;
			 fim_jog, fim_adv:			 out STD_LOGIC;
			 -- Controle Recebe
			 term_Nadv:                 in  STD_LOGIC;
			 jog_Nmsg:                  in  STD_LOGIC;
			 recebe_enable: 				 in  STD_LOGIC;
			 recebe_reset:					 in  STD_LOGIC;
			 recebe_erro: 					 out STD_LOGIC;
			 recebe_pronto:				 out STD_LOGIC;
			 recebe_vez:				    out STD_LOGIC;
			 -- Dados Recebe
			 entrada_serial_terminal:   in STD_LOGIC;
			 entrada_serial_adversario: in STD_LOGIC;
			 jogada_L: 						 out STD_LOGIC_VECTOR(6 downto 0);
			 jogada_C: 						 out STD_LOGIC_VECTOR(6 downto 0);
			 -- Controle Enviar
			 enviar_enable:   in  STD_LOGIC;
			 mensagem:        in  STD_LOGIC_VECTOR(2 downto 0);
			 enviar_pronto:   out STD_LOGIC;
			 -- Dados Enviar
			 saida_serial_adversario: 		out STD_LOGIC;
			 -- Controle Operações
			 opera_enable: in STD_LOGIC;
			 operacao: 		in STD_LOGIC_VECTOR(1 downto 0);
			 opera_pronto: out STD_LOGIC;
			 -- Dados Operações
			 saida_serial_terminal: 		out STD_LOGIC;
			 -- Resultado Jogada
			 resultado_jogada_adv: 		 buffer STD_LOGIC_VECTOR(1 downto 0);
			 resultado_jogada_jog: 		 buffer STD_LOGIC_VECTOR(1 downto 0);
			 -- Placar
			 placar_adv_enable:  in STD_LOGIC;
			 placar_jog_enable:	in STD_LOGIC;
			 placar_jogador: 		out STD_LOGIC_VECTOR(3 downto 0);
			 placar_adversario: 	out STD_LOGIC_VECTOR(3 downto 0)
			 
    );
end batalha_naval_fd;

architecture batalha_naval_fd_arc of batalha_naval_fd is

	-- Recebe Jogada
	component recebe_mensagem 
		port ( 
			-- Entradas Controle
			clock, reset:   in STD_LOGIC; 
			recebe_enable:  in STD_LOGIC;
			recebe_reset:   in STD_LOGIC;
			jog_Nmsg:       in STD_LOGIC;
			--Entrada Dados     
			entrada_serial: in STD_LOGIC; 
			--Saídas Controle
			recebe_erro:    out STD_LOGIC;
			recebe_pronto:  buffer STD_LOGIC;
			recebe_vez:     out STD_LOGIC;
			--Saídas Dados
			reg_jogada_L:	 out STD_LOGIC_VECTOR(6 downto 0);
			reg_jogada_C:	 out STD_LOGIC_VECTOR(6 downto 0);
			reg_mensagem:	 buffer STD_LOGIC_VECTOR(6 downto 0);
			estado:		 	 out STD_LOGIC_VECTOR(6 downto 0)
		);
	end component;
	
	-- Envia Mensagem
	component envia_mensagem
		port (
			clock, reset: 			in std_logic;
			enviar_enable:       in std_logic;
			mensagem: 				in std_logic_vector(2 downto 0);
			jogada_L, jogada_C:	in std_LOGIC_VECTOR(6 downto 0);
			saida_serial:			out std_logic;
			envia_pronto:			out std_logic
		);
	end component;
	
	-- Operações do Campo
	component opera_campo
		port (
        clock, reset: 						 in std_logic; 
		  vez: 						 			 in std_logic;
		  opera_enable: 						 in std_logic;
        operacao: 							 in std_logic_vector(1 downto 0);
		  dado: 									 in std_logic_vector(6 downto 0);
        endereco: 							 in std_logic_vector(13 downto 0);
        saida_serial: 	 					 out std_logic; 
		  opera_pronto: 	 					 out std_logic;
		  resultado_jogada: 					 out std_logic_vector(1 downto 0);
        -- depuracao
        db_reseta, db_partida, db_zera: out std_logic; 
		  db_conta, db_carrega: 			 out std_logic;
		  db_pronto, db_we, db_fim: 		 out std_logic;
        db_q: 									 out std_logic_vector(5 downto 0);
        db_sel: 								 out std_logic_vector(1 downto 0);
        db_dados: 							 out std_logic_vector(6 downto 0)
		);
	end component;
		
	component ascii_to_7seg
	port ( 
		jogada_linha, jogada_coluna: in std_logic_vector(6 downto 0);
      linha, coluna: 				  out std_logic_vector (6 downto 0) 
	);
	end component;
	
	component contador_m is
	generic (
		constant M: integer := 50; 
		constant N: integer := 6    
	);
   port (
		CLK, zera, conta: in STD_LOGIC;
      Q: out STD_LOGIC_VECTOR (N-1 downto 0);
      fim: out STD_LOGIC
   );
	end component;
	
	component mux3x1_n
	generic (
       constant BITS: integer := 4);
	port(D2, D1, D0 : in std_logic_vector (BITS-1 downto 0);
       SEL: in std_logic_vector (1 downto 0);
       MX_OUT : out std_logic_vector (BITS-1 downto 0));
	end component;
	
	component decodificador_resultado_jogada_jog
	port(
		memoria:    in std_logic_vector(6 downto 0);
		jogada_cod: out std_logic_vector (1 downto 0)
	);
	end component;
	
	signal s_entrada_serial:   		STD_LOGIC; 
	signal s_jogada_L:         		STD_LOGIC_VECTOR(6 downto 0);
	signal s_jogada_C:        			STD_LOGIC_VECTOR(6 downto 0);
	signal s_resultado:   	   		STD_LOGIC_VECTOR(6 downto 0);
	signal s_resultado_jogada_adv:   STD_LOGIC_VECTOR(6 downto 0); 
	signal s_resultado_jogada_jog:   STD_LOGIC_VECTOR(6 downto 0);
	
begin 
		
	with term_Nadv select
		s_entrada_serial <= entrada_serial_terminal when '1',
							     entrada_serial_adversario when others; 
	
	-- Recebe Jogada
	RJ: recebe_mensagem
	port map(
		clock          => clock, 
		reset  			=> reset,
		recebe_enable	=> recebe_enable,
		recebe_reset   => recebe_reset,
		jog_Nmsg			=> jog_Nmsg, 	
		entrada_serial => s_entrada_serial,  
		recebe_erro		=> recebe_erro, 
		recebe_pronto	=> recebe_pronto, 
		recebe_vez     => recebe_vez,
		reg_jogada_L	=> s_jogada_L, 
		reg_jogada_C	=> s_jogada_C, 
		reg_mensagem	=> s_resultado_jogada_jog,
		estado 			=> open
	);

	-- Envia Mensagem
	EM: envia_mensagem
	port map(
		clock         => clock,
		reset         => reset,
		enviar_enable => enviar_enable,
		mensagem      => mensagem,
		jogada_L      => s_jogada_L,
		jogada_C		  => s_jogada_C,
		saida_serial  => saida_serial_adversario,
		envia_pronto  => enviar_pronto
	);
	
	-- Operações Campo
	OC: opera_campo
	port map(
		clock				  => clock, 
		reset            => reset, 
		vez				  => vez,
		opera_enable     => opera_enable,
		operacao         => operacao,  
		dado             => s_resultado,
		endereco         => s_jogada_L & s_jogada_C,
		saida_serial     => saida_serial_terminal, 
		opera_pronto     => opera_pronto,
		resultado_jogada => resultado_jogada_adv,
		-- depuracao
		db_reseta        	=> open, 
		db_partida			=> open, 
		db_zera				=> open,
		db_conta				=> open, 
		db_carrega			=> open, 
		db_pronto			=> open, 
		db_we					=> open, 
		db_fim				=> open,
		db_q					=> open,
		db_sel				=> open,
		db_dados				=> open
	);
	
	with vez select
	s_resultado <= s_resultado_jogada_jog  when '1', 
						s_resultado_jogada_adv when others;
						
	MUX: mux3x1_n
	generic map(BITS=>7)
	port map(
		D2     => "1011000",  -- X
		D1     => "1000001",  -- A
		D0     => "1000101",  -- E
      SEL    => resultado_jogada_adv,
      MX_OUT => s_resultado_jogada_adv
	);
	
	
	ASC_7SEG: ascii_to_7seg
	port map ( 
			jogada_linha =>  s_jogada_L,
			jogada_coluna => s_jogada_C,
         linha         => jogada_L,
			coluna        => jogada_C
	);
	
	-- Decodificador Resultado de ASCII para código 
	D_RES: decodificador_resultado_jogada_jog 
	port map (
		memoria 	  => s_resultado_jogada_jog, 
		jogada_cod => resultado_jogada_jog
	);
	
	PLACAR_JOG: contador_m
	generic map(M => 7, N => 4)
   port map(
		CLK   => clock,
		zera  => reset,
		conta => placar_jog_enable and resultado_jogada_jog(1) and (not resultado_jogada_jog(0)) ,
      Q     => placar_jogador,
      fim   => fim_jog
   );
	
	PLACAR_ADV: contador_m
	generic map(M => 7, N => 4)
   port map(
		CLK   => clock,
		zera  => reset,
		conta => placar_adv_enable and resultado_jogada_adv(1) and (not resultado_jogada_adv(0)),
      Q     => placar_adversario,
      fim   => fim_adv
   );
	
end batalha_naval_fd_arc;