#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <math.h>
#include <termios.h>

void clrscr()
{
    system("clear");
}


// converte um número binário em forma de uma string de 1s e 0s
// em um inteiro
// o char[0] deve ser o bit menos significativo;
int binToInt(char binary[]){
    int converted = 0;

    for(int i = 0; i<8; i++){
        converted = converted + (binary[i] * (pow(2, i)));
    }

    return converted; //retorna o número inteiro que corresponde ao binário
}

void printAllSensors(int temperatures[33], int humidities[33]){
    char temp[3];
    char hum[3];
    char celsius[3];
    char percen[3];
    
    printf("\nSituacao atual dos sensores:\n");
    printf("\n----------------   ----------------   ----------------   ----------------\n");
    for(int i = 0; i< 32; i++){
        
        if (temperatures[i] == -1){
            strcpy(temp, ""); //copia o caractere vazio para temp
            strcpy(celsius, ""); //copia o caractere vazio para celsius
        } else {
            sprintf(temp, "%d", temperatures[i]); //armazena a temperatura em um buffer
            strcpy(celsius, "C"); //copia o caractere C vazio para celsius
        }

        if (humidities[i] == -1){
            strcpy(hum, ""); //copia o caractere vazio para hum
            strcpy(percen, ""); //copia o caractere vazio para percen
        } else {
            sprintf(hum, "%d", humidities[i]); //armazena a umidade em um buffer
            strcpy(percen, "%"); //copia o caractere % vazio para percen
        }

        printf("|%2d|T:%2s%1s H:%2s%1s|", i, temp, celsius, hum, percen); //Printa as informações do sensor
        

        if((i+1) % 4 == 0){
            if((i+1) != 32){
                printf("\n|--|-----------|   |--|-----------|   |--|-----------|   |--|-----------|\n");
            } else {
                printf("\n----------------   ----------------   ----------------   ----------------\n");
            }
            
        } else{
            printf("   ");
        }
    }
    
}


