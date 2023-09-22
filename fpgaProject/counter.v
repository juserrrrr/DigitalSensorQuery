module counter(clk, rst, count);
	input clk;
	output reg [15:0] count;
	input rst;
	
	
	
always @(posedge clk) begin
	
	if (rst == 1)
		count <= 0;
	else if (count == 16'b111111111111111)
		count <= 0;
	else
		count <= count + 1;
	
end



endmodule