#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 12345
//expanation code commented below
int main() {
    int sock;
    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    struct sockaddr_in server, clientA, clientB;
    memset(&server, 0, sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons(PORT);
    server.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr *)&server, sizeof(server)) == -1) {
        perror("Binding failed");
        exit(1);
    }

    printf("Server listening on port %d...\n", PORT);

    struct sockaddr_in addrA, addrB;
    socklen_t addrA_len = sizeof(addrA), addrB_len = sizeof(addrB);

    while (1) {
        char decisionA[256], decisionB[256];
        int recvA, recvB;

        recvA = recvfrom(sock, decisionA, sizeof(decisionA), 0, (struct sockaddr *)&addrA, &addrA_len);
        recvB = recvfrom(sock, decisionB, sizeof(decisionB), 0, (struct sockaddr *)&addrB, &addrB_len);

        int resultA, resultB;
        if (strcmp(decisionA, decisionB) == 0) {
            resultA = resultB = 0;
        } else if ((strcmp(decisionA, "Rock") == 0 && strcmp(decisionB, "Scissors") == 0) ||
                   (strcmp(decisionA, "Paper") == 0 && strcmp(decisionB, "Rock") == 0) ||
                   (strcmp(decisionA, "Scissors") == 0 && strcmp(decisionB, "Paper") == 0)) {
            resultA = 1;
            resultB = 2;
        } else {
            resultB = 1;
            resultA = 2;
        }

        sendto(sock, &resultA, sizeof(resultA), 0, (struct sockaddr *)&addrA, addrA_len);
        sendto(sock, &resultB, sizeof(resultB), 0, (struct sockaddr *)&addrB, addrB_len);

        char playAgainA, playAgainB;
        recvfrom(sock, &playAgainA, sizeof(playAgainA), 0, (struct sockaddr *)&addrA, &addrA_len);
        recvfrom(sock, &playAgainB, sizeof(playAgainB), 0, (struct sockaddr *)&addrB, &addrB_len);

        int playAgain = 1;

        if ((playAgainA == 'n' || playAgainA == 'N') || (playAgainB == 'n' || playAgainB == 'N')) {
            playAgain = 0;
        }

        sendto(sock, &playAgain, sizeof(playAgain), 0, (struct sockaddr *)&addrA, addrA_len);
        sendto(sock, &playAgain, sizeof(playAgain), 0, (struct sockaddr *)&addrB, addrB_len);

        if (!playAgain) {
            break;
        }
    }

    close(sock);
    return 0;
}



/*#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_PORT 12345



int main() {
    // Create UDP socket for handling clients
    int serverSocket;
    if ((serverSocket = socket(AF_INET, SOCK_DGRAM, 0)) == -1 ) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in serverAddress;
    memset(&serverAddress, 0, sizeof(serverAddress));
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(SERVER_PORT);
    
    serverAddress.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to server address
    if (bind(serverSocket, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) == -1) {
        perror("Binding failed");
        
        exit(1);
    }

    printf("Server listening on port %d...\n", SERVER_PORT);

    struct sockaddr_in clientAAddress, clientBAddress;
    socklen_t clientALen = sizeof(clientAAddress), clientBLen = sizeof(clientBAddress);

    while (1) {
        char decisionA[256], decisionB[256];

        // Receive decision from clientA
        int bytesReceivedA = recvfrom(serverSocket, decisionA, sizeof(decisionA), 0, (struct sockaddr *)&clientAAddress, &clientALen);
        decisionA[bytesReceivedA] = '\0';

        // Receive decision from clientB
        int bytesReceivedB = recvfrom(serverSocket, decisionB, sizeof(decisionB), 0, (struct sockaddr *)&clientBAddress, &clientBLen);
        decisionB[bytesReceivedB] = '\0';

        // Determine the result
        int resultClientA, resultClientB;
        if (strcmp(decisionA, decisionB) == 0) {
            resultClientA = 0; // Draw
            resultClientB = 0;
        } else if ((strcmp(decisionA, "Rock") == 0 && strcmp(decisionB, "Scissor") == 0) ||
                   (strcmp(decisionA, "Paper") == 0 && strcmp(decisionB, "Rock") == 0) ||
                   (strcmp(decisionA, "Scissor") == 0 && strcmp(decisionB, "Paper") == 0)) {
            resultClientA = 1;
            resultClientB = 2; // clientA wins
        } else {
            resultClientB = 1;
            resultClientA = 2; // clientB wins
        }

        // Send the result to both clients
        sendto(serverSocket, &resultClientA, sizeof(resultClientA), 0, (struct sockaddr *)&clientAAddress, clientALen);
        sendto(serverSocket, &resultClientB, sizeof(resultClientB), 0, (struct sockaddr *)&clientBAddress, clientBLen);

        // Receive play-again decision from both clients
        char playAgainClientA, playAgainClientB;
        recvfrom(serverSocket, &playAgainClientA, sizeof(playAgainClientA), 0, (struct sockaddr *)&clientAAddress, &clientALen);
        recvfrom(serverSocket, &playAgainClientB, sizeof(playAgainClientB), 0, (struct sockaddr *)&clientBAddress, &clientBLen);
        int playAgainResult = 1;
        
        

        // Determine if both clients want to play again
        if ((playAgainClientA == 'n' || playAgainClientA == 'N') || (playAgainClientB == 'n' || playAgainClientB == 'N')) {
            playAgainResult = 0;
            sendto(serverSocket, &playAgainResult, sizeof(playAgainResult), 0, (struct sockaddr *)&clientAAddress, clientALen);
            sendto(serverSocket, &playAgainResult, sizeof(playAgainResult), 0, (struct sockaddr *)&clientBAddress, clientBLen);
            break; // Exit the loop if both clients don't want to play again
        }
        
        
        
        sendto(serverSocket, &playAgainResult, sizeof(playAgainResult), 0, (struct sockaddr *)&clientAAddress, clientALen);
        sendto(serverSocket, &playAgainResult, sizeof(playAgainResult), 0, (struct sockaddr *)&clientBAddress, clientBLen);
    }

    close(serverSocket);
    return 0;
}
*/
