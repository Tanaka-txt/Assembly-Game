; ------
; Julio Tanaka
; Ryan Sulino
; Leo Eid

jmp main ; Pula para a subrotina main ignorando a declaração de variaveis

;---- Declaração de Variáveis Que São Constantes-----
; Declaração das variáveis de texto (Strings)
msg_title: string "CALCULUS HORROR" ; Ele print isso toda vez que voltamos ao começo do jogo "call_print_string"
msg_start: string "PRESS 'SPACE'"
msg_gameover: string "GAME OVER"
msg_restart: string "PRESS 'SPACE' TO RESTART"

; Variáveis de Estado
dino_pos: var #1      ; registra na memoria por meio do var uma posição para o "dino"
cactus_pos: var #1    ; -- // --                                             o "cactus"
jump_state: var #1   ; Define p estado do dinosauro, se está no chão, subindo, topo ou descendo.
jump_timer: var #1    ; Por meio deste controlador de tempo sabemos o tempo que o dino está "voando"
score: var #1         ; utilizado para contabilizar os obstaculos, por meio disto, o jogo avança a dificuldade diminuindo o delay e resetando os "cactus"
game_speed: var #1   ; Controle da dificuldade, aumenta ou diminui o delay entre os frames
rand_seed: var #1    ; Fiz este seed para tentar deixar aleatório o jogo, parcialmente não funcionou kskks :⁽(

; Var de Controle de Input (Tinha um bug que se você segurava o espaço o jogador ficava em um loop e assom ganhava segurando o espaço)
key_prev: var #1      ; 0 = Solto, 1 = Pressionado (Bloqueado)

; Variáveis Nuvens = Nuvem é 2 caracteres
cloud1_pos: var #1     ; Posição da nuvem 1
cloud2_pos: var #1     ; Posição da nuvem 2

; Constantes
DINO_FLOOR_POS: var #1   ; 805 | Guarda onde as coisas devem começar
CACTUS_START_POS: var #1 ; 839 | Guarda onde as coisas devem começar

;---- Fim das Variáveis -----

;---- INICIO JOGO -----
main:
    loadn r0, #805          ; Passo está posição para oregistrador 0
    store DINO_FLOOR_POS, r0  ; Está é a posição de exibição do dino_floor (Salva na memória com o apelido de DINO_FLOOR_POS)
    loadn r0, #839          ; Pega está posição e sobreescreve no registrador 0
    store CACTUS_START_POS, r0 ; Passa a posição do cactu (Salva na memória com o apelido de CACTUS_START_POS)

    call clear_screen         ; Subrotina para limpar a tela após a morte do jogador
    loadn r0, #413          ; Carrega a posição para o registrador 0
    loadn r1, #msg_title      ; Carrega o endereço da memória do msg_tittle para o registrador r1
    loadn r2, #512          ; Carrega a cor
    call print_str  ; linha 660 | Chama a subrotina print_str para printar na tela

    loadn r0, #613        ;Carrega a posição para o registrador 0
    loadn r1, #msg_start    ;Carrega o endereço da memória do msg_start para o registrador r1
    loadn r2, #0            ;Carrega a posição para o registrador r2
    call print_str          ;linha 660 | Chama a subrotina print_str para printar na tela
    
    loadn r7, #0           ; Carrega o registrador 7 com está posição, garante que a contagem do inicio do jogo começe limpa

loop_wait_start: ; Espera para ver algum botão especifico para iniciar o jogo
    inchar r0 ; le o buffer do tecla 
    loadn r1, #' ' ; Verificação para ver se não tem nada no buffer
    cmp r0, r1 ; Compara com o buffer e o "vazio" para ver se o user apertou algo
    jeq start_game_init ; Se apertar e for igual a "espaço" jumpa para o start_game_init
    inc r7 ; Tentei usar esse valor dos milissegundos que ocorrem por baixo do momento que o user clica no espaço para aleatorizar
    jmp loop_wait_start ; Se não for igual ao valor esperado no start, jumpa para o loop

