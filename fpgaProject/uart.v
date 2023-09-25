/*
	Esse módulo recebe o "serialIn" do cabo uart conectado ao pc e coloca os bits primeiro no
	"addressIn" e depois no "commandIn", já que as requisições são sempre comando+endereço.
	
	Os inputs "address_out" e "command_out" são os dados em paralelo que serão enviados pela 
	"serial_out" assim que um bit 1 seja detectado no fio "start_send"

 */



module uart(serialIn, serial_out, baudClk, 
addressIn, commandIn, address_out, command_out, value_out, start_send, clearUart);

input wire serialIn; 		//Entrada serial que vem do PC
input wire baudClk;		//Clock em 9600 bps

input wire clearUart;		//Variável de limpeza da UART

output reg serial_out = 1;	//Saída serial da UART
reg error;			//Erro na transmissão

//Endereço do sensor, comando de requisição ou resposta e valor de temp/umid
output reg [7:0] addressIn = 8'b00000000;
input [7:0] address_out;
output reg [7:0] commandIn = 8'b11111111;
input [7:0] command_out;
input [7:0] value_out;

//registradores
reg [4:0] counter = 0;
reg [4:0] counter_sender = 0;
reg [2:0] state_reciever = 0;
reg [2:0] state_sender = 0;

reg addressOrCommand = 0; // 0 = endereço enviado, 1 = comando enviado
reg [1:0]address_or_command_sender = 0;

input start_send;

//Estados da máquina
localparam [2:0]
	idle = 0,
	data_reciever = 1,
	stop_bit = 2,
	data_sender = 3;
	 

//UART RX
always @(posedge baudClk) begin

	case (state_reciever)
	
		idle: //Estado de espera
			begin
				if (serialIn == 0) begin //se chegou o start bit
					counter <= 0;
					state_reciever <= data_reciever;
					
				end
				
				if (clearUart == 1) begin		//Limpar o comando
					commandIn <= 8'b11111111;
					
				end
			end
			
		data_reciever: //Estado de recebimento dos 8 bits
			begin
				error <= 0;
			
				if (addressOrCommand == 0) //Conferência se é comando ou endereço
					addressIn[counter] <= serialIn;
				else
					commandIn[counter] <= serialIn;
		
				counter = counter + 1; //incrementa a contagem
				
				if (counter == 8) begin //Se enviu todos os 8 bits, alterna o modo de endereço para comando, ou o contrário
					addressOrCommand <= ~addressOrCommand;
					state_reciever <= stop_bit; //Passa para o próximo estado		
				end
			end
				
		stop_bit: //estado de stop que perdura por um clock
			begin
				state_reciever <= idle; //retorna para o estado de espera
			end
			
	endcase
end

//UART TX
always @(posedge baudClk) begin

	case (state_sender)
		
		idle: //estado de espera
			begin 
				serial_out <= 1; // em IDLE
				if (start_send) begin //Se houve um aviso da unidade de controle para envio dos 3 bytes...
					counter_sender = 0;
					state_sender <= data_sender; //alterna para o estado de identificação dos bits
				end
				
			end
			
			
		data_sender:
		
			begin
			
				if (counter_sender == 0) //Detecção do start bit
					serial_out <= 0;
					
				else if (counter_sender == 8) //Se conclui o envio dos 8 bits...
					begin
						if (address_or_command_sender == 0) begin //Se recebeu o endereço do sensor, vai para o comando
							address_or_command_sender <= 1;
						end else if (address_or_command_sender == 1) begin //Se recebeu o comando, vai para o valor
							address_or_command_sender <= 2;
						end else //Se recebeu o valor, retorna para o endereço do sensor
							address_or_command_sender = 0;
						state_sender <= stop_bit; //Vai para o envio do stop bit
					end
					
				else	begin //envio dos 8 bits...
					if (address_or_command_sender == 0) //se for endereço do sensor
						begin
							serial_out <= address_out[counter_sender - 1]; //salva aqueles bits no vetor adress_out
						end
					else if(address_or_command_sender == 1) //se for comando
						begin
							serial_out <= command_out[counter_sender - 1]; //salva aqueles bits no vetor comand_out
						end
					else 
					    begin //se for valor de temp/umid
						    serial_out <= value_out[counter_sender - 1]; //salva aqueles bits no vetor value_out
					    end
				end
				
				counter_sender = counter_sender + 1; //incrementa a contagem
			end
			
		stop_bit:
			
			begin
				serial_out <= 1; //envio do stop_bit
				if (address_or_command_sender == 1 || address_or_command_sender == 2 ) //Se já foi enviado o endereço ou comando, retorno para o data_sender
					begin
						counter_sender = 0;
						state_sender <= data_sender;
					end
				else //se foi enviado o valor de temp e umid, pode retornar para o estado de espera
					state_sender <= idle;
					
			end
			
	endcase

end




endmodule




