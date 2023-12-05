
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define PORT 12346

int main() {
    // Create TCP socket
    int client_socket;
    if ((client_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    // Connect to the server
    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Connection to server failed");
        exit(1);
    }

    char user_decision[256];

    while (1) {
        // Get user's decision
        printf("Enter your decision (Rock, Paper, Scissors): ");
        scanf("%s", user_decision);

        // Send decision to the server
        send(client_socket, user_decision, strlen(user_decision), 0);

        // Receive the game result from the server
        int game_result;
        recv(client_socket, &game_result, sizeof(game_result), 0);

        // Display the result
        if (game_result == 0) {
            printf("It's a draw!\n");
        } else if (game_result == 1) {
            printf("You win!\n");
        } else {
            printf("You lose!\n");
        }

        // Prompt for another game
        char play_again;
        printf("Do you want to play again? (y/n): ");
        scanf(" %c", &play_again);

        // Send the play-again decision to the server
        send(client_socket, &play_again, sizeof(play_again), 0);
        recv(client_socket, &game_result, sizeof(game_result), 0);
        if ((play_again == 'n' || play_again == 'N') || game_result == 0) {
            break;
        }
    }

    close(client_socket);
    return 0;
}



/*
 //Explanation code
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define PORT 12345

int main() {
    // Create TCP socket
    int client_socket;
    if ((client_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    // Connect to the server
    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Connection to server failed");
        exit(1);
    }

    char decision[256];

    while (1) {
        // Get user's decision
        printf("Enter your decision (Rock, Paper, Scissors): ");
        scanf("%s", decision);

        // Send decision to the server
        send(client_socket, decision, strlen(decision), 0);

        // Receive the game result from the server
        int result;
        recv(client_socket, &result, sizeof(result), 0);

        // Display the result
        if (result == 0) {
            printf("It's a draw!\n");
        } else if (result == 1) {
            printf("You win!\n");
        } else {
            printf("You lose!\n");
        }

        // Prompt for another game
        char play_again;
        printf("Do you want to play again? (y/n): ");
        scanf(" %c", &play_again);

        // Send the play-again decision to the server
        send(client_socket, &play_again, sizeof(play_again), 0);
        recv(client_socket, &result, sizeof(result), 0);
        if ((play_again == 'n' || play_again == 'N') || result==0) {
            break;
        }
    }

    close(client_socket);
    return 0;
}
*/