start_game_init: ; Inicia o jogo 
    call clear_screen ;linha 640 | Chama subrotina de limpar a tela pois tinhamos texto na tela
    
    loadn r0, #0 ; Carrega o valor zero para o r0
    store jump_state, r0 ; Guardo o dino no estado 0 (Chão)
    store jump_timer, r0 ; Reseta o crinometro para zero
    store score, r0 ; Reseta o score para 0 
    store key_prev, r0 ; Reseta o estado da tecla como se não tivesse sido apertado nada
    
    loadn r0, #1200         ; Define o delay 
    store game_speed, r0    ; Salva o delay
    
    load r0, DINO_FLOOR_POS ; Coloca o dino na posição que seria o chão
    store dino_pos, r0     ; Coloca a posição no dino
    
    load r0, CACTUS_START_POS ; Posição inicial do cacto fora da tela
    store cactus_pos, r0  ; Posição salva no cactus

    ; Nuvens
    loadn r0, #150        ; Posição registrada em r0  
    store cloud1_pos, r0    ; Coloca a posição da nuvem 1
    loadn r0, #220          ; Posição2 registrada em r0
    store cloud2_pos, r0     ; Coloca a posição na nuvem 2

;---- Loop Principal -----
game_loop:
    
    call erase_actors  ; Chama subrotina | linha 578      
    call draw_floor    ; Chama subrotina, para printar os atores, integral, pessoa, nuvem, bsi....
    
    call process_input  ; Faz o processo de receber o input do teclado
    call update_physics ; Fisica do dino
    call move_obstacle  ; Fisica do obstáculo   Movimento da "arvore / integral"
    call move_clouds    ; Movimento da "nuvem"
    
    call check_collision ; Verifica colisão do personagem com a integral verificando se algum momento a posição deles é a mesma
    call draw_actors  ; Desenha os "atores"      
    
    call delay_frame        
    inc r7
    
    jmp game_loop

;---- Lógica de Input (ANTI-HOLD) -----

process_input: ; Processo de leitura do teclado
    push r0 ; Guarda oque havia nos registradores que vamos usar
    push r1
    push r2
    
    inchar r0 ; Recebe o input do teclado
    loadn r1, #' ' ; Salva o edereço do espaço no r1
    cmp r0, r1 ; Compara se o input é vazio
    jne not_space_pressed   ; Se leu qualquer coisa que não é espaço (ou nada)
    
    ; --- Detectou Espaço ---
    load r1, key_prev       ; Verifica o estado anterior
    loadn r2, #1
    cmp r1, r2
    jeq end_input           ; Se key_prev == 1, o jogador está segurando -> Ignora
    
    ; É um "novo" clique
    store key_prev, r2      ; Trava a tecla (key_prev = 1)
    
    ; Tenta Pular (Lógica original de física)
    load r1, jump_state
    loadn r2, #0
    cmp r1, r2
    jne end_input           ; Se não estiver no chão, não faz nada
    
    loadn r2, #1
    store jump_state, r2 
    loadn r2, #0
    store jump_timer, r2
    jmp end_input

not_space_pressed:
    ; Se chegou aqui, o jogador soltou o espaço
    loadn r1, #0
    store key_prev, r1      ; Destrava a tecla (key_prev = 0)

end_input:
    pop r2
    pop r1
    pop r0
    rts

update_physics:
    ; Salva os registradores que vamos usar no push
    push r0
    push r1
    push r2
    push r3
    push r4
    ; Vamos salvar essas posições para poder verificar a fisica
    load r0, jump_state ; Guarda o estatus do jump no registrador 0 (estado atual do jump)
    load r1, dino_pos ; Salva a posição (posição atual do dino)
    loadn r4, #40 ; salva o endereço da posição do pulo
    loadn r2, #0 ; Salva o endereço da posição do chão

    cmp r0, r2 ; Compara  se o estado do chão se for igual ele vão para subrotina phys_ground
    jeq phys_ground ; Situação de estando no chão

    loadn r2, #1 ; Carrega 1 para o r2
    cmp r0, r2 ; Compara se o chão temporário dele for for a posição 1, jampa para o phys_ascending
    jeq phys_ascending ; 

    loadn r2, #2
    cmp r0, r2
    jeq phys_top
    loadn r2, #3
    cmp r0, r2
    jeq phys_descending
    jmp phys_end

phys_ground:
    load r3, DINO_FLOOR_POS ; Salva no r3 a posição do chão 0
    store dino_pos, r3 ; Guarda 
    jmp phys_end ; Pula para subrotina fim de fisica

