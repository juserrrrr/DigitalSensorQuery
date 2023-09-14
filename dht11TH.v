module dht(
	input clk, 							//clk de 1 microssegundo
	inout [31:0]dht_data, 			//pino de data do dht11
	input start_bit, 					//sinal de start para a máquina começar
	input [4:0]sensorIndex, 		//índice identificando qual sensor será requisitado
	output reg errorSensor, 		//pino de identificação de erro
	output reg done,                //reg de 1 bit para indicação de conclusão
	output [7:0]hum_int, 			//parte inteira da humidade
	output [7:0]hum_float, 			//parte float da humidade
	output [7:0]temp_int, 			//parte inteira da temperatura
	output [7:0]temp_float, 		//parte float da temperatura
	output [7:0]check_sum 			//8 bits de checagem
	);
	
	reg [31:0]direction; 			//registrador de 1 bit da direção do pino de data 
	reg [14:0]counter; 				//contador de 1 em 1 microssegundo
	reg [5:0]index; 					//registrador de index
	reg [39:0]temp_data; 			//registrador temporário de 40 bits
	reg [31:0]send; 					//registrador de 1 bit que manda sinal da fpga para o dht11
	wire [31:0]read; 					//leitura do dht11
	reg error; 							// Erro que aconteceu durante o procedimento
	
	//triState tris0(dht_data, direction, send, read);
	
	//tristates que alternam os 32 dht_data de input para output
	triState tris0(dht_data[0], direction[0], send[0], read[0]);
	triState tris1(dht_data[1], direction[1], send[1], read[1]);
	triState tris2(dht_data[2], direction[2], send[2], read[2]);
	triState tris3(dht_data[3], direction[3], send[3], read[3]);
	triState tris4(dht_data[4], direction[4], send[4], read[4]);
	triState tris5(dht_data[5], direction[5], send[5], read[5]);
	triState tris6(dht_data[6], direction[6], send[6], read[6]);
	triState tris7(dht_data[7], direction[7], send[7], read[7]);
	triState tris8(dht_data[8], direction[8], send[8], read[8]);
	triState tris9(dht_data[9], direction[9], send[9], read[9]);
	triState tris10(dht_data[10], direction[10], send[10], read[10]);
	triState tris11(dht_data[11], direction[11], send[11], read[11]);
	triState tris12(dht_data[12], direction[12], send[12], read[12]);
	triState tris13(dht_data[13], direction[13], send[13], read[13]);
	triState tris14(dht_data[14], direction[14], send[14], read[14]);
	triState tris15(dht_data[15], direction[15], send[15], read[15]);
	triState tris16(dht_data[16], direction[16], send[16], read[16]);
	triState tris17(dht_data[17], direction[17], send[17], read[17]);
	triState tris18(dht_data[18], direction[18], send[18], read[18]);
	triState tris19(dht_data[19], direction[19], send[19], read[19]);
	triState tris20(dht_data[20], direction[20], send[20], read[20]);
	triState tris21(dht_data[21], direction[21], send[21], read[21]);
	triState tris22(dht_data[22], direction[22], send[22], read[22]);
	triState tris23(dht_data[23], direction[23], send[23], read[23]);
	triState tris24(dht_data[24], direction[24], send[24], read[24]);
	triState tris25(dht_data[25], direction[25], send[25], read[25]);
	triState tris26(dht_data[26], direction[26], send[26], read[26]);
	triState tris27(dht_data[27], direction[27], send[27], read[27]);
	triState tris28(dht_data[28], direction[28], send[28], read[28]);
	triState tris29(dht_data[29], direction[29], send[29], read[29]);
	triState tris30(dht_data[30], direction[30], send[30], read[30]);
	triState tris31(dht_data[31], direction[31], send[31], read[31]);
	
	reg [3:0]state = 0; //registrador do estado
	
	//estados possíveis
	parameter IDLE=0, START=1, DETECT_SIGNAL=2, WAIT_DHT11=3, DHT11_RESPONSE=4, 
	DHT11_HIGH_RESPONSE=5, TRANSMIT=6, DETECT_BIT=7, WAIT_SIGNAL=8, STOP = 9;
	
	//copia os valores da variávek temporária para a saída
	assign hum_int[7:0] = temp_data[39:32];
	assign hum_float[7:0] = temp_data[31:24];
	assign temp_int[7:0] = temp_data[23:16];
	assign temp_float[7:0] = temp_data[15:8];
	assign check_sum[7:0] = temp_data[7:0];

	
	initial begin
		send <= 32'hFFFFFFFF;
		direction <= 32'hFFFFFFFF; //Direção é do FPGA para o sensor
	end
	
	always @(posedge clk) begin
		
		case(state)
			IDLE: begin//Se estado for START
				error <= 0;
				done <= 0;
				errorSensor <=0;
				if (start_bit ==1) begin
					temp_data = 0; //temp_data resetado
					index = 0; //index resetado
					send[sensorIndex] <= 0; //envia 0 para o sensor
					counter <= 0; //contador resetado	
					state <= START;
				end	
			end
			START: begin//Se estado for START
				counter <= counter + 1;
				if(counter == 19000) begin //Quando chegar a 19ms...
					counter <= 0; //reseta o contador
					send[sensorIndex] <= 1; //envia 1 para o sensor
					state <= DETECT_SIGNAL; //próximo estado
				end
			end
			
			DETECT_SIGNAL:begin//Se estado for DETECT_SIGNAL // 2
				counter <= counter + 1;
				if(counter == 20) begin //Enquanto não der 20us...
					counter <= 0; //reseta o contador
					direction[sensorIndex] <= 0; //agora o dht11 que manda sinal para a FPGA
					state <= WAIT_DHT11; //próximo estado
				end
			end
			
			WAIT_DHT11: begin//Se estado for WAIT_DHT11  // 3
				counter <= counter + 1;
				if(counter == 21 || read[sensorIndex] == 0) begin //Enquanto não der 40 ou 41us...
					counter <= 0; //reseta o contador
					direction[sensorIndex] <= 0; //agora o dht11 que manda sinal para a FPGA
					state <= DHT11_RESPONSE; //próximo estado
				end
			end
			
			DHT11_RESPONSE:  begin//Se estado for DHT11_RESPONSE // 4
				counter <= counter + 1;
				if(read[sensorIndex] == 1 || counter == 100) begin //enquanto o sinal for 0 e contagem durar até 80 us...
					counter <= 0;
					if(read[sensorIndex] == 0) begin //caso passado o tempo e o dht11 manteve o 0 de sinal, deu erro
						error <= 1;
						state <= WAIT_SIGNAL; //estado de STOP
					end else begin //caso passado o tempo ou dht11 mudou o sinal para 1
						state <= DHT11_HIGH_RESPONSE; //próximo estado
					end
				end 
			end
			
			DHT11_HIGH_RESPONSE: begin//Se estado for DHT11_HIGH_RESPONSE  // 5
				counter <= counter + 1;
				if(read[sensorIndex] == 0 || counter == 100) begin //enquanto o sinal for 1 e contagem durar até uns 100 us... ***
					if(read[sensorIndex] == 1) begin //caso passado o tempo e o dht11 manteve o 1 de sinal, deu erro
						counter <= 0;
						error <= 1;
						state <= WAIT_SIGNAL; //estado de STOP
					end else begin //caso passado o tempo ou dht11 mudou o sinal para 0 ******
						counter <= 0;
						state <= TRANSMIT; //próximo estado
					end
				end
			end
			
			TRANSMIT: begin//Se estado for TRANSMIT (começa transmissão dos bits) // 6
				if(index < 40) begin //enquanto index for menor que 40
					counter <= counter + 1;
					if(read[sensorIndex] == 1 || counter == 70) begin //enquanto o sinal for 0 e contagem durar até 50 us...
						counter <= 0;
						if(read[sensorIndex] == 0) begin //caso passado o tempo e o dht11 manteve o 0 de sinal, deu erro
							error <= 1;
							state <= WAIT_SIGNAL; //estado de STOP
						end else begin //caso passado o tempo ou dht11 mudou o sinal para 1
							state <= DETECT_BIT; //próximo estado
						end
					end
				end else begin //estorou o número limite de 40 bits
					state <= WAIT_SIGNAL; //estado de STOP
				end
			end
			
			DETECT_BIT: begin//Se estado for DETECT_BIT (detecção se o bit é 0 ou 1) // 7
				if(read[sensorIndex] == 1) begin //enquanto a leitura do sinal for 1
					counter <= counter + 1;
				end else begin
					if(counter > 50) begin //se a contagem do tempo extrapolou 50us(Meio a meio do limite 30 ~ 70us) 
						temp_data[39-index] <= 1; //bit 1
					end else begin //senão
						temp_data[39-index] <= 0; //bit 0
					end
					counter <= 0; //reseta contador
					index <= index + 1; //incrementa em 1 o index
					state <= TRANSMIT; //volta para transmit
				end
			end
			WAIT_SIGNAL: begin// Tempo para aguardar livramento do sinal pelo dht11 // 8
				counter <= counter + 1;
				if (counter == 100) begin // Tempo de 100us para garantir que está livre para uso novamente
					counter <= 0;
					send[sensorIndex] <=1;
					direction[sensorIndex] <= 1; //Direção é do FPGA para o sensor
					state <= STOP; // Volta para o estado final da maquina.
				end
			end
			
			STOP: begin//Se o estado for STOP, parou a transmissão com sucesso ou erro // 9
				if(error == 1)
					errorSensor <= 1;
				done <= 1;
				state <= IDLE; // Manda para o estado inicial.
			end
			
		endcase
	end
	
	
	
endmodule 	


