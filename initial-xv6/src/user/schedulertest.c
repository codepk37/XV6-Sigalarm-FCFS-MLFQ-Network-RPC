#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main(int argc, char *argv[])
{
  int n, pid;
  int w_time, r_time;
  int twtime = 0, trtime = 0;
  


  for (n = 0; n < NFORK; n++)
  {
    pid = fork();
    if (pid < 0)
      break;
    if (pid == 0)
    {
      if (n < IO)
      {
        sleep(200); // IO bound processes
      }
      else
      {
        for (volatile int i = 0; i < 1000000000; i++){ } // CPU bound process
      }
      
      printf("Process %d finished\n", n);//not buffer ,prints alternatly -> use flushh or fprintf() ->not available in xv6
      // char a[100]="Process   finished\n";
      // char nn=n-0+'0';
      // a[9]=nn;
      // write(1, a, 20);
      exit(0);
    }
  }
  for (; n > 0; n--)
  {
    if (waitx(0, &w_time, &r_time) >= 0)
    {
      trtime += r_time;
      twtime += w_time;
      // printf("r_time %d ,w_time %d\n",r_time,w_time);
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  exit(0);
}