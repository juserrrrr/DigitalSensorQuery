#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <termios.h>

int main() {
	int fd, len;
	struct termios options; //váriavel que permite a configuração de uma porta serial
    unsigned char address;
    unsigned char command;
    
    int addressInput;
    int inputError = 0;
    char commandInput[3];

    //fd é uma variável que representa um descritor de arquivo. 
    //Descritores de arquivo são inteiros que o sistema operacional usa para rastrear arquivos abertos.
	fd = open("/dev/ttyS0", O_WRONLY); //O_WRONLY é uma flag que especifica que o arquivo será aberto apenas para escrita
    //dev/ttyS0 é o caminho para uma porta serial
	if (fd < 0) { //Se fd menor que 0, deu erro na abertura
		perror("Error opening file");
		return -1;
	}
	
    //options.c_cflag = "character control"
    //options.c_oflag = "output control"
    //options.c_lflag = "line control"
	options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
    //B9600 é o Baud Rate
    //CS8 indica que cada caractere enviado ou recebido terá 8 bits
    //CLOCAL desativa a detecção de linha de controle, que só permite que a comunicação inicie se o dispositivo estiver "online" e pronto para comuunicação
    //CREAD ativa a leitura de dados da porta serial
	options.c_oflag = 0; //Configura para que a sáida seja simples sem caracteres como \t ou \r
	options.c_lflag = 0; //Configura para que a sáida seja simples sem caracteres como \n ou \b

    //tcflush é usada para descartar dados em um buffer de entrada ou saída associado a um descritor de arquivo de terminal.
    tcflush(fd, TCIFLUSH); //TCIFLUSH é usado para descartar todos os dados não lidos no buffer de entrada
	tcsetattr(fd, TCSANOW, &options); //tcsetattr seta atributos da porta serial
    //TCSANOW é uma flag que avisa para os atributos serem setados imediatamente
    //&options é um ponteiro. 
    //Nesse caso o que ele diz é: configure todos os atributos B9600, CS8, ... setados em options para a porta serial
    

    while(1){ //Loop infinito
        
        system("clear");//Limpeza do sistema

        printf("-------------------------------------------------------------------------\n");
        printf("Painel de Controle DHT11");
        printf("\n-------------------------------------------------------------------------\n");

        if (inputError){ //Se inputError for 1
            printf("Comando Invalido\n");
        } else {
            printf("\nUltimo Endereco Enviado: 0x%02hhX\n", address); //printa o último endereço em hexadecimal
            write(fd, &address, 1); //Escreve o valor que está em address na porta serial, sendo que deve ser apenas 1 Byte
			
			sleep(0.1); //Aguarda 0.1 segundos
			
            printf("\nUltimo Comando Enviado: 0x%02hhX\n", command); //printa o último comando em hexadecimal
            write(fd, &command, 1); //Escreve o valor que está em command na porta serial, sendo que deve ser apenas 1 Byte
        }

        printf("\n-------------------------------------------------------------------------");
        printf("\n\nDigite o comando no seguinte formato: [Numero do sensor(0 a 31)] [Comando]\nExemplo: 28 TT\n\nTabela de comandos:"
        "\nTT -> Temperatura\nUU -> Umidade\nSS -> Situacao Atual Do Sensor\nTC -> Temperatura Continua\n"
        "UC -> Umidade Continua\nDT -> Desativar Temperatura Continua\nDU -> Desativar Umidade Continua\n");

        scanf("%d %2s", &addressInput, commandInput); //Entrada do usuário do endereço e comando

        inputError = 0;
        //strcmp retorna 0 se duas Strings forem iguais, então por isso precisa negá-la
        //Faz a identificação de qual comando de requisição foi selecionado pelo usuário
        if (!strcmp(commandInput, "TT")){  
            command = 0x01;
        } else if(!strcmp(commandInput, "UU")){
            command = 0x02;
        } else if(!strcmp(commandInput, "SS")){
            command = 0x00;
        } else if(!strcmp(commandInput, "TC")){
            command = 0x03;
        } else if(!strcmp(commandInput, "UC")){
            command = 0x04;
        } else if(!strcmp(commandInput, "DT")){
            command = 0x05;
        } else if(!strcmp(commandInput, "DU")){
            command = 0x06;
        } else { //Se não foi nenhum comando esperado...
            inputError = 1;
        }
        

        if (addressInput < 0 || addressInput > 31){ //Se foi digitado um endereço de sensor inválido...
            inputError = 1;
        } else { //Senão, pega endereço digitado e armazena no adress
            address = addressInput;
        }


    }
    

	close(fd);

	return 0;
}