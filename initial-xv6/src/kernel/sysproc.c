#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
//#include "part1.h"


int readcount=0;

uint64
sys_getreadcount(void){ //////////////////
	return readcount;  ///////////
}

//////////
uint64 
sys_sigalarm(void)
{
  int ticks;
  uint64 handleraddrs;
  if(argint(0, &ticks) < 0)  //read arg0 
    return -1;
  if(argaddr(1, &handleraddrs) < 0) //read arg1
    return -1;

  myproc()->ticks = ticks;  //here 2 , becomes 0 sigalarm(0,--)
     // myproc()->alarm_on = 1;
  myproc()->handler = handleraddrs;  //func periodic ka address
  //myproc()->a1 = myproc()->trapframe->a0;
  //myproc()->a2 = myproc()->trapframe->a1;

  return 0;
}


uint64 
sys_sigreturn(void)
{
  struct proc *p = myproc();
  memmove(p->trapframe, p->alarm_tf, PGSIZE);//give state of main before returning
  //myproc()->trapframe->a0 = myproc()->a1;
  //myproc()->trapframe->a1 = myproc()->a2;
  kfree(p->alarm_tf);
  p->handler_permission = 1;//1
  //trapp always happens cur % tick but //making handler_permission=1,gives opprtunity to call periodic
  // if handler_permission =0 always , periodic isnt called
  // printf("perm_1");
  return myproc()->trapframe->a0;//previously executing thread
}

////////////////////



uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
extern int readcount;

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}



int 
sys_getyear(void){
	return 1975;
}













