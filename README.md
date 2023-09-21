# DigitalSensorQuery

# Projeto

## Introdução - Guilherme

## Manual do Usuário - Zé

## Metodologia - Thiago

As ferramentas utilizadas no desenvolvimento do projeto foram:
   - FPGA CYCLONE IV
   - Sensor(es) DHT11
   - Software Quartus II
   - Editor de Texto para escrita do código em C
   - Software Creately para modelagem do sistema e máquinas de estados

As etapas que foram seguidas em ordem cronológica, foram:
   1. Protocolo UART
   1.1. Estudo do funcionamento do protocolo de comunicação
   1.2. Desenvolvimento do Código em C responsável pela transmissão e recebimento dos dados pelo usuário
   1.3. Desenvolvimento do Código em Verilog da máquina de estados responsável pela UART na FPGA
   2. Sensor DHT11
   2.1. Estudo do funcionamento do DHT11 por meio da leitura do seu datasheet
   2.2. Desenvolvimento da máquina de estados em Verilog capaz de acionar o sensor e coletar a temperatura e a umidade
   2.3. Para funcionamento desta máquina, foram desenvolvidos:
   2.3.1. Um módulo Trie State para controle do fluxo de dados entre a FPGA e o sensor (Ora a FPGA manda sinal, ora o sensor manda sinal)
   2.3.2. Um módulo de geração de Clock com periódo de 1 microssegundo, já que o tempo das respostas do sensor é baseado em microssegundos
## Descrição do Projeto:
   - Diagrama em alto nível - Thiago
   - C - Mendes
   - UART - Zé
   - DHT11 - Thiago
   - STEPPER - Mendes

## Conclusão - Guilherme

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
