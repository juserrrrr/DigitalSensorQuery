module triState(
	inout port,		//pino FPGA que se comunica com o sensor
	input direction,	//direção
	input send,		//sinal enviado da FPGA para o sensor
	output read		//sinal lido pela FPGA que vem do sensor
	);
	
	//Se direcao = 1, então porta vai atuar como saida
	assign port = direction ? send : 1'bZ;
	//Se direcao = 0, então porta vai atuar como entrada
	assign read = direction ? 1'bZ : port;
	
endmodule 
