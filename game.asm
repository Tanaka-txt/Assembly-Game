; --- ICMC DINO RUN (Anti-Hold: Não pode segurar espaço) ---
;
; Lógica de Input alterada:
; - O jogador é obrigado a soltar a tecla espaço para pular novamente.
; - Mantém a velocidade infinita e o texto centralizado.

jmp main

;---- Declaração de Variáveis -----

msg_title: string "CALCULUS HORROR"
msg_start: string "PRESS 'SPACE'"
msg_gameover: string "GAME OVER"
msg_restart: string "PRESS 'SPACE' TO RESTART"

; Variáveis de Estado
dino_pos: var #1      
cactus_pos: var #1    
jump_state: var #1    
jump_timer: var #1    
score: var #1         
game_speed: var #1    
rand_seed: var #1

; NOVA VARIÁVEL: Controle de Input
key_prev: var #1      ; 0 = Solto, 1 = Pressionado (Bloqueado)

; Variáveis Nuvens
cloud1_pos: var #1     
cloud2_pos: var #1     

; Constantes
DINO_FLOOR_POS: var #1   ; 805
CACTUS_START_POS: var #1 ; 839

;---- Fim das Variáveis -----

main:
    loadn r0, #805
    store DINO_FLOOR_POS, r0
    loadn r0, #839
    store CACTUS_START_POS, r0

    call clear_screen
    loadn r0, #413          ; Centralizado
    loadn r1, #msg_title
    loadn r2, #512          ; Azul
    call print_str

    loadn r0, #613          ; Centralizado
    loadn r1, #msg_start
    loadn r2, #0            ; Branco
    call print_str
    
    loadn r7, #0

loop_wait_start:
    inchar r0
    loadn r1, #' '
    cmp r0, r1
    jeq start_game_init
    inc r7
    jmp loop_wait_start

start_game_init:
    call clear_screen
    
    loadn r0, #0
    store jump_state, r0
    store jump_timer, r0
    store score, r0
    store key_prev, r0      ; Começa com a tecla solta
    
    loadn r0, #1200         ; Começa Lento
    store game_speed, r0    
    
    load r0, DINO_FLOOR_POS
    store dino_pos, r0
    
    load r0, CACTUS_START_POS
    store cactus_pos, r0

    ; Nuvens
    loadn r0, #150          
    store cloud1_pos, r0
    loadn r0, #220          
    store cloud2_pos, r0

;---- Loop Principal -----
game_loop:
    
    call erase_actors        
    call draw_floor          
    
    call process_input       
    call update_physics     
    call move_obstacle       
    call move_clouds        
    
    call check_collision    
    call draw_actors        
    
    call delay_frame        
    inc r7
    
    jmp game_loop

;---- Lógica de Input (ANTI-HOLD) -----

process_input:
    push r0
    push r1
    push r2
    
    inchar r0
    loadn r1, #' '
    cmp r0, r1
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
    push r0
    push r1
    push r2
    push r3
    push r4
    load r0, jump_state
    load r1, dino_pos
    loadn r4, #40
    loadn r2, #0
    cmp r0, r2
    jeq phys_ground
    loadn r2, #1
    cmp r0, r2
    jeq phys_ascending
    loadn r2, #2
    cmp r0, r2
    jeq phys_top
    loadn r2, #3
    cmp r0, r2
    jeq phys_descending
    jmp phys_end
phys_ground:
    load r3, DINO_FLOOR_POS
    store dino_pos, r3
    jmp phys_end
phys_ascending:
    sub r1, r1, r4
    store dino_pos, r1
    load r2, jump_timer
    inc r2
    store jump_timer, r2
    loadn r3, #4
    cmp r2, r3
    jne phys_end
    loadn r2, #2
    store jump_state, r2
    loadn r2, #0
    store jump_timer, r2
    jmp phys_end
phys_top:
    load r2, jump_timer
    inc r2
    store jump_timer, r2
    loadn r3, #2
    cmp r2, r3
    jne phys_end
    loadn r2, #3
    store jump_state, r2
    loadn r2, #4
    store jump_timer, r2
    jmp phys_end
phys_descending:
    add r1, r1, r4
    store dino_pos, r1
    load r2, jump_timer
    dec r2
    store jump_timer, r2
    loadn r3, #0
    cmp r2, r3
    jne phys_end
    loadn r2, #0
    store jump_state, r2
    jmp phys_end
phys_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

move_obstacle:
    push r0
    push r1
    push r2
    push r3
    push r4 
    
    load r0, cactus_pos
    dec r0
    
    loadn r1, #800
    cmp r0, r1
    jle reset_obs
    
    store cactus_pos, r0
    jmp end_move_obs

reset_obs:
    load r0, CACTUS_START_POS
    store cactus_pos, r0
    
    load r2, score
    inc r2
    store score, r2
    
    ; --- ACELERAÇÃO INFINITA ---
    load r3, game_speed     
    loadn r4, #40           ; Acelera tirando 40 do delay
    sub r3, r3, r4          
    
    ; Trava de segurança (Delay mínimo 1)
    loadn r4, #5            
    cmp r3, r4
    jle force_min_speed     
    
    store game_speed, r3    
    jmp end_move_obs

force_min_speed:
    loadn r3, #5            
    store game_speed, r3
    jmp end_move_obs

end_move_obs:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

move_clouds:
    push r0
    push r1
    push r2
    ; NUVEM 1
    load r0, cloud1_pos
    dec r0
    loadn r1, #120
    cmp r0, r1
    jgr save_cloud1
    loadn r0, #158          