phys_ascending: ; Subida até atingir a altura maxima
    sub r1, r1, r4 ; r1 = posição dino - 40 (pulo) | para saber qual é a altura do dino
    store dino_pos, r1 ;  Guarda a altura
    load r2, jump_timer ; Usamos para contagem de frames que ele subiu
    inc r2 ; Incrementa o timar
    store jump_timer, r2
    loadn r3, #4 ; Salva o valor para saber a linha de limite
    cmp r2, r3 ; Compara o limite com os frames
    jne phys_end ; If for igual a 4 ele jampa pra subrotina de end
    loadn r2, #2
    store jump_state, r2
    loadn r2, #0
    store jump_timer, r2
    jmp phys_end

phys_top: ; Fisica no topo , pairando
    ;Estado 1
    load r2, jump_timer ; Ele carrega no r2 o o time do jump
    inc r2 ; Incrementa
    store jump_timer, r2 ; Salva o jump_timer r2
    loadn r3, #2 ; Carrega com o valor 2 no r3
    cmp r2, r3 ; Compara para ver se deu o tempo de pairar
    jne phys_end ; Se deu ele jumpa para o end
    ;Estado 2
    loadn r2, #3 ; Carrega o 3 no r3 como parametro
    store jump_state, r2 ; salva o jump state para saber que está na altura
    loadn r2, #4 ; Coloca no r2 o valor de 4
    store jump_timer, r2 ; Guarda o jump timer, para registrar
    jmp phys_end ; Após isso pula para o fim

phys_descending: ; Dino cai no chão
    add r1, r1, r4 ; posição dino + 40 = queda do dino | faz descer pois vc coloca 40 caracteres ai da \n
    store dino_pos, r1 ; Guarda a posição + 40 
    load r2, jump_timer ; salva o jump timer no r2
    dec r2 ; decrementa o r2
    store jump_timer, r2 ; Salva o jump timer = 3
    loadn r3, #0 ; salva o 0 posição do chão no r3
    cmp r2, r3 ; compara para ver se está igual ao chão 
    jne phys_end ; se não for igual ele jampa para o end
    loadn r2, #0 ; se for ele salva o 0 no r2
    store jump_state, r2 ; e da estore no jump_state com o r2
    jmp phys_end ; jampa pro fim

phys_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

