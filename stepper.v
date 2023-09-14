module stepper(baudRate, serialFromPc, serialToPc, clkMicroSec, sensor, 
clk);

input baudRate;
input serialFromPc;
input clkMicroSec; // 1 pulso = 1 microssegundo
input clk; // 50mhz

reg clearUart; // essa variavel limpa o comando atual da uart, é utilizada sempre que um comando é lido

inout [31:0]sensor; // sensor dht11

output serialToPc; // serial que ira ir pela uart para o pc


// arrays onde cada indice representa um sensor, 1=continuo 0=nao continuo
reg [32:0] constantTemperature = 33'h00; 
reg [32:0] constantHumidity = 33'h00;


// comando e endereco que vieram atraves da uart do pc para a fpga
wire [7:0] commandFromPc;
wire [7:0] addressFromPc;


// comando e endereco que serao tratados para serem enviados para a uart
reg [7:0] commandToPc;
reg [7:0] addressToPc;


// comando e endereco que serao enviados pela uart, apos a junção do byte de valor com os outros 2 bytes
wire [7:0] commandAndValueToPc;
wire [7:0] addressAndValueToPc;


// valor que sera unido aos bytes de comando e endereco para ser enviado pela uart
reg [7:0] valueToPc;


// contador que representa o indice que esta sendo verificado no momento nos estados de verificação constante
// quando chega em 31 é resetado
reg [7:0] constIndex = 0;


// estado atual
reg [6:0] state = 0;


// contador da maquina
wire [15:0] counter;


// indice do sensor dht11 a ser utilizado, é enviado ao módulo dht, é atualizado toda vez q um endereco é recebido
reg [4:0] sensorIndex = 0;

wire [7:0]hum_int; //parte inteira da humidade
wire [7:0]hum_float; //parte float da humidade
wire [7:0]temp_int; //parte inteira da temperatura
wire [7:0]temp_float; //parte float da temperatura
wire [7:0]check_sum; //8 bits de checagem

wire doneDht; // fica 1 quando o dht11 termina uma transmissao
wire timeToSendUart; // segura o pulso que vem no doneDht por varios pulsos de clock, para q seja possivel detecta-lo
wire dhtError; // representa um erro na transmissao do dht
reg startDht = 0; // inicia o dht
reg startSendUart = 0; // inicia a uart
reg resetCounter; // reseta a maquina do contador

dht(
	.clk(clkMicroSec), 			//clk de 1 microssegundo
	.dht_data(sensor), 			//pino de data do dht11
	.start_bit(startDht), 		//sinal de start para a máquina começar
	.sensorIndex(sensorIndex),	//índice identificando qual sensor será requisitado
	.errorSensor(dhtError), 	//pino de identificação de erro
	.done(doneDht),				//fica em 1 quando o dht termina a leitura
	.hum_int(hum_int), 			//parte inteira da humidade
	.hum_float(hum_float), 		//parte float da humidade
	.temp_int(temp_int), 		//parte inteira da temperatura
	.temp_float(temp_float),	//parte float da temperatura
	.check_sum(check_sum)		//8 bits de checagem
);



// Nessa máquina, usar contadores normais não estava funcionando
// Entao foi necessario criar um modulo contador, e resetar quando queremos "counter <= 0"
counter(.clk(baudRate), .rst(resetCounter), .count(counter));
	
uart(
	.serialIn(serialFromPc), 
	.baudClk(baudRate), 
	.addressIn(addressFromPc), 
	.commandIn(commandFromPc), 
	.address_out(addressToPc), 
	.command_out(commandToPc), 
	.value_out(valueToPc),//addressAndValue, commandAndValue no lugar de address e comm
	.start_send(startSendUart), 
	.serial_out(serialToPc), 
	.clearUart(clearUart)
);

pulseSensorToTransmit(
	.clk(clkMicroSec), 
	.pulseInitial(doneDht), 
	.pulseFinal(timeToSendUart)
);


// parametros para os estados
localparam[2:0]
	sendingConstTemp = 0,
	sendingConstHum = 1,
	gettingNewCommand = 2,
	activateDht = 3,
	activateUart = 4;
	

reg [2:0] chosenInfo;	

// parametros para identificar qual informacao sera enviada no "value" pela uart, salvo em "chosenInfo"
localparam[2:0]
	sendTemp = 0,
	sendHum = 1,
	sendTempConst = 2, 	// necessario diferenciar as constantes, ja que apos enviar, a maquina deve voltar ao estado seguinte
	sendHumConst = 3,  	// exemplo: constTemp -> activateDht -> activateUart -> constHum (se tivesse vindo do gettingNewCommand...
	noValue = 4, 		  	// ...ele voltaria para o constTemp, e nao para o constHum)
	sendStatus = 5;

	
initial begin 

	state <= sendingConstTemp;
	
end
	
