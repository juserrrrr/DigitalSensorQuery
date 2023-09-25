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