save_cloud1:
    store cloud1_pos, r0
    ; NUVEM 2
    load r0, cloud2_pos
    dec r0
    loadn r1, #200
    cmp r0, r1
    jgr save_cloud2
    loadn r0, #238          
save_cloud2:
    store cloud2_pos, r0
    pop r2
    pop r1
    pop r0
    rts

check_collision:
    push r0
    push r1
    push r2
    push r3
    push r4
    
    load r0, dino_pos
    load r1, cactus_pos
    
    ; --- 1. CHECAGEM DO TRONCO ($) ---
    sub r2, r0, r1      ; Delta = Dino - Tronco
    
    loadn r4, #0
    cmp r2, r4
    jeq game_over
    
    loadn r4, #1
    cmp r2, r4
    jeq game_over
    
    loadn r4, #0
    dec r4              ; -1
    cmp r2, r4
    jeq game_over
    
    ; --- 2. CHECAGEM DA COPA (q) ---
    load r1, cactus_pos
    loadn r4, #39       ; Offset da copa
    sub r1, r1, r4      ; r1 = posição do 'q'
    
    sub r2, r0, r1      ; Delta = Dino - Copa
    
    loadn r4, #0
    cmp r2, r4
    jeq game_over
    
    loadn r4, #1
    cmp r2, r4
    jeq game_over
    
    loadn r4, #0
    dec r4
    cmp r2, r4
    jeq game_over
    
    jmp end_col_check

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

draw_floor:
    push r0
    push r1
    push r2
    loadn r0, #800
    loadn r1, #840
    loadn r2, #'_'
loop_floor:
    cmp r0, r1
    jeq end_floor
    outchar r2, r0
    inc r0
    jmp loop_floor
end_floor:
    pop r2
    pop r1
    pop r0
    rts

draw_actors:
    push r0
    push r1
    push r2
    push r3
    
    ; --- TEXTO BSI (NO JOGO - Centralizado Pos 456) ---
    loadn r0, #456          
    
    loadn r1, #'B'
    loadn r2, #2304
    add r1, r1, r2
    outchar r1, r0
    inc r0
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
    inc r0
    loadn r1, #'a'
    loadn r2, #3328
    add r1, r1, r2
    outchar r1, r0
    inc r0
    loadn r1, #'b'
    loadn r2, #512
    add r1, r1, r2
    outchar r1, r0

    ; --- DINOZORD ---
    loadn r2, #512 
    load r0, dino_pos
    loadn r3, #120
    sub r0, r0, r3
    loadn r1, #'5'
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80
    sub r0, r0, r3
    loadn r1, #'4'
    add r1, r1, r2
    outchar r1, r0
    dec r0
    loadn r1, #'6'
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80
    sub r0, r0, r3
    inc r0
    loadn r1, #'7'
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #40
    sub r0, r0, r3
    loadn r1, #'2'
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    dec r0
    loadn r1, #'1'
    add r1, r1, r2
    outchar r1, r0
    load r0, dino_pos
    inc r0
    loadn r1, #'3'
    add r1, r1, r2
    outchar r1, r0
    
    ; --- ÁRVORE ---
    load r0, cactus_pos
    loadn r1, #'$'
    loadn r2, #3072      ; Vermelho/Marrom
    add r1, r1, r2
    outchar r1, r0
    
    loadn r3, #39
    sub r0, r0, r3       
    loadn r1, #'%'
    loadn r2, #3072      ; Verde
    add r1, r1, r2
    outchar r1, r0

    ; --- NUVENS ---
    loadn r2, #0           
    load r0, cloud1_pos
    loadn r1, #'8'
    add r1, r1, r2
    outchar r1, r0           
    inc r0
    loadn r1, #'9'
    add r1, r1, r2
    outchar r1, r0           
    load r0, cloud2_pos
    loadn r1, #'8'
    add r1, r1, r2
    outchar r1, r0           
    inc r0
    loadn r1, #'9'
    add r1, r1, r2
    outchar r1, r0           
    
    pop r3
    pop r2
    pop r1
    pop r0
    rts

erase_actors:
    push r0
    push r1
    push r2
    push r3

    ; COR DE FUNDO (AZUL)
    loadn r1, #' '           
    loadn r2, #2560          
    add r1, r1, r2           

    ; Apaga Dinozord
    load r0, dino_pos
    loadn r3, #120
    sub r0, r0, r3
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80
    sub r0, r0, r3
    outchar r1, r0
    dec r0
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #80
    sub r0, r0, r3
    inc r0
    outchar r1, r0
    load r0, dino_pos
    loadn r3, #40
    sub r0, r0, r3
    outchar r1, r0
    load r0, dino_pos
    dec r0
    outchar r1, r0
    load r0, dino_pos
    inc r0
    outchar r1, r0
    
    ; --- APAGA ÁRVORE ---
    load r0, cactus_pos
    outchar r1, r0
    
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
    rts

clear_screen:
    push r0
    push r1
    push r2
    loadn r0, #1199
    loadn r1, #' '           
    loadn r2, #2560          
    add r1, r1, r2           
loop_clear:
    outchar r1, r0           
    dec r0
    loadn r2, #0
    cmp r0, r2
    jgr loop_clear
    outchar r1, r0
    pop r2
    pop r1
    pop r0
    rts

print_str:
    push r0
    push r1
    push r2
    push r3
    push r4
    loadn r3, #'\0'
loop_print:
    loadi r4, r1
    cmp r4, r3
    jeq end_print
    add r4, r2, r4
    outchar r4, r0
    inc r0
    inc r1
    jmp loop_print
end_print:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

delay_frame:
    push r0
    push r1
    load r0, game_speed 
delay_loop:
    dec r0
    jnz delay_loop
    pop r1
    pop r0
    rts