always @(posedge baudRate) begin
	
	
	case (state)
		sendingConstTemp:
			begin
				
				if (constantTemperature[constIndex] == 1) begin
					
					sensorIndex <= constIndex; // diz para o dht qual sensor ele deve ler
					addressToPc <= constIndex; // salva o endereço que será enviado para uart
					chosenInfo <= sendTempConst;
					commandToPc <= 8'h09;  //0x09 -> temperatura
					state <= activateDht;
					
				end else
					state <= sendingConstHum;

				resetCounter <= 1; // reseta o counter
					
			end
			
		sendingConstHum:
			begin
			
				if (constantHumidity[constIndex] == 1) begin
					
					sensorIndex <= constIndex; // diz para o dht qual sensor ele deve ler
					addressToPc <= constIndex; // salva o endereço que será enviado para uart
					chosenInfo <= sendHumConst;
					commandToPc <= 8'h08;  //0x08 -> humidade
					state <= activateDht;
					
				end else
					state <= gettingNewCommand;
				
				resetCounter <= 1; // reseta o counter
			
			end
			
		gettingNewCommand:
			begin
				
				if (commandFromPc == 8'h00) begin // envia status do sensor
				
					chosenInfo <= sendStatus;
					state <= activateDht;
					clearUart <= 1; // limpa o comando lido da uart
					valueToPc <= 8'h00;
					// o comando do status é atualizado apos passar pelo dht
				
				end else if (commandFromPc == 8'h01) begin // temperatura atual
				
					chosenInfo <= sendTemp;
					commandToPc <= 8'h09;  //0x09 -> temperatura
					state <= activateDht;
					clearUart <= 1; // limpa o comando lido da uart
				
				end else if (commandFromPc == 8'h02) begin // umidade atual
				
					chosenInfo <= sendHum;
					commandToPc <= 8'h08;  //0x08 -> humidade
					state <= activateDht;
					clearUart <= 1; // limpa o comando lido da uart
					
				end else if (commandFromPc == 8'h03) begin // ativa temperatura contínua
				
					chosenInfo <= noValue;
					constantTemperature[addressFromPc] <= 1;
					commandToPc <= 8'h0C;  //0x0C -> confirmacao ativamento continuo temperatura
					state <= activateUart;
					clearUart <= 1; // limpa o comando lido da uart
					valueToPc <= 8'h00;
					
				end else if (commandFromPc == 8'h04) begin // ativa umidade contínua
				
					chosenInfo <= noValue;
					constantHumidity[addressFromPc] <= 1;
					commandToPc <= 8'h0F;  //0x0D -> confirmacao ativamento continuo umidade
					state <= activateUart;
					clearUart <= 1; // limpa o comando lido da uart
					valueToPc <= 8'h00;
					
				end else if (commandFromPc == 8'h05) begin // desativa temperatura contínua
				
					chosenInfo <= noValue;
					commandToPc <= 8'h1A;  //0x0A -> confirmacao desativamento continuo temperatura				
					constantTemperature[addressFromPc] <= 0; // desativando o indice continuo respectivo
					state <= activateUart;
					clearUart <= 1; // limpa o comando lido da uart
					valueToPc <= 8'h00;
				
				end else if (commandFromPc == 8'h06) begin // desativa umidade contínua
					
					chosenInfo <= noValue;
					commandToPc <= 8'h0B;  //0x0B -> confirmacao desativamento continuo umidade	
					constantHumidity[addressFromPc] <= 0; // desativando o indice continuo respectivo
					state <= activateUart;
					clearUart <= 1; // limpa o comando lido da uart
					valueToPc <= 8'h00;
					
					
				end else 
					state <= sendingConstTemp; // volta para o comeco da maquina

				
				if (constIndex > 31) // a cada iteração é checado se um sensor esta contínuo, ate o index 31
					constIndex <= 0;
				else
					constIndex <= constIndex + 1;
				
				
				sensorIndex <= addressFromPc; // diz para o dht qual sensor ele deve ler
				addressToPc <= addressFromPc; // salva o endereço que será enviado para uart
				resetCounter <= 1; // reseta o counter
					
			end
		
		activateDht:
			begin
			
				if (counter < 10) begin
					resetCounter <= 0; // inicia o counter
					clearUart <= 0; // libera a uart para receber novos comandos
					startDht <= 1;
					
				end else if (counter == 10) begin	// tempo para garantir que o sensorIndex foi atualizado
					startDht <= 0; // liga o dht11
						
				end else if (timeToSendUart == 1) begin //sinal que o dht chegou no ultimo estado
					
					// seleciona qual valor sera enviado pela uart
					if (chosenInfo == sendTemp || chosenInfo == sendTempConst) begin
						valueToPc <= temp_int;
						
					end else if (chosenInfo == sendHum || chosenInfo == sendHumConst) begin
						valueToPc <= hum_int;
						
					end else if (chosenInfo == sendStatus) begin
						
						// necessario atualizar o comando de resposta apos dht, caso comando = sendStatus
						if (dhtError == 1)
							commandToPc <= 8'h1F; // sensor com problema
						else
							commandToPc <= 8'h07; // sensor ok
						
						valueToPc <= 8'h00;
					
					end else 
						valueToPc <= 8'h00;

					state <= activateUart;
					resetCounter <= 1; // reseta o counter
					
				end
				
							
			end
		
		activateUart:
			begin
				if (counter < 5) begin
					resetCounter <= 0; // inicia o counter
					clearUart <= 0; // libera a uart para receber novos comandos
					
				end else if (counter == 5) begin// tempo para garantir que o valueToPc foi atualizado
					startSendUart <= 1; // ativa a uart
					
				end else if (counter == 8) // tempo para garantir que a uart recebeu o sinal de start
					startSendUart <= 0; 
					
				else if (counter == 19200) begin// espera 2 segundos (19200 na baud rate) para prosseguir, necessario por conta do dht11
					
					if (chosenInfo == sendTemp || chosenInfo == sendHum || chosenInfo == noValue) // volta para o comeco, pois veio do gettingNewCommand
						state <= sendingConstTemp;
					
					else if (chosenInfo == sendTempConst) // vai para o de umidade constante, seguindo a ordem
						state <= sendingConstHum;
					
					else 
						state <= gettingNewCommand; // vai para o de receber um novo comando, seguindo a ordem	
					
					resetCounter <= 1;
				end
				
				
			end


	endcase
end

endmodule 