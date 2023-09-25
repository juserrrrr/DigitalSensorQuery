/*
	Esse módulo recebe o "serialIn" do cabo uart conectado ao pc e coloca os bits primeiro no
	"addressIn" e depois no "commandIn", já que as requisições são sempre comando+endereço.
	
	Os inputs "address_out" e "command_out" são os dados em paralelo que serão enviados pela 
	"serial_out" assim que um bit 1 seja detectado no fio "start_send"

 */



module uart(serialIn, serial_out, baudClk, 
addressIn, commandIn, address_out, command_out, value_out, start_send, clearUart);

input wire serialIn;
input wire baudClk;

input wire clearUart;

output reg serial_out = 1;
reg error;

output reg [7:0] addressIn = 8'b00000000;
input [7:0] address_out;
output reg [7:0] commandIn = 8'b11111111;
input [7:0] command_out;
input [7:0] value_out;

reg [4:0] counter = 0;
reg [4:0] counter_sender = 0;
reg [2:0] parity_counter = 0;
reg [2:0] parity_counter_sender = 0;
reg [2:0] state_reciever = 0;
reg [2:0] state_sender = 0;

reg addressOrCommand = 0; // 0 = saving address, 1 = saving command
reg [1:0]address_or_command_sender = 0;

input start_send;

localparam [2:0]
	idle = 0,
	data_reciever = 1,
	parity_bit = 2,
	stop_bit = 3,
	data_sender = 4;
	 


always @(posedge baudClk) begin

	case (state_reciever)
	
		idle:
			begin
				if (serialIn == 0) begin
				
					counter <= 0;
					parity_counter <= 0;
					state_reciever <= data_reciever;
					
				end
				
				if (clearUart == 1) begin
					commandIn <= 8'b11111111;
					
				end
			end
			

		data_reciever:
			begin
				error <= 0;
			
				if (addressOrCommand == 0)
					addressIn[counter] <= serialIn;
				else
					commandIn[counter] <= serialIn;
		
				counter = counter + 1;
				parity_counter <= parity_counter + serialIn;
				
				if (counter == 8) begin
					addressOrCommand <= ~addressOrCommand;
					state_reciever <= stop_bit;		
				end
			end
				
		stop_bit:
			begin
				state_reciever <= idle;
			end
			
	endcase
end

always @(posedge baudClk) begin

	case (state_sender)
		
		idle:
		
			begin
				serial_out <= 1;
				if (start_send) begin
					counter_sender = 0;
					//parity_counter_sender = 0;
					state_sender <= data_sender;
				end
				
			end
			
			
		data_sender:
		
			begin
			
				if (counter_sender == 0)
					serial_out <= 0;
					
				else if (counter_sender == 8)
					begin
						if (address_or_command_sender == 0) begin
							address_or_command_sender <= 1;
						end else if (address_or_command_sender == 1) begin
							address_or_command_sender <= 2;
						end else
						address_or_command_sender = 0;
						state_sender <= stop_bit;
					end
					
				else	begin 
					if (address_or_command_sender == 0)
						begin
							serial_out <= address_out[counter_sender - 1];
						end
					else if(address_or_command_sender == 1)
						begin
							serial_out <= command_out[counter_sender - 1];
						end
					else 
					    begin
					        serial_out <= value_out[counter_sender - 1];
					    end
				end
				
				counter_sender = counter_sender + 1;
			end
			
		stop_bit:
			
			begin
				serial_out <= 1;
				if (address_or_command_sender == 1 || address_or_command_sender == 2 )
					begin
						counter_sender = 0;
						state_sender <= data_sender;
					end
				else
					state_sender <= idle;
					
			end
			
	endcase

end




endmodule























