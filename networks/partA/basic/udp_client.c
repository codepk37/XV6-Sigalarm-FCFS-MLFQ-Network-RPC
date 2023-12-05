#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    char *ip = "127.0.0.1";
    int port = 5566;

    int sock;
    struct sockaddr_in server_addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    sock = socket(AF_INET, SOCK_DGRAM, 0);

    if (sock < 0) {
        perror("ERROR opening socket");
        exit(1);
    }
    printf("UDP client socket created successfully.\n");

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    while (1) {
        printf("Client: ");
        bzero(buffer, sizeof(buffer));
        fgets(buffer, sizeof(buffer), stdin);
        n = sendto(sock, buffer, strlen(buffer), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (n < 0) {
            perror("Error on sending");
            continue; // Continue sending other messages
        }

        addr_size = sizeof(server_addr);
        n = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)&server_addr, &addr_size);
        if (n < 0) {
            perror("Error on receiving");
            continue; // Continue receiving other messages
        }

        printf("Server: %s", buffer);

        int i = strncmp("Bye", buffer, 3);
        if (i == 0)
            break;
    }

    // Close the client socket
    close(sock);
    printf("Client closed.\n");

    return 0;
}

