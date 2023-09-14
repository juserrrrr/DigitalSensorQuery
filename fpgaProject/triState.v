module triState(
	inout port, 
	input direction,
	input send,
	output read
	);
	
	//Se direcao = 1, então porta vai atuar como saida
	assign port = direction ? send : 1'bZ;
	//Se direcao = 0, então porta vai atuar como entrada
	assign read = direction ? 1'bZ : port;
	
endmodule 