void printAndRunCurrentCommand(int intAddress, int intCommand, int measuredValue,
int liveTemperature[33], int liveHumidity[33], int temperatures[33], int humidities[33], 
char rawCommand, char rawAddress, char rawValue, int *isSecond, char lastStatus[], char * lastAddress, char * lastCommand){

    //Analisa o comando de retorno
	switch (intCommand) {

        // Sensor com problema 0x1F
        case(31):
         //Armazena a string de sensor com problema e seu endereço em um buffer de no máximo 150 chars
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensor Com Problema", intAddress);

            liveHumidity[intAddress] = 0; //Umidade Contínua desativada
            humidities[intAddress] = -1; //Umidade desligada

            liveTemperature[intAddress] = 0; //Temperatura Contínua desativada
            temperatures[intAddress] = -1; //Temperatura desligada

            (*isSecond) = 1; //significa que foi mandado um comando
            (*lastAddress) = rawAddress;
            *lastCommand = rawCommand;
			break;

        // Funcionando normalmente 0x07
		case(7):
		//Armazena a string de sensor funcionando normalmente e seu endereço em um buffer de no máximo 150 chars
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensor Funcionando Normalmente", intAddress);

            (*isSecond) = 1; //significa que foi mandado um comando
            *lastAddress = rawAddress;
            *lastCommand = rawCommand;
			break;

        // Medida de humidade 0x08
        case(8):     
            if (liveHumidity[intAddress] == 0){ //Se não for umidade contínua
            //Armazena a string do endereço do sensor e sua umidade em um buffer de no máximo 150 chars
                snprintf(lastStatus, 150, "\nSensor %2d:\n Umidade: %d%%", intAddress, measuredValue);

                (*isSecond) = 1; //significa que foi mandado um comando
                *lastAddress = rawAddress;
                *lastCommand = rawCommand;
            } else { //Se for umidade contínua
                humidities[intAddress] = measuredValue;
            }

			break;

        // Medida de temperatura 0x09
        case(9):
            
            if (liveTemperature[intAddress] == 0){ // Se a temperatura não for contínua
            //Armazena a string do endereço do sensor e sua temperatura em um buffer de no máximo 150 chars
                snprintf(lastStatus, 150, "\nSensor %2d:\n Temperatura: %dC", intAddress, measuredValue);

                (*isSecond) = 1; //significa que foi mandado um comando
                *lastAddress = rawAddress;
                *lastCommand = rawCommand;
            } else { //Se a temperatura for contínua
                temperatures[intAddress] = measuredValue;
            }
		    break;


        // Confirmação de desativação sensoriamento contínuo temperatura 0x0A(10) -- 1A(26)
        case(26):
        //Armazena em um buffer de no máximo 150 chars a string do endereço do sensor em que temperatura continua foi desativada 
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensoriamento Continuo de Temperatura Desativado", intAddress);

            liveTemperature[intAddress] = 0; //Temperatura continua desativada
            temperatures[intAddress] = -1; //Temperatura desativada

			(*isSecond) = 1; //significa que foi mandado um comando
            *lastAddress = rawAddress;
            *lastCommand = rawCommand;
			break;

        // Confirmação de desativação sensoriamento contínuo umidade 0x0B
        case(11):
        //Armazena em um buffer de no máximo 150 chars a string do endereço do sensor em que umidade continua foi desativada 
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensoriamento Continuo de Umidade Desativado", intAddress);

            liveHumidity[intAddress] = 0; //Umidade continua desativada
            humidities[intAddress] = -1; //Umidade desativada

			(*isSecond) = 1; //significa que foi mandado um comando
            *lastAddress = rawAddress;
            *lastCommand = rawCommand;
			break;

        // Confirmação de ativação sensoriamento contínuo temperatura 0x0C
        case(12):
        //Armazena em um buffer de no máximo 150 chars a string do endereço do sensor em que temperatura continua foi ativada 
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensoriamento Continuo de Temperatura Ativado", intAddress);

            liveTemperature[intAddress] = 1; //temperatura continua ativada

			(*isSecond) = 1; //significa que foi mandado um comando
            *lastAddress = rawAddress;
            *lastCommand = rawCommand;
			break;

        // Confirmação ativação sensoriamento contínuo umidade 0x0D(13) -- 0F(15)
        case(15):
        //Armazena em um buffer de no máximo 150 chars a string do endereço do sensor em que umidade continua foi ativada 
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensoriamento Continuo de Umidade Ativado", intAddress);

            liveHumidity[intAddress] = 1; //umidade continua ativada

			(*isSecond) = 1; //significa que foi mandado um comando
            *lastAddress = rawAddress;
            *lastCommand = rawCommand;
			break;
        
        /*
        // Sensor não conectado 0x0E
        case(14):
            snprintf(lastStatus, 150, "\nSensor %2d:\n Sensor Não Conectado", intAddress);

            liveHumidity[intAddress] = 0;
            humidities[intAddress] = -1;

            liveTemperature[intAddress] = 0;
            temperatures[intAddress] = -1;

            (*isSecond) = 1;
            (*lastAddress) = rawAddress;
            *lastCommand = rawCommand;
			break;
			*/
	}

    if ((*isSecond)){ //Se for 1, significa que teve comando recebido
        printf("\nUltima requisicao:\n");
        //Printa o último status
        printf("%s\n", lastStatus);
    } else {
        printf("\nNenhum comando recebido ate agora.\n");
    }

}

// transforma um char em uma string de 8chars, cada um representando um bit
void hexToBinString(char c, char binary[]){
    // a operação c >> i move os bits do char c "i" casas para a direita
    // se o valor for "00010010", após um c >> 1, o valor é "00001001"
    // o operador "&" checa o último bit do resultado da operação
    // fazendo isso pra todos os 8 bits, conseguimos o valor completo do byte em um array
    // onde cada índice representa um bit
    for(int i = 0; i<8; i++){
        binary[i] = (char) ((c >> i) & 1); //indice 0 é o menos significativo
    }
}

