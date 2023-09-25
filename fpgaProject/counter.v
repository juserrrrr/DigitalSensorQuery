module counter(clk, rst, count);
	input clk;			//clock
	output reg [15:0] count;	//contador
	input rst;			//reset
	
	
	
always @(posedge clk) begin
	
	if (rst == 1) //reset = 1, reinicia a contagem
		count <= 0;
	else if (count == 16'b111111111111111) // se chegar a contagem no limite, reinicia a contagem
		count <= 0;
	else
		count <= count + 1; //contagem incrementada
	
end



endmodule
