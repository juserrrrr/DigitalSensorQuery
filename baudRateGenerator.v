module baudRateGenerator(clk, baudRate);

input clk; // 50 mhz
output baudRate; // 9600 hz

reg baud;
reg [12:0] baudReg = 0;


buf(baudRate, baud);

always @(posedge clk)
begin
	baudReg <= baudReg + 1;
	
	// o valor da contagem deve ser igual à (metade do baud rate desejado) - 1
	// para um clock de 50mhz numa baudrate de 9600, o valor é (5208/2) - 1 = 2603
	if (baudReg == 2603)
		begin
			baud <= !baud;
			baudReg <= 0;
		end
	

end

endmodule