move_obstacle: ;Movimentação da integral 
    push r0 ; Salva oq havia nos registradores que vamos usar, na memória
    push r1
    push r2
    push r3
    push r4 
    
    load r0, cactus_pos ; Carrega a posição start do cacto no r0 (ex. 839
    dec r0 ; Recrementa a posição (ex. 838)
    
    loadn r1, #800 ; Linha começa no endereço 800 e termina no 809
    cmp r0, r1 ; Compara para verificar se ele chegou no limite esquerdo da tela
    jle reset_obs ; jampa se r0 < r1
    
    store cactus_pos, r0 ; Salva o r0 no cactos pos
    jmp end_move_obs ; jampa para o end

reset_obs: ; Quando o cacto sai da tela isso é executado
    load r0, CACTUS_START_POS ; a posição inicial do cacto é salva em r0
    store cactus_pos, r0 ; o valor de r0 é salvo na memoria com o cactus_pos
    
    ; Contador de score
    load r2, score ; Conta ponto pois o player sobrevivel, isso em si nem aparece pro player, mas é um cotabilizador para podermos aumentar a dificuldade
    inc r2 
    store score, r2
    
    ; --- ACELERAÇÃO INFINITA ---
    load r3, game_speed ; Carrega um delay atual   (ex.1200)  
    loadn r4, #40           ; Acelera tirando 40 do delay
    sub r3, r3, r4          ; ex. r3(novo delay) = 1200 - 40 = 1160
    
    ; Trava de segurança (Delay mínimo 1)
    ; Estava tendo um problema que se deixasse infinitamente ele ia dar um unflow, isso faria o delay travar ou não funcionar, pois um numero negativo pode ser representado como um nuemro positivo gigante
    loadn r4, #5  ; Registra o valor 5 no r4
    cmp r3, r4 ; Compare se o game_speed <= 5 ele chega no mim speed
    jle force_min_speed   
    store game_speed, r3  ; Se não ele salva o novo delay  
    jmp end_move_obs ; Jampa pro end

force_min_speed: ; Aqui forçamos o min speed
    loadn r3, #5            
    store game_speed, r3 ; Travamos o jogo com 5 de game-speed
    jmp end_move_obs ; Jampa fim

end_move_obs: ; Retorna onde parou
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

move_clouds: ; Movimentação da nuvem
    push r0 ; Guarda oq tinha nos registradores dentro da memoria
    push r1
    push r2

    ; NUVEM 1
    load r0, cloud1_pos ; r0 recebe o cloud1
    dec r0 ; decrementa movento para esquerda a nuvem
    loadn r1, #120 ; r1 recebe o valor de 120 | limite esquerda (3*40 = 120)
    cmp r0, r1 ; Compara a movimentação para esquerda para ver se é igual
    jgr save_cloud1 ; se posição > 120 ele jampa para subrotina save_cloud1
    loadn r0, #158    ; Reseta para o canto direito

save_cloud1:
    store cloud1_pos, r0 ; Salva a pos da nuvem 

    ; NUVEM 2
    load r0, cloud2_pos ; r0 recebe o cloud2
    dec r0 ; Decrementamos, movendo ele para esquerda
    loadn r1, #200; limite esquerda é (5*4 = 2000)
    cmp r0, r1 ; Compara pos == 200 ?
    jgr save_cloud2 ; jampa se posi > 200, save_cloud2
    loadn r0, #238 ; reset para voltar

save_cloud2: ; Salva tudo e retorna
    store cloud2_pos, r0
    pop r2
    pop r1
    pop r0
    rts

check_collision: ; Checagem de colisão
    push r0
    push r1
    push r2
    push r3
    push r4
    
    load r0, dino_pos ; r0 recebe pos do personagem
    load r1, cactus_pos ; r1 recebe a pos do "cacto"
    
    ; --- 1. CHECAGEM DO TRONCO ($) ---
    sub r2, r0, r1      ; r2 = Posi Dino - Posi Tronco | isso não pode ser 0 pq ai eles tão na mesma posição 
    
    ; tronco
    loadn r4, #0 ; r4 comparação para ver se está certo
    cmp r2, r4 ; se é 0 bateu
    jeq game_over ; Perdeu se bateu
    ; Braço direto
    loadn r4, #1 
    cmp r2, r4
    jeq game_over
    ; Perna esquerda
    loadn r4, #0
    dec r4              ; -1
    cmp r2, r4
    jeq game_over
    
    ; --- 2. CHECAGEM topo integral (pulo baixo) ---
    load r1, cactus_pos
    loadn r4, #39       ; Offset da copa | 39 = sobre um dilha e vira um pra direita
    sub r1, r1, r4      ; r1 = posição do 'q'
    
    sub r2, r0, r1      ; r2 = Dino - Topo
    
    loadn r4, #0 ; Salva o 0
    cmp r2, r4 ; Verifica se é 0
    jeq game_over ; Perdeu se for 0
    
    ; Essa é o meio das pernas
    loadn r4, #1 ; Carrega 1
    cmp r2, r4  ; Compara posi dito com 1
    jeq game_over ; Se bater over
    
    loadn r4, #0
    dec r4
    cmp r2, r4
    jeq game_over
    
    jmp end_col_check ; Fim

end_col_check:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; --- TELA DE GAME OVER ---
game_over:
    call clear_screen 

    ; 1. GAME OVER
    loadn r0, #415          
    loadn r1, #msg_gameover
    loadn r2, #2304
    call print_str
    
    ; 2. BSI 2025 COLORIDO (Centralizado: 456 + 40 = 496)
    loadn r0, #496          
    
    loadn r1, #'B'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #'S'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #'I'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #' '
    outchar r1, r0
    inc r0
    
    loadn r1, #'a'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #'0'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #'a'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
    
    loadn r1, #'b'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0

    ; 3. PRESS SPACE TO RESTART
    loadn r0, #569          
    loadn r1, #msg_restart
    loadn r2, #0
    call print_str

wait_reset:
    inchar r0
    loadn r1, #' '
    cmp r0, r1
    jeq main
    jmp wait_reset

;---- Gráficos -----

draw_floor: ; Desenha chão
    push r0 ; Guarda os registradores anteriores
    push r1
    push r2
    loadn r0, #800 ; começo da onde vai ser o chão
    loadn r1, #840 ; Fim da onde vai ser a ultima linha
    loadn r2, #'_' ; Caracter do chão
loop_floor: ; loop do chão
    cmp r0, r1 ; compara o caracter do inicio e ve se é igual ao ultimo
    jeq end_floor ; se forem igual pula para o fim de criar chão
    outchar r2, r0 ; desenha o chão
    inc r0 ; vai incrementando do começo até o chegar no ultimo chão
    jmp loop_floor ; se não acabar de printar o chão volta pro loop
end_floor: ; Fim após terminar de por os 
    pop r2 ; Pega novamente os resgitradores salvos
    pop r1
    pop r0
    rts ; Retorna para onde tinha saido

draw_actors: ; redesenha a posição do personagem e o BSI que fica na tela
    push r0 ; guarda os registradores
    push r1
    push r2
    push r3
    
    ; --- TEXTO BSI (NO JOGO - Centralizado Pos 456) ---
    ; Usei outros caracteres para escrever bsi e mudei eles no MIF, pq eu já tava usando pra outra coisa
    loadn r0, #456 ; Guarda a posição de centralização          
    
    loadn r1, #'B' ; Guarda B no r1
    loadn r2, #2304 ; Guarda cor
    add r1, r1, r2 ; Coloca cor no B
    outchar r1, r0 ; Printa
    inc r0 ; Incrementa r0 para ir para a posição ao lado da primeira letra e continuar as outras
    loadn r1, #'S'
    loadn r2, #512
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'I'
    loadn r2, #2816
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    loadn r1, #'a'
    loadn r2, #3328
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'0'
    loadn r2, #3584
    add r1, r1, r2
    outchar r1, r0
    inc r0 ; r0 + 1
    loadn r1, #'a'
    loadn r2, #3328
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'b'
    loadn r2, #512
    add r1, r1, r2
    outchar r1, r0

    ; --- DINO FAKE QUE É UMA PESSOA ---
    loadn r2, #512  ; 
    load r0, dino_pos
    loadn r3, #120
    sub r0, r0, r3
    loadn r1, #'5' ; Cabeça
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80 
    sub r0, r0, r3
    loadn r1, #'4' ; Braço esquerdo
    add r1, r1, r2
    outchar r1, r0
    dec r0
    loadn r1, #'6' ; Tronco
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80
    sub r0, r0, r3
    inc r0
    loadn r1, #'7' ; Braço direito
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #40
    sub r0, r0, r3
    loadn r1, #'2' ; Perna esquerda
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    dec r0
    loadn r1, #'1' ; Perna direita
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    inc r0
    loadn r1, #'3'
    add r1, r1, r2
    outchar r1, r0
    
    ; --- ÁRVORE --- 
    load r0, cactus_pos ; Aqui recebemos o cactus_pos para o registrador r0
    loadn r1, #'$' ; Topo da integral
    loadn r2, #3072 ; Cor
    add r1, r1, r2 ; Adiciona cor com o registrador
    outchar r1, r0 ; Printa 
    ; Acontece a mesma coisa com a parte de baixo
    loadn r3, #39
    sub r0, r0, r3       
    loadn r1, #'%' ; Caracter da parte de baixo
    loadn r2, #3072      
    add r1, r1, r2
    outchar r1, r0

    ; --- NUVENS --- Temos 2 arvores que são formadas por 2 caracteres
    loadn r2, #0           
    load r0, cloud1_pos
    loadn r1, #'8' ; Caracter da nuvem 1.1
    add r1, r1, r2
    outchar r1, r0           
    inc r0
    loadn r1, #'9' ; Caracter da nuvem 1.2
    add r1, r1, r2
    outchar r1, r0           
    load r0, cloud2_pos
    loadn r1, #'8' ; Caracter da nuvem 2.1
    add r1, r1, r2
    outchar r1, r0           
    inc r0
    loadn r1, #'9' ; Caracter da nuvem 2.2
    add r1, r1, r2
    outchar r1, r0    ; Printa       
    ; Pega de novo oq havia guardado
    pop r3
    pop r2
    pop r1
    pop r0
    rts ; Resotrna onde parou

erase_actors: ; Apaga a posição antiga para poder ocorrer os movimentos
    push r0 ; Salva tudo que tinha salvo nos registradores na memória
    push r1
    push r2
    push r3

    ; COR DE fundo, usamos pois a onde estáva o antigo "ser" tem que ser subistituido por vazio
    loadn r1, #' '   ; Add o  endereço do vazio no r1      
    loadn r2, #2560 ; Add a cor no r2
    add r1, r1, r2    ; r1 = r1+r2

    ; Apaga Dinozord | Utilizo da subtração para subir linhas e soma para descer
    ;Cabeça (Largura da tela 40)
    load r0, dino_pos ; Recebo a posição da cabeça
    loadn r3, #120 ; 40 * 3 = 120 
    sub r0, r0, r3 ; Sobe 3 linhas
    outchar r1, r0 ; Apaga
    ;Tronco
    load r0, dino_pos ; Recebo a poisção do tronco 
    loadn r3, #80 ; 40 * 2 = 80 
    sub r0, r0, r3 ; Sobe 2 linhas
    outchar r1, r0 ; Apaga
    dec r0         ; Vai 1 para esquerda
    outchar r1, r0 ; Apaga
    ; Troco
    load r0, dino_pos 
    loadn r3, #80
    sub r0, r0, r3
    inc r0
    outchar r1, r0
    ; Pernas
    load r0, dino_pos
    loadn r3, #40
    sub r0, r0, r3
    outchar r1, r0
    ;Pés
    load r0, dino_pos
    dec r0
    outchar r1, r0
    load r0, dino_pos
    inc r0
    outchar r1, r0
    
    ; --- APAGA ÁRVORE ---
    load r0, cactus_pos
    outchar r1, r0
    
    ; Apaga o topo do cacto
    loadn r3, #39
    sub r0, r0, r3
    outchar r1, r0
    
    ; Apaga Nuvens
    load r0, cloud1_pos
    outchar r1, r0
    inc r0
    outchar r1, r0
    load r0, cloud2_pos
    outchar r1, r0
    inc r0
    outchar r1, r0
    
    pop r3
    pop r2
    pop r1
    pop r0
    rts ; Retorna onde parou

clear_screen:
    push r0 ; Salva oque tinha nos registradores que vamos usar na memória r0,r1,r2
    push r1
    push r2
    loadn r0, #1199 ; Salva o ponto de partida para a limpeza no fim da tela 0 - 1200 caracteres
    loadn r1, #' '    ; Carrega o vazio para o r1     
    loadn r2, #2560 ; Configura cor de fundo
    add r1, r1, r2    ; Add o vazio com a cor de fundo | r1 = r1 + r2
loop_clear: ; Começa loop para limpeza
    outchar r1, r0  ; Apaga o caracter que tiver no fim da tela na posição 1199 e poe o vazio
    dec r0 ; Decrementa a posição da tela para podermos pensar em avançar
    loadn r2, #0 ; Carrega para o r2 o endereço do caracter 0, da tela 
    cmp r0, r2 ; Comparamos para ver se chegamos ao começo da tela
    jgr loop_clear ; Enquando a posição for > jumpamos para este loop, limpando tudo
    outchar r1, r0 ;Quando chegamos em 0 printamos para limpar tbm a posi 0
    pop r2 ; Pegamos os valores que tinhamos salvo na memória
    pop r1
    pop r0
    rts ; Retornamos onde paramos no código

print_str:
    push r0         ; Salva os valores atuais dos registradores na memória r0 a r4
    push r1
    push r2
    push r3
    push r4
    loadn r3, #'\0' ; Carrega o r3 com valor do caracter como nulo para se basear na hora de parar de ler a string
loop_print: ; loop para printar na tela
    loadi r4, r1 ; passa o valor do registrador r1 para o r4 
    cmp r4, r3 ; utiliza disto para ver se é o final da string
    jeq end_print ; Se for igual ao caracter nulo /0, pula para o fim do print
    add r4, r2, r4 ; Carrega a cor para o r4 em cada caracter passado
    outchar r4, r0 ; Imprime na tela cada caracter
    inc r0 ; incremento o r0 para ir printando caracter por caracter
    inc r1 ; Inc para passar a próxima letra para o r4
    jmp loop_print ; Volta para o começo do loop para continuar o próximo caracter
end_print: ; sub rotina para o final do print, pega oq havia alocado na memória
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts ; Retorna onde havia dado o call

delay_frame: ; sub-rotina de delay-frame
    push r0 ; libera os resistradores
    push r1
    load r0, game_speed ; Processador burro tem que mandar ele contar até um numero alto ksks

delay_loop: ; Sub-rotina de delay do loop , aqui enrolamos o clock fazendo o delay de 1200 e que diminui
    dec r0
    jnz delay_loop
    pop r1
    pop r0
    rts
