#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {

  char *ip = "127.0.0.1";
  int port = 5566;

  int sock;
  struct sockaddr_in addr;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  sock = socket(AF_INET, SOCK_STREAM, 0);

  
  if (sock < 0){
    perror("ERROR opening socket");
    exit(1);
  }
  printf("TCP client socket created successfully.\n");

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port); // Use htons to set the port in network byte order
  addr.sin_addr.s_addr = inet_addr(ip);

  if(connect(sock, (struct sockaddr*)&addr, sizeof(addr))<0){
  	perror("connection failed");
  }
  printf("Connected to the server.\n");
  
  while(1){
  	bzero(buffer,1024);
  	printf("Client: ");
  	fgets(buffer,1024,stdin);
  	
  	
  		
  	n=write(sock,buffer,strlen(buffer));
  	if(n<0)
  		perror("ERROR on writing");
  		
        int i=strncmp("Bye",buffer,3);
  	if(i==0)
  		break;
        
  	bzero(buffer,1024);
  	n=read(sock,buffer,1024);
  	if(n<0)
  		perror("ERROR on reading");
  	printf("Server : %s ",buffer);
  	
  	i=strncmp("Bye",buffer,3);
  	if(i==0)
  		break;
  }
/*
  bzero(buffer, 1024);   //ORIGINAL
  strcpy(buffer, "HELLO, THIS IS CLIENT.");
  printf("Client: %s\n", buffer);
  send(sock, buffer, strlen(buffer), 0);

  bzero(buffer, 1024);
  recv(sock, buffer, sizeof(buffer), 0);
  printf("Server: %s\n", buffer);
*/
  //close(sock);
  if (close(sock) < 0) {
    perror("Error closing client socket");
  }
  printf("Disconnected from the server.\n");

  return 0;
}

