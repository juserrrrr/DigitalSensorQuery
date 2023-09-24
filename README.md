# DigitalSensorQuery

# Projeto

## Introdução - Guilherme

## Metodologia


## Descrição do Projeto:

### Diagrama em alto nível

### C - Mendes

### UART

A UART, ou Universal Asynchronous Receiver/Transmitter, é um componente vital na comunicação entre dispositivos microcontroladores. Ela permite a transmissão e recepção de dados de forma assíncrona, sem a necessidade de um sinal de clock compartilhado entre os dispositivos.

O transmissor UART é responsável por enviar os dados do dispositivo de origem para o destino. Funciona enviando os dados em pacotes, iniciando com um bit de início (start bit) para sincronização. Os bits de dados são transmitidos, geralmente, com o menos significativo primeiro. Opcionalmente, um bit de paridade pode ser incluído para detecção de erros. Por fim, um ou mais bits de parada são anexados para indicar o fim da transmissão.

O receptor UART no dispositivo de destino decodifica os dados recebidos. Ele aguarda o início de um pacote detectando o bit de início, e lê os bits de dados conforme são recebidos. Se a paridade for utilizada, o receptor verifica se o número de bits de dados recebidos está correto. Ao identificar os bits de parada, determina o fim da transmissão e decodifica os bits de volta aos dados originais.

### DHT11 - Thiago

### STEPPER - Mendes

## Descrição e análise dos testes

Durante o processo de teste, o projeto enfrentou diversos desafios, os quais foram essenciais para aprimorá-lo. Esses testes incluíram simulações no próximo Quartus, abrangendo aspectos como o DHT e a UART. No entanto, o verdadeiro teste de fogo para o funcionamento do projeto veio com os testes reais.

Estes últimos foram conduzidos com o objetivo de avaliar praticamente cada módulo de forma independente. Por exemplo, o sensor DHT11 foi integrado a um único botão com pulso para minimizar ruídos. Em seguida, utilizando um osciloscópio, foi verificado se o sensor realmente respondeu corretamente, observando as ondas geradas.

Ao final, foi realizado um teste completo do projeto em conjunto para validar se as respostas estavam de acordo com as expectativas iniciais. Essa validação foi feita através do código C, que foi elaborado especificamente para receber e enviar dados pela UART via porta serial. Por sua vez, o código C foi criado e testado em conjunto com o módulo UART, como forma de observar se os dados mandados pela FPGA, assim como os recebidos, estavam de acordo com os valores passados manualmente.

## Conclusão - Guilherme

## Autores

- José Gabriel de Almeida Pontes
- Luis Guilherme Nunes Lima
- Pedro Mendes
- Thiago Pinto Pereira Sena
