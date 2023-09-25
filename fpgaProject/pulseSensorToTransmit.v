module pulseSensorToTransmit(
	input clk,
	input pulseInitial,
	output reg pulseFinal
);
	
	reg state;										// Estado atual
	reg [10:0] countPulse = 0; 					// Contador de pulsos
	
	localparam  									// Declaração dos estados
		WAIT_PULSE = 0,
		SEND_PULSE = 1;

	
	always @(posedge clk) begin
		case (state)
			WAIT_PULSE: begin 					// Estado responsável por aguardar um pulso.
				if(pulseInitial == 1) begin
					state <= SEND_PULSE;
				end
			end
			SEND_PULSE: begin 					// Estado para segurar o pulso por aproximadamente 9600bps.
				countPulse <= countPulse + 1;
				if(countPulse == 102) begin
					countPulse <= 0;
					state <= WAIT_PULSE;
				end
			end
		endcase
	end	
	
	always @(state) begin						// Saídas da máquina, no caso o pulso.
		case (state)
			WAIT_PULSE: 				
				pulseFinal <= 0;
			SEND_PULSE: 	
				pulseFinal <= 1;
		endcase
	end	

endmodule 