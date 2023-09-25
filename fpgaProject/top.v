module top(serial_in, clk, serial_out, dht_data);

input serial_in;     				// uart rx
input clk;								// clk 50Mhz
inout [31:0]dht_data;				// 32 sensores
output serial_out;					// uart tx

wire baud_rate;						// 9600 bps
wire microSec;

baudRateGenerator(
.clk(clk), 
.baudRate(baud_rate)
);

geradorMicrossegundo(.clk(clk), 
.microssegundo(microSec)
);

stepper(
.baudRate(baud_rate), 
.serialFromPc(serial_in), 
.serialToPc(serial_out), 
.clkMicroSec(microSec), 
.sensor(dht_data), 
.clk(clk)
);

endmodule
