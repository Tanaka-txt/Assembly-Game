
# 🦖 CALCULUS HORROR
#### "Aceleração infinita, precisão milimétrica e o terror do Cálculo."

Este projeto é uma implementação completa de um jogo estilo Endless Runner desenvolvido inteiramente em Assembly para o Processador ICMC. O jogo apresenta física de pulo, geração procedural de obstáculos, detecção de colisão avançada e renderização gráfica direta na memória de vídeo.

![Status do Projeto](https://img.shields.io/badge/Status-Concluído-brightgreen)
![Propósito](https://img.shields.io/badge/Propósito-Aprendizado-blue)
---

📸 Screenshots
![image](Pasted%20image.png)

#### Link vídeo: https://youtu.be/kaRp4521eVg

---

## 🎮 Funcionalidades
Motor de Física de 4 Estados: Implementação de máquina de estados para controlar o pulo do dinossauro (Chão -> Subindo -> Topo/Hover -> Descendo).

Geração Procedural (RNG): Utiliza um algoritmo baseado na semente r7 e na pontuação atual para gerar padrões de obstáculos aleatórios, garantindo que nenhuma partida seja igual à outra.

Aceleração Infinita: Não há limite de velocidade. A cada obstáculo superado, o delay de clock diminui, levando o processador ao seu limite físico de execução.

Anti-Hold Input: Sistema que impede o jogador de "voar" segurando a tecla de espaço. Exige cliques precisos para cada pulo.

Hitboxes Precisas: O sistema de colisão verifica não apenas o centro, mas as extremidades do sprite do dinossauro contra o tronco e a copa das árvores.

---

## 🕹️ Como Jogar
Carregue o código .asm no Simulador do Processador ICMC.

Inicie a execução.

Pressione ESPAÇO para iniciar o jogo na tela de título.

Pressione ESPAÇO para pular os obstáculos ($q).

Objetivo: Sobreviver o máximo possível enquanto a velocidade aumenta exponencialmente.

---

## 🛠️ Detalhes Técnicos
Este jogo foi desenvolvido para demonstrar domínio sobre a arquitetura de computadores e manipulação de baixo nível. Abaixo estão os destaques da implementação:

#### 1. Manipulação de Memória de Vídeo
O jogo não utiliza bibliotecas gráficas. Toda a renderização é feita escrevendo diretamente nos endereços de memória de vídeo (0 a 1199).

Cores: Utiliza-se a técnica de somar offsets ao caractere ASCII (ex: +2560 para fundo azul, +512 para verde).

Clipping: Implementamos lógica para evitar que objetos desenhados nas bordas da tela "quebrem" para a linha seguinte.

#### 2. O Algoritmo "Calculus Horror" (Aceleração)
A dificuldade do jogo é gerida pela subrotina de delay. Diferente de jogos tradicionais com velocidade máxima, aqui subtraímos ciclos de clock a cada ponto:

```

; Trecho da lógica de aceleração
load r3, game_speed     
loadn r4, #40           
sub r3, r3, r4          ; Reduz o delay em 40 ciclos
loadn r4, #5            
cmp r3, r4
jle force_min           ; Trava no limite físico de 5 ciclos
```

#### 3. Padrões de Obstáculos (RNG)
Utilizamos o registrador r7 como semente, incrementado freneticamente durante a tela de espera (baseado no tempo de reação humano). O jogo escolhe entre 3 padrões de árvores usando a instrução MOD:

- Padrão 0: Dupla Colada ($q$q)

- Padrão 1: Trio Espalhado ($q .. $q .. $q)

- Padrão 2: Gap Longo ($q ..... $q)

#### 4. Sprite "Dinozord"
O personagem não é um caractere único, mas um sprite composto ("Dinozord") desenhado com múltiplos caracteres numéricos para criar volume e animação estática:

```
  5
6 4 7   (Cabeça e Corpo)
  2
1   3   (Pés)
```

---

## 📂 Estrutura do Código
main: Inicialização de vetores de interrupção e variáveis globais.

game_loop: O laço principal que orquestra renderização, física e lógica.

update_physics: Máquina de estados finitos (FSM) para o pulo.

move_obstacle: Gerencia a posição dos inimigos e chama o RNG.

check_collision: Matemática de vetores 1D para detectar impacto.

draw_actors / erase_actors: Manipulação direta de buffer de vídeo.

---

## 👨‍💻 Autors
Projeto desenvolvido para a disciplina de Arquitetura de Computadores (BSI 2025 - USP/ICMC).

**Dev.Tanaka**

**Ryan Sulino**

**Leo Eid**

<div align="center"> <sub>Feito com 💀 e Assembly no ICMC.</sub> </div>