/*
	Esse módulo recebe o "serialReceiver" do cabo uart conectado ao pc e coloca os bits primeiro no
	"addressIn" e depois no "commandIn", já que as requisições são sempre comando+endereço.
	
	Os inputs "addressOut" e "commandOut" são os dados em paralelo que serão enviados pela 
	"serialTransmitter" assim que um bit 1 seja detectado no fio "startSend"


module uart(
	input baudClk, 														//Clock referente a tramissão dos bits.
	input clearUart,														//Limpa o ultimo comando recebido pela uart
	 
	input serialReceiver,												//Entrada serial dos bits.
	output reg [7:0] addressIn,                  				//Armazenamento do endereço de entrada do serialReceiver.
	output reg [7:0] commandIn,                   				//Armazenamento do comando de entrada do serialReceiver.
	
	input startSend,                   								//Ativa o envio de bits pela saída serial.
	output reg serialTransmitter,                   			//Saída serial dos bits.
	input [7:0] addressOut,                    					//Entrada do endereço para o transmitir os bits.
	input [7:0] commandOut,                    					//Entrada do comando para o transmitir os bits.
	input [7:0] valueOut                    						//Entrada do valor para o transmitir os bits.
);


// Rx = Recebimentos/Receiver dos bits / Tx = Tranmissão/Transmitter dos bits.

reg [4:0] counterRx;                                        // Contador atrelado a máquina do recebimento dos bits
reg [4:0] counterTx;                                        // Contador atrelado a máquina de transmissão dos bits

reg [2:0] stateRx;                                        	// Estado atrelado a máquina do recebimento dos bits						
reg [2:0] stateTx;                                        	// Estado atrelado a máquina de transmissão dos bits

reg addressOrCommandRx; 												//Responsável por alternar entre o armazenamento de um comando ou endereço.
reg [1:0]addressOrCommandTx;											//Responsável por alternar entre a transmissão de um comando, endereço ou valor.



localparam [2:0] 															// CONSTANTES das transições de estados
	IDLE = 0,																// Estado para aguardar o startBit
	DATA_RECIEVER = 1,													// Estado para receber 1 byte
	STOP_BIT = 3,															// Estado para aguardar o stopBit
	DATA_SENDER = 4;														// Estado para transmitir 1 byte
	 
initial begin																//Definiçao dos valores inicias.
	serialTransmitter = 1;
end

always @(posedge baudClk) begin 										//Máquina responsável pelo recebimento dos bits.

	if (clearUart == 1) begin
		commandIn <= 8'b11111111;	
	end

	case (stateRx)
		IDLE: begin															//Estado responsável por aguardar o recebimento de um sinal de transmissão.
			if (serialReceiver == 0) begin
				counterRx <= 0;
				stateRx <= DATA_RECIEVER;	
			end
		end
		
		DATA_RECIEVER: begin												//Estado responsável por receber endereço e comando pela porta serial.
			if (addressOrCommandRx == 0)
				addressIn[counterRx] <= serialReceiver;
			else
				commandIn[counterRx] <= serialReceiver;
				
			counterRx = counterRx + 1;
			
			if (counterRx == 8) begin
				addressOrCommandRx <= ~addressOrCommandRx;
				stateRx <= STOP_BIT;		
			end
		end
				
		STOP_BIT: begin													//Estado responsável por aguardar o stopBit da porta serial.
				stateRx <= IDLE;
		end
	endcase
end

always @(posedge baudClk) begin 										//Máquina responsável pela transmissão dos bits.

	case (stateTx)
		
		IDLE: begin															//Estado responsável por aguardar o envio de um sinal de transmissão.
			serialTransmitter <= 1;
			if (startSend) begin
				counterTx = 0;
				stateTx <= DATA_SENDER;
			end
		end	
			
		DATA_SENDER: begin 												//Estado responsável por enviar endereço, comando e valor pela porta serial.
			if (counterTx == 1) begin
				serialTransmitter <= 0;
			end
				
			else if (counterTx == 10) begin
				addressOrCommandTx = addressOrCommandTx + 1;		//Responsavel por mudar se é endereço, comando ou valor que será transmitido.
				counterTx = 0;
				stateTx <= STOP_BIT;
			end
				
			else	begin 
				if (addressOrCommandTx == 0) begin
					serialTransmitter <= addressOut[counterTx - 2];
				end
				
				else if(addressOrCommandTx == 1) begin
					serialTransmitter <= commandOut[counterTx - 2];
				end
				
				else begin
					serialTransmitter <= valueOut[counterTx - 2];
				end
			end
			
			counterTx = counterTx + 1;
		end
			
		STOP_BIT: begin													//Estado responsável por mandar o stopBit para a porta serial.
			serialTransmitter <= 1;
			
			if (addressOrCommandTx == 3) begin
				addressOrCommandTx <= 0;
				stateTx <= IDLE;
			end 
			
			else begin
				stateTx <= DATA_SENDER;
			end
			
		end
	endcase
	
end

endmodule


 */