// Separa cada byte enviado em seus respectivos chars
// O formato dos bits, do menos significativo para o mais significativo:
// rawBinAddress -> 6 primeiros bits p/ o endereço, 2 últimos para os 2 primeiros da medida
// rawBinCommand -> 4 primeiros bits p/ o comando, 4 últimos para os 4 últimos da medida
// como só sobram 6 bits para o valor da medida, e a umidade pode ir de 20-90 (7bits)
// a solução escolhida foi dividir as 70 medidas de umidade possíveis em 2;
// sendo assim, cada valor recebido pela medida de umidade deve ser multiplicado por 2
// e somado ao 20 inicial
void proccessRawAddressCommand(char rawBinAddress[9], char rawBinCommand[9], //FUNCAO AINDA NAO UTILIZADA
    char address[9], char command[9], char measuredValue[9]){
    
    address[0] = rawBinAddress[0];
    address[1] = rawBinAddress[1];
    address[2] = rawBinAddress[2];
    address[3] = rawBinAddress[3];
    address[4] = rawBinAddress[4];


    command[0] = rawBinCommand[0];
    command[1] = rawBinCommand[1];
    command[2] = rawBinCommand[2];
    command[3] = rawBinCommand[3];

    measuredValue[0] = rawBinAddress[5];
    measuredValue[1] = rawBinAddress[6];
    measuredValue[2] = rawBinAddress[7];
    measuredValue[3] = rawBinCommand[4];
    measuredValue[4] = rawBinCommand[5];
    measuredValue[5] = rawBinCommand[6];
    measuredValue[6] = rawBinCommand[7];
}


