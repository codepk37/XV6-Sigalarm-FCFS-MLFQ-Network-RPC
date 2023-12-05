
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 12346

int main() {
    // Create TCP socket
    int server_socket;
    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to server address
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Binding failed");
        exit(1);
    }

    // Listen for incoming connections
    if (listen(server_socket, 2) == -1) {
        perror("Listening failed");
        exit(1);
    }

    printf("Server listening on port %d...\n", PORT);

    struct sockaddr_in clientX_addr, clientY_addr;
    socklen_t clientX_len = sizeof(clientX_addr), clientY_len = sizeof(clientY_addr);

    while (1) {
        // Accept connections from clientX and clientY
        int clientX_socket, clientY_socket;
        clientX_socket = accept(server_socket, (struct sockaddr *)&clientX_addr, &clientX_len);
        clientY_socket = accept(server_socket, (struct sockaddr *)&clientY_addr, &clientY_len);

        char decisionX[256], decisionY[256];

        // Receive decision from clientX
        int bytes_received_X = recv(clientX_socket, decisionX, sizeof(decisionX), 0);
        decisionX[bytes_received_X] = '\0';

        // Receive decision from clientY
        int bytes_received_Y = recv(clientY_socket, decisionY, sizeof(decisionY), 0);
        decisionY[bytes_received_Y] = '\0';

        // Determine the result
        int resultX, resultY;
        if (strcmp(decisionX, decisionY) == 0) {
            resultX = 0; // Draw
            resultY = 0;
        } else if ((strcmp(decisionX, "Rock") == 0 && strcmp(decisionY, "Scissors") == 0) ||
                   (strcmp(decisionX, "Paper") == 0 && strcmp(decisionY, "Rock") == 0) ||
                   (strcmp(decisionX, "Scissors") == 0 && strcmp(decisionY, "Paper") == 0)) {
            resultX = 1;
            resultY = 2; // clientX wins
        } else {
            resultY = 1;
            resultX = 2; // clientY wins
        }

        // Send the result to both clients
        send(clientX_socket, &resultX, sizeof(resultX), 0);
        send(clientY_socket, &resultY, sizeof(resultY), 0);

        // Receive play-again decision from both clients
        char play_again_X, play_again_Y;
        recv(clientX_socket, &play_again_X, sizeof(play_again_X), 0);
        recv(clientY_socket, &play_again_Y, sizeof(play_again_Y), 0);
        int result = 1;

        // Determine if both clients want to play again
        if ((play_again_X == 'n' || play_again_X == 'N') || (play_again_Y == 'n' || play_again_Y == 'N')) {
            result = 0;
            send(clientX_socket, &result, sizeof(result), 0);
            send(clientY_socket, &result, sizeof(result), 0);
        } else {
            send(clientX_socket, &result, sizeof(result), 0);
            send(clientY_socket, &result, sizeof(result), 0);
        }

        // Close the client sockets
        close(clientX_socket);
        close(clientY_socket);
    }

    close(server_socket);
    return 0;
}



/*
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 12346

int main() {
    // Create TCP socket
    int server_socket;
    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to server address
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Binding failed");
        exit(1);
    }

    // Listen for incoming connections
    if (listen(server_socket, 2) == -1) {
        perror("Listening failed");
        exit(1);
    }

    printf("Server listening on port %d...\n", PORT);

    struct sockaddr_in clientA_addr, clientB_addr;
    socklen_t clientA_len = sizeof(clientA_addr), clientB_len = sizeof(clientB_addr);

    while (1) {
        // Accept connections from clientA and clientB
        int clientA_socket, clientB_socket;
        clientA_socket = accept(server_socket, (struct sockaddr *)&clientA_addr, &clientA_len);
        clientB_socket = accept(server_socket, (struct sockaddr *)&clientB_addr, &clientB_len);

        char decisionA[256], decisionB[256];

        // Receive decision from clientA
        int bytes_received_A = recv(clientA_socket, decisionA, sizeof(decisionA), 0);
        decisionA[bytes_received_A] = '\0';

        // Receive decision from clientB
        int bytes_received_B = recv(clientB_socket, decisionB, sizeof(decisionB), 0);
        decisionB[bytes_received_B] = '\0';

        // Determine the result
        int result1, result2;
        if (strcmp(decisionA, decisionB) == 0) {
            result1 = 0; // Draw
            result2 = 0;
        } else if ((strcmp(decisionA, "Rock") == 0 && strcmp(decisionB, "Scissors") == 0) ||
                   (strcmp(decisionA, "Paper") == 0 && strcmp(decisionB, "Rock") == 0) ||
                   (strcmp(decisionA, "Scissors") == 0 && strcmp(decisionB, "Paper") == 0)) {
            result1 = 1;
            result2 = 2; // clientA wins
        } else {
            result2 = 1;
            result1 = 2; // clientB wins
        }

        // Send the result to both clients
        send(clientA_socket, &result1, sizeof(result1), 0);
        send(clientB_socket, &result2, sizeof(result2), 0);

        // Receive play-again decision from both clients
        char play_again_A, play_again_B;
        recv(clientA_socket, &play_again_A, sizeof(play_again_A), 0);
        recv(clientB_socket, &play_again_B, sizeof(play_again_B), 0);
        int result = 1;

        // Determine if both clients want to play again
        if ((play_again_A == 'n' || play_again_A == 'N') || (play_again_B == 'n' || play_again_B == 'N')) {
            result = 0;
            send(clientA_socket, &result, sizeof(result), 0);
            send(clientB_socket, &result, sizeof(result), 0);
        } else {
            send(clientA_socket, &result, sizeof(result), 0);
            send(clientB_socket, &result, sizeof(result), 0);
        }

        // Close the client sockets
        close(clientA_socket);
        close(clientB_socket);
    }

    close(server_socket);
    return 0;
}
*/

