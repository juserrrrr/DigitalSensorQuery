# DigitalSensorQuery

# Projeto

## Introdução - Guilherme

## Manual do Usuário - Zé

## Metodologia - Thiago

## Descrição do Projeto:
   - Diagrama em alto nível - Thiago
   ### C
   A comunicação do computador com a FPGA é feita através de um cabo serial, utilizando o protocolo UART que será detalhado na próxima seção. Essa comunicação é controlada por dois códigos em C salvos em arquivos distintos, o "read_uart.c" e o "write_uart.c"
   #### read_uart.c
   Esse arquivo serve para ler a porta serial continuamente.
   
   As principais funções são:
   
   - hexToBinString: recebe um "unsigned char" e transforma-o em uma string com 8 caracteres, cada caractere representa um bit e pode ser 0 ou 1, para realizar essa função foi utilizado o LSL (Logic Shift Left) e um comparador de bits (&) para "iterar" sobre os bits do char e ir guardando um a um na string.
      
   - binToInt: recebe a string com os 8 bits gerada na função anterior e converte em um número inteiro.
      
   - printAllSensors: printa todos os 32 sensores em uma tabela, o valor de temperatura e umidade nessa tabela é mostrado somente se o sensor estiver em modo contínuo.
      
   - printAndRunCurrentCommand: recebe o comando, endereço e valor recebidos e printa a última requisição lida.
      
   - main: na função principal existe o comando de abertura da porta serial em modo de leitura e um laço "while", que é atualizado a cada segundo e lê 3 bytes da porta  a cada atualização. Os bytes são, respectivamente, endereço, comando e valor. Ela envia os valores recebidos para as demais funções e printa informações para debug, como os valores recebidos em formato binário, inteiro e hexadecimal, e a quantidade de bytes lidos.

Os comandos recebidos são lidos e interpretados, seguindo a seguinte tabela:

   | Comando | Descrição |
| ---  | --- |
|  0x1F | Sensor Com Problema  |
|  0x07 | Sensor Ok |
|  0x09 | Medida de Temperatura |
| 0x08 | Medida de Umidade |
| 0x0C | Confirmação Ativamento Contínuo Temperatura |
|  0x0F | Confirmação Ativamento Contínuo Umidade |
|  0x1A | Confirmação Desativamento Contínuo Temperatura|
|  0x0B | Confirmação Desativamento Contínuo Umidade|
     
   #### write_uart.c
   Esse arquivo serve para escrever bytes na porta serial

   A única função presente nele é a main, onde o usuário pode digitar o endereço e o comando do pedido. Cada requisição tem o formato "XX YY" onde XX é um número inteiro de 0 a 31 representando o sensor, e YY é uma string contendo dois chars que representam o comando.
   Cada comando é convertido para o seu código binário correspondente, antes de ser enviado pela UART, seguindo a seguinte tabela:
   
   | Comando | Hexadecimal | Função |
| --- | --- | --- |
| `SS` | 0x00 | Situação do Sensor  |
| `TT` | 0x01 | Temperatura Atual |
| `UU` | 0x02 | Umidade Atual |
| `TC` | 0x03 | Ativar Temperatura Contínua |
| `UC` | 0x04 | Ativar Umidade Contínua |
| `DT` | 0x05 | Desativar Temperatura Contínua |
| `DU` | 0x06 | Desativar Umidade Contínua |
   
   - UART - Zé
   - DHT11 - Thiago
   ### STEPPER
   ![Diagrama Stepper](https://github.com/juserrrrr/DigitalSensorQuery/blob/main/public/img/stepper.png)

   O módulo Stepper serve para escalonar as requisições que vêm do computador com as requisições contínuas dos 32 sensores. Existem 5 estados na máquina, sendo eles:

   - SendingConstTemp: é o primeiro estado da máquina, nele é verificado se um dos 32 sensores está em monitoramento contínuo de temperatura, caso esteja, a máquina irá para o ActivateDht e logo em seguida ao ActivateUart, caso contrário, ela passa para o próximo estado.
   - SendindConstHum: segue a mesma lógica do anterior, porém verificando a umidade constante.
   - GettingNewCommand: nesse estado, é verificado se existe algum comando que veio do computador salvo na "memória", caso exista, o comando é executado (no ActivateDht e ActivateUart), e logo em seguida a máquina volta para o primeiro estado.
   - ActivateDht: aqui a máquina do DHT11 recebe um bit de início, o estado espera até que ela envie o bit de término, para então ir para o próximo estado.
   - ActivateUart: aqui a máquina da UART é ativada para enviar o comando de resposta, além do endereço do sensor requisitado e o valor pedido. Nesse estado existe um contador de 2 segundos, pois a máquina do DHT11 precisa desse tempo para receber um novo comando.

## Conclusão - Guilherme

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