int main(){
    int fd;
    int rc;
	struct termios options = {0}; //váriavel que permite a configuração de uma porta serial
	//fd é uma variável que representa um descritor de arquivo. 
    //Descritores de arquivo são inteiros que o sistema operacional usa para rastrear arquivos abertos.
    fd = open("/dev/ttyS0", O_RDONLY | O_NOCTTY); //O_RONLY é uma flag que especifica que o arquivo será lido apenas para escrita
    
     //dev/ttyS0 é o caminho para uma porta serial
    if (fd < 0) { //erro na leitura
        perror("Error opening file");
        return -1;
    }
    
    /*
    speed_t spd = B9600;
    cfsetospeed(&options, (speed_t)spd);
    cfsetispeed(&options, (speed_t)spd);

    //cfmakeraw(&options);

    options.c_cc[VMIN] = 1;
    options.c_cc[VTIME] = 10;

    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CRTSCTS;    /* no HW flow control? 
    options.c_cflag |= CLOCAL | CREAD;
    tcsetattr(fd, TCSANOW, &options); */

    
    //options.c_cc[VMIN] = 1;
	//options.c_cc[VTIME] = 5;
    //options.c_cflag = "character control"
    //options.c_oflag = "output control"
    //options.c_lflag = "line control"
    options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
    options.c_cflag &= ~CRTSCTS;
    //options.c_cflag &= ~CRTSCTS;
    //B9600 é o Baud Rate
    //CS8 indica que cada caractere enviado ou recebido terá 8 bits
    //CLOCAL desativa a detecção de linha de controle, que só permite que a comunicação inicie se o dispositivo estiver "online" e pronto para comuunicação
    //CREAD ativa a leitura de dados da porta serial
    //cfmakeraw(&options);
	options.c_oflag = 0; //Configura para que a sáida seja simples sem caracteres como \t ou \r
	options.c_lflag = 0; //Configura para que a sáida seja simples sem caracteres como \n ou \b
	
    tcflush(fd, TCIFLUSH); //TCIFLUSH é usado para descartar todos os dados não lidos no buffer de entrada
	tcsetattr(fd, TCSANOW, &options); //tcsetattr seta atributos da porta serial

	
    unsigned char rawAddress;
    unsigned char rawCommand;
    unsigned char rawValue;

    // endereço e comando que vêm direto da uart
    char rawBinaryAddress[] = "00000000";
    char rawBinaryCommand[] = "00000000";
    char rawBinaryValue[] = "00000000";
    
    //endereço, comando e valor após tratamento (separação) dos bits
    char address[] = "00000000";
    char command[] = "00000000";
    char measuredValue[] = "00000000";
    
    
	// valores booleanos que indicam se o índice(sensor) está em monitoramento contínuo ou não	
    int liveTemperature[33]; 
    int liveHumidity[33];

    // cada índice desses arrays representa um sensor, 1=um, 2=dois, assim por diante
    // sao as temperaturas que serão printadas no monitoramento contínuo
    int temperatures[33]; 
    int humidities[33];

    int isSecond = 0; // Verifica se ja recebeu alguma informacao antes, para atualizar os prints de acordo

    char lastStatus[150] = ""; // Ultimo status recebido, sera printado continuamente
    char lastCommand; // Ultimo comando recebido
    char lastAddress; // Ultimo endereco recebido
	
	//tamanho de cada Byte lido
	int len1 = 0;
	int len2 = 0; 
	int len3 = 0;
	
	//Inicializa as temperaturas e umidades em -1 (desativadas) além de temperatura e umidade continua em 0 (desativadas)
    for(int i = 0; i< 33; i++){
        temperatures[i] = -1;
        humidities[i] = -1;
        
        liveTemperature[i] = 0;
        liveHumidity[i] = 0;
    }
    
    //Loop infinito
    while(1){
    	clrscr();//Limpeza do terminal
		
		//Leitura dos 3 Bytes
        len1 = read(fd, &rawAddress, 1);
        //sleep(0.1);
        len2 = read(fd, &rawCommand, 1);
        //sleep(0.1);
        len3 = read(fd, &rawValue, 1);

        if (len1+len2+len3 < 3){
            rawAddress = 0x00;
            rawCommand = 0x00;
            rawValue = 0x00;
        }
			
        printAllSensors(temperatures, humidities);
        
        printAndRunCurrentCommand(binToInt(rawBinaryAddress), binToInt(rawBinaryCommand), binToInt(rawBinaryValue), 
        liveTemperature, liveHumidity, temperatures, humidities, rawAddress, rawCommand, rawValue, &isSecond, lastStatus,
        &lastAddress, &lastCommand);

		printf("\n---------------------------INFORMACOES PARA MONITORAMENTO---------------------------\n");

        printf("\nRead %d bytes\n", len1+len2+len3);

        printf("\nHex Address: 0x%02hhX\n", rawAddress);
        printf("Hex Command: 0x%02hhX\n", rawCommand);
        printf("Hex Value: 0x%02hhX\n", rawValue);

        //converte os valores lidos em hexadecimal para binário
        hexToBinString(rawAddress, rawBinaryAddress);
        hexToBinString(rawCommand, rawBinaryCommand);
        hexToBinString(rawValue, rawBinaryValue);

        
        //proccessRawAddressCommand(rawBinaryAddress, rawBinaryCommand, address, command, measuredValue);
	
	/*
        if (binToInt(command) != 8 && binToInt(command) != 9){
            strcpy(address, rawBinaryAddress);
            strcpy(command, rawBinaryCommand);
        } */

        
        //Printa os valores inteiros de endereço, comando e valor
        printf("\nInt Address: %d\n", binToInt(rawBinaryAddress));
        printf("Int Command: %d\n", binToInt(rawBinaryCommand));
        printf("Int Value: %d\n", binToInt(rawBinaryValue)); 
		
		//Printa os valores binários de endereço, comando e valor
       	printf("\nBin address: ");
        for (int i = 0; i<8; i++){
        	printf("%d", rawBinaryAddress[i]);
        }
        printf("\n");
        

		printf("\nBin command: ");
        for (int i = 0; i<8; i++){
        	printf("%d", rawBinaryCommand[i]);
        }
        printf("\n");
        
        
        printf("\nBin value: ");
        for (int i = 0; i<8; i++){
        	printf("%d", rawBinaryValue[i]);
        }
        printf("\n");
        
        sleep(1.7); //a mimir por 1 segundo
    }
    
    close(fd); //fecha o descritor de arquivo

    return 0;
}
