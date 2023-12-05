
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 12345
//expanation code commented below
int main() {
    int clientSock;
    if ((clientSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(SERVER_PORT);
    serverAddr.sin_addr.s_addr = inet_addr(SERVER_IP);

    char userChoice[256];

    while (1) {
        printf("Enter your choice (Rock, Paper, Scissor): ");
        scanf("%s", userChoice);

        sendto(clientSock, userChoice, strlen(userChoice), 0, (struct sockaddr *)&serverAddr, sizeof(serverAddr));

        int gameOutcome;
        recvfrom(clientSock, &gameOutcome, sizeof(gameOutcome), 0, NULL, NULL);

        if (gameOutcome == 0) {
            printf("It's a draw!\n");
        } else if (gameOutcome == 1) {
            printf("You win!\n");
        } else {
            printf("You lose!\n");
        }

        char playAgainChoice;
        printf("Play again? (y/n): ");
        scanf(" %c", &playAgainChoice);
        sendto(clientSock, &playAgainChoice, sizeof(playAgainChoice), 0, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
        recvfrom(clientSock, &gameOutcome, sizeof(gameOutcome), 0, NULL, NULL);
        if ((playAgainChoice == 'n' || playAgainChoice == 'N') || gameOutcome == 0) {
            break;
        }
    }

    close(clientSock);
    return 0;
}


/*
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 12345

//descriptive variables

int main() {
    // Create UDP socket
    int clientSocket;
    if ((clientSocket = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in serverAddress;
    memset(&serverAddress, 0, sizeof(serverAddress));
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(SERVER_PORT); // Connect to server's port initially
    serverAddress.sin_addr.s_addr = inet_addr(SERVER_IP);

    char userDecision[256];

    while (1) {
        // Get user's decision
        printf("Enter your decision (Rock, Paper, Scissor): ");
        scanf("%s", userDecision);

        // Send decision to the server
        sendto(clientSocket, userDecision, strlen(userDecision), 0, (struct sockaddr *)&serverAddress, sizeof(serverAddress));

        // Receive the game result from the server
        int gameResult;
        recvfrom(clientSocket, &gameResult, sizeof(gameResult), 0, NULL, NULL);

        // Display the result
        if (gameResult == 0) {
            printf("It's a draw!\n");
        } else if (gameResult == 1) {
            printf("You win!\n");
        } else {
            printf("You lose!\n");
        }

        // Prompt for another game
        char playAgain;
        printf("Do you want to play again? (y/n): ");
        scanf(" %c", &playAgain);
        // Send the play-again decision to the server
        sendto(clientSocket, &playAgain, sizeof(playAgain), 0, (struct sockaddr *)&serverAddress, sizeof(serverAddress));
        recvfrom(clientSocket, &gameResult, sizeof(gameResult), 0, NULL, NULL);
        if ((playAgain == 'n' || playAgain == 'N') || gameResult == 0) {
            break;
        }
    }

    close(clientSocket);
    return 0;
}
*/

