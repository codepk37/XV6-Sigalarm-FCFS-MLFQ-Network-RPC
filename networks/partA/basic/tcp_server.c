
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    char *ip = "127.0.0.1";
    int port = 5566;

    int server_sock, client_sock;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0) {
        perror("ERROR opening Socket");
        exit(1);
    }
    printf("TCP server socket created.\n");

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    int reuse = 1;
	if (setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) < 0) {
	    perror("setsockopt(SO_REUSEADDR) failed");
	    exit(1);
	}

    
    if (bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Binding failed");
        exit(1);
    }
    printf("Bind to the port number: %d\n", port);

    listen(server_sock, 5); // Max limit of client connections
    printf("Listening...\n");
    int stop=0;
    while (1 && stop==0) {  ////use for multiple clients
        addr_size = sizeof(client_addr);
        client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
        if (client_sock < 0) {
            perror("ERROR on accept");
            continue; // Continue listening for other clients
        }

        while (1) {
            bzero(buffer, 1024);
            n = read(client_sock, buffer, 1024);
            if (n < 0)
                perror("Error on reading");
                
            int i = strncmp("Bye", buffer, 3);
            if (i == 0) {
                printf("Received 'Bye' from client. Closing the connection.\n");
                stop=1; // for single client
                break; // Exit the inner loop if 'Bye' is received
                
            }

            printf("Client: %s\n", buffer);

            // Read input from the server's console
            printf("Server: ");
            bzero(buffer, 1024);
            fgets(buffer, 1024, stdin);

            // Send the server's input back to the client
            n = write(client_sock, buffer, strlen(buffer));
            if (n < 0)
                perror("Error on writing");

            
        }
        
        // Close the client socket after the client decides to terminate the connection
        close(client_sock);
    }

    // Close the server socket (this code is unreachable in this loop)
    //close(server_sock);
    if (close(server_sock) < 0) {
	    perror("Error closing server socket");
   }

    printf("Server closed.\n");

    return 0;
}



