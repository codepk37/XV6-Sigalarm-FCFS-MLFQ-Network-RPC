#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    char *ip = "127.0.0.1";
    int port = 5566;

    int server_sock;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    server_sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_sock < 0) {
        perror("ERROR opening Socket");
        exit(1);
    }
    printf("UDP server socket created.\n");

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    if (bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Binding failed");
        close(server_sock);
        exit(1);
    }
    printf("Bind to the port number: %d\n", port);

    printf("Listening...\n");

    while (1) {
        addr_size = sizeof(client_addr);
        n = recvfrom(server_sock, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr, &addr_size);
        if (n < 0) {
            perror("Error on receiving");
            continue; // Continue listening for other messages
        }

        printf("Client: %s\n", buffer);

        // Respond to the client
        printf("Server: ");
        bzero(buffer, sizeof(buffer));
        fgets(buffer, sizeof(buffer), stdin);
        n = sendto(server_sock, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addr, addr_size);
        if (n < 0) {
            perror("Error on sending");
            continue; // Continue listening for other messages
        }
        int i = strncmp("Bye", buffer, 3);
        if (i == 0)
            break;
    }

    // Close the server socket (this code is unreachable in this loop)
    close(server_sock);
    printf("Server closed.\n");

    return 0;
}

