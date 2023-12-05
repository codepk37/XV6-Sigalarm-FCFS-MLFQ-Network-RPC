#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

int sahil=0;
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

int queueprocesscount[5] = {0, 0, 0, 0, 0};
int queuemaxindex[5] = {0, 0, 0, 0, 0};



/////////////############3
#define MAX_SIZE 65
#define NUM_QUEUES 4

struct CircularQueue {
    struct proc * items[MAX_SIZE];
    // int front;
    // int rear;
};

struct MultiCircularQueue {
    struct CircularQueue queues[NUM_QUEUES];
};

void initializeCircularQueue(struct CircularQueue *queue) {
    // queue->front = -1;
    // queue->rear = -1;
    for (int i = 0; i < MAX_SIZE; i++) {
        queue->items[i] = 0;
    }
}

int isCircularQueueEmpty(struct MultiCircularQueue *multiQueue,int n) {
    struct CircularQueue *queue=&multiQueue->queues[n];
    int tot=0;
    for(int i=0;i<MAX_SIZE;i++){
        if(queue->items[i]!=0){//exist
            tot++;
        }
    }
    return (tot==0); //1 empty
}

int isCircularQueueFull(struct CircularQueue *queue) {
    int tot=0;
    for(int i=0;i<MAX_SIZE;i++){
        if(queue->items[i]!=0){//exist
            tot++;
        }
    }
    
    return (tot==MAX_SIZE); //1 full
    
}

void enqueueToCircularQueue(struct CircularQueue *queue, struct proc * value) {
    if (isCircularQueueFull(queue)) {
        printf("Queue is full. Cannot enqueue.\n");
        return;
    }
    
    for(int i=0;i<MAX_SIZE;i++){
        if(queue->items[i]==0){
            //found empty place
            queue->items[i]=value;
            break;
        }
    }
    // printf("%dproc pid enqueued to queue%d , at ticks %d\n",value->pid,ticks);
    
    
    
}

void initializeMultiCircularQueue(struct MultiCircularQueue *multiQueue) {
    for (int i = 0; i < NUM_QUEUES; i++) {
        initializeCircularQueue(&multiQueue->queues[i]);
    }
}

void enqueueToMultiCircularQueue(struct MultiCircularQueue *multiQueue, int queueNumber, struct proc * value) {
    if (queueNumber >= 0 && queueNumber < NUM_QUEUES) {
        enqueueToCircularQueue(&multiQueue->queues[queueNumber], value);
        // printf("%d %d %d\n",value->pid,queueNumber,ticks);//pid  make graph
    } else {
        printf("Invalid queue number.\n");
    }
}
void display(struct MultiCircularQueue *multiQueue){
    for (int i = 0; i < NUM_QUEUES; i++) {
        if (1||!isCircularQueueEmpty(multiQueue, i)) {
            
            struct CircularQueue *queue=&multiQueue->queues[i];
            
            for (int pos = 0; pos < MAX_SIZE; pos++) {
                printf("%d ",queue->items[pos]);
            }
            printf("\n");

        }
    }
}
void dequeueFromMultiCircularQueue(struct MultiCircularQueue *multiQueue, struct proc * value) {
    for (int i = 0; i < NUM_QUEUES; i++) {
        if (!isCircularQueueEmpty(multiQueue, i)) {
            
            struct CircularQueue *queue=&multiQueue->queues[i];
            
            for (int pos = 0; pos < MAX_SIZE; pos++) {
                if(queue->items[pos]==value){
                    // printf("bef %d\n",queue->items[pos]);
                    *&queue->items[pos] = 0;
                     // printf("afte %d\n",queue->items[pos]);
                  // printf("%d %d\n",value->pid,ticks); //make graph
                  // display(multiQueue);
                    return;
                }   
                
            }
            

        }
    }
    // printf("No element found in any queue. Cannot dequeue.\n");
    
}

// int allpid[100];   //pid array mlfq  declared before allocproc:
struct MultiCircularQueue multiQueue; //struct mlfq



// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.

int allpid[100];   //pid array mlfq ,sets allpid[pid]=1 ,in allocproc

static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  p->rtime = 0;
  p->r_time = 0;
  p->etime = 0;
  p->ctime = ticks;
  
  // p->alarm_on = 0;    of no use      
  p->cur_ticks = 0;         //  sigalarm
  p->handler_permission = 1;//  sigalarm

  p->p_arrival_time=ticks;


  //mlfq
  p->queuenumber=0; //initially at 0 queue
  p->rtime=0; //gets updated in clockintr() ,for all process
  p->r_time=0; 
  p->wtime=0;
  p->w_time=0;


  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  // allpid[p->pid]=1;           //mlfq 
  // enqueueToMultiCircularQueue(&multiQueue,0, p);
  sahil=1 ; //interrupt new process

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}


void pf(struct proc *p){
  allpid[p->pid]=0;
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
  printf(" %d- %d-\n",p->state,p->pid);
}
////////////////###########


// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);
  // *(&allpid[p->pid])=0;  ////
  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;
  // pf(p);   ////////      ///// dequeue exit
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
  allpid[p->pid]=0;
  // release(&p->lock);//-------chatgpt
  release(&wait_lock);
  allpid[p->pid]=0;
  dequeueFromMultiCircularQueue(&multiQueue, p); //remove proc from queue
  
  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.

int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}


//changes/////////////////
//changes/////////////////
//changes/////////////////
//changes/////////////////
//changes/////////////////
//changes/////////////////

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.


//////######



// int main() {
//     struct MultiCircularQueue multiQueue;
//     initializeMultiCircularQueue(&multiQueue);

//     enqueueToMultiCircularQueue(&multiQueue,0, 10);
//     enqueueToMultiCircularQueue(&multiQueue,1, 20);
//     enqueueToMultiCircularQueue(&multiQueue,2, 30);
//     enqueueToMultiCircularQueue(&multiQueue,3, 40);

//     int dequeuedValue=30;
//     dequeueFromMultiCircularQueue(&multiQueue, dequeuedValue);
//     // printf("Dequeued value: %d\n", dequeuedValue);
    
//     display(&multiQueue);
    
//     enqueueToMultiCircularQueue(&multiQueue,1, 60);
//     enqueueToMultiCircularQueue(&multiQueue,1, 70);
//     enqueueToMultiCircularQueue(&multiQueue,1, 70);
    
//     display(&multiQueue);
    
//     dequeueFromMultiCircularQueue(&multiQueue, 60);
//     display(&multiQueue);
//     enqueueToMultiCircularQueue(&multiQueue,1, 100);
//     display(&multiQueue);
    
//     return 0;
// }


//////######

void initpid(){
  for(int i=0;i<100;i=i+1){allpid[i]=0;}
}


void scheduler(void)
{
  //added CFLAG: ,in makefile so it runs 'make clean', "make qemu SCHEDULER=RR "

  // struct proc *p=0;
  // struct cpu *c = mycpu();
  // c->proc = 0;

  #ifdef MLFQ
  initpid();
  int aging=0;int agetime=100; //100 ticks
   //defined above globaly// 
   //struct MultiCircularQueue multiQueue; //user defined multiqueue 
    struct proc *p;
    printf("MLFQ\n");
    struct cpu *c = mycpu();
    c->proc = 0;

    int maxtick[4]={1,3,9,15};
    for (;;)
    {  
      intr_on();
      for (p = proc; p < &proc[NPROC]; p++){
         
         acquire(&p->lock);
        if (p->state == RUNNABLE &&allpid[p->pid]==0)
        {
            allpid[p->pid]=1;
            enqueueToMultiCircularQueue(&multiQueue,0, p);

        }
        release(&p->lock);  //got all runnable right now ,including new swapns



        //  DONE:called pf(proc*) to remove exit() if exited process, pid[pos]=0; above
      }
      if(isCircularQueueEmpty(&multiQueue,0)!=1){
          // stay in queue 0
          //RR
        
          struct CircularQueue *queue= &multiQueue.queues[0];//0th queue
          for (int pos=0; pos<MAX_SIZE; pos++) ////
          { 

            if(sahil==1){
              printf("--\n");
              sahil=0;
              break;  //goto top after 1 tick ,unexplored new process arrived
            }
            if(ticks% agetime==0){ // %100
               aging=1;
               break; //go down anti-aging
            }

            p=queue->items[pos]; //proc *p
            
            if(p==0){continue;} //no process at pos

            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
              // Switch to chosen process.  It is the process's job
              // to release its lock and then reacquire it
              // before jumping back to us.
              p->state = RUNNING;
              c->proc = p;
              swtch(&c->context, &p->context); // do 1 quantum tick

              // Process is done running for now.
              // It should have changed its p->state before coming back.
              c->proc = 0;
            }
            release(&p->lock);
            acquire(&p->lock);
            if((p->rtime > maxtick[0] ) || (p->state==SLEEPING && p->wtime>1)){ //remove from q 0 ,push que 1
                //deuue 0
                // enqueue 1

                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->rtime=0; //start rtime 0 in new queue
                p->wtime=0;
                enqueueToMultiCircularQueue(&multiQueue,1, p);
            }
            release(&p->lock);

          }
      }       
      else if(isCircularQueueEmpty(&multiQueue,1)!=1){//queue 0 ,absent

            // stay in queue 1
          //RR
          struct CircularQueue *queue= &multiQueue.queues[1];//1th queue
          for (int pos=0; pos<MAX_SIZE; pos++)
          { 

            if(sahil==1){
              printf("--\n");
              sahil=0;
              break;  //goto top after 1 tick ,unexplored new process arrived
            }
            if(ticks% agetime==0){ // %100
               aging=1;
               break; //go down anti-aging
            }

            p=queue->items[pos]; //proc *p
            
            if(p==0){continue;}  //no process at pos

            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
              // Switch to chosen process.  It is the process's job
              // to release its lock and then reacquire it
              // before jumping back to us.
              p->state = RUNNING;
              c->proc = p;
              swtch(&c->context, &p->context); // do 1 quantum tick

              // Process is done running for now.
              // It should have changed its p->state before coming back.
              c->proc = 0;
            }
            release(&p->lock);
            
            //RR 
            
            if((p->rtime > maxtick[1] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>1)){ //remove from q 0 ,push que 1
                //deuue 0
                // enqueue 1
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->rtime=0; //start rtime 0 in new queue
                p->wtime=0;
                enqueueToMultiCircularQueue(&multiQueue,2, p);
            }            
            else if((p->wtime > 12 && p->state==RUNNABLE) ){ //remove from q 1 ,push que0
                //deuue 2
                // enqueue 1
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->wtime=0; //start rtime 0 in new queue
                p->rtime=0;
                enqueueToMultiCircularQueue(&multiQueue,0, p);
            }


          }

      } 
      //queue 1 also absent    
      else if(isCircularQueueEmpty(&multiQueue,2)!=1){ //go q2 

            // stay in queue 2
          //RR
          struct CircularQueue *queue= &multiQueue.queues[2];//2 th queue
          for (int pos=0; pos<MAX_SIZE; pos++)
          { 

            if(sahil==1){
              printf("--\n");
              sahil=0;
              break;  //goto top after 1 tick ,unexplored new process arrived
            }
            if(ticks% agetime==0){ // %100
               aging=1;
               break; //go down anti-aging
            }

            p=queue->items[pos]; //proc *p
            
            if(p==0){continue;}  //no process at pos

            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
              // Switch to chosen process.  It is the process's job
              // to release its lock and then reacquire it
              // before jumping back to us.
              p->state = RUNNING;
              c->proc = p;
              swtch(&c->context, &p->context); // do 1 quantum tick

              // Process is done running for now.
              // It should have changed its p->state before coming back.
              c->proc = 0;
            }
            release(&p->lock);
            //RR 
            if((p->rtime > maxtick[2] && p->state==RUNNABLE) || (p->state==SLEEPING && p->wtime>3)){ //remove from q 0 ,push que 1
                //deuue 0
                // enqueue 1
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->rtime=0; //start rtime 0 in new queue
                p->wtime=0;
                enqueueToMultiCircularQueue(&multiQueue,3, p);
            }
            else if(p->wtime > 30 && p->state==RUNNABLE  ){ //remove from q 2 ,push que 1 //18
                //deuue 2
                // enqueue 1
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->wtime=0; //start rtime 0 in new queue
                p->rtime=0;
                enqueueToMultiCircularQueue(&multiQueue,1, p);
            }
          }           

      }
      // queue 2 also absent
      else if(isCircularQueueEmpty(&multiQueue,3)!=1){ //go q 3 

            // stay in queue 3
          //RR
          struct CircularQueue *queue= &multiQueue.queues[3];//1 th queue
          for (int pos=0; pos<MAX_SIZE; pos++)
          { 
            if(sahil==1){
              printf("--\n");
              sahil=0;
              break;  //goto top after 1 tick ,unexplored new process arrived
            }
            if(ticks% agetime==0){ // %100
               aging=1;
               break; //go down anti-aging
            }

            p=queue->items[pos]; //proc *p
            
            if(p==0){continue;}  //no process at pos

            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
              // Switch to chosen process.  It is the process's job
              // to release its lock and then reacquire it
              // before jumping back to us.
              p->state = RUNNING;
              c->proc = p;
              swtch(&c->context, &p->context); // do 1 quantum tick

              // Process is done running for now.
              // It should have changed its p->state before coming back.
              c->proc = 0;
            }
            release(&p->lock);
            //RR 
            if(p->wtime > 40 && p->state==RUNNABLE  ){ //remove from q 3 ,push que 2
                //deuue 3         why to take process ,still sleeping in higher priority?
                // enqueue 2
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->wtime=0; //start rtime 0 in new queue
                p->rtime=0;
                enqueueToMultiCircularQueue(&multiQueue,2, p);
            }
          }           

      }
      if(aging){//1  //100
        struct CircularQueue *queue= &multiQueue.queues[3];//3 th queue
          for (int pos=0; pos<MAX_SIZE; pos++)
          { 
            p=queue->items[pos]; //proc *p
            
            if(p==0){continue;}  //no process at pos

            // push all in que 0
            acquire(&p->lock);
            if (p->state == RUNNABLE ||p->state==SLEEPING)
            {
                dequeueFromMultiCircularQueue(&multiQueue, p);
                p->wtime=0; //start rtime 0 in new queue
                p->rtime=0;
                enqueueToMultiCircularQueue(&multiQueue,0, p);

            }
            release(&p->lock);  //got all runnable right now ,including new swapns

         }
         aging=0;
      }


    
    
    
    
    
    
    
    
    
    
    }



  #endif
  


  /////////////// Round Robin
  #ifdef RR
  struct proc *p=0;
  struct cpu *c = mycpu();
  c->proc = 0;

    printf("open RR\n");  
    for (;;)
    {
      // Avoid deadlock by ensuring that devices can interrupt.
      intr_on();/// *so it doesnt goes in infinite loop ,gives chance to cpu take up control if want * /

        for (p = proc; p < &proc[NPROC]; p++)
        {
          acquire(&p->lock); /// * without locking p ,we cant see if it's runnable or not* /
          if (p->state == RUNNABLE)
          {
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p; /// *cpu running process p* /
            swtch(&c->context, &p->context);

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;  /// *cpu running process 0 ,none* /
          }
          release(&p->lock);
        }
      }
  #endif
    
  
  ////////////////////

   //if (FCFS)
  //Any time we find a process with a lower creation time, first_come_process gets updated,*/
  #ifdef FCFS
  struct proc *p=0;
  struct cpu *c = mycpu();
  c->proc = 0;

    printf("open FCFS\n");
    // printf("first in first serve\n");
    struct proc * first_process =0;
    
    for(;;){
      intr_on();  //once after each proces

      int shortest_possible_time=0;
      first_process=0;

      for(p=proc; p< &proc[NPROC]; p++){
          acquire(&p->lock);
          if(p->state==RUNNABLE){
            if(first_process==0){

              shortest_possible_time=p->p_arrival_time;
              first_process=p;
              continue;

            }
            else if(shortest_possible_time> p->p_arrival_time){
                shortest_possible_time=p->p_arrival_time;
                
                release(&first_process->lock); //
                first_process=p;
                continue;
            }
          }//found first process created comp other ,and in ready State
          release(&p->lock); //not RUNNALBLE released
      }
      if(first_process!=0){
          first_process ->state= RUNNING; //change state of first_process
          c->proc =first_process;   // change the cpu's process to the one found 
          swtch(&c->context , &first_process->context); //allocate the cpu's resources 
          c->proc=0;
          
          release(&first_process->lock);
          // we will have to release the lock (which got acquired right before first_process_coming was last updated), 
          // but which did not get released
      }
      //executed one process , can reach interuupt next loop     

    }
  #endif

}


// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;

  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  
  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"}; //completed execution zombie 
  struct proc *p;
  char *state;

  printf("ticks %d\n",ticks);

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s %d %d \n", p->pid, state, p->name,p->r_time,p->w_time); //r_time in test of total till now
  
    // printf("  rt  %d , wt %d \n",p->rtime,p->wtime);// rtime ,wtime in queue
  }
  // for(int i=0;i<100;i=i+1){
  //     printf("%d",allpid[i]);
  //   }printf("\n");
    
  display(&multiQueue);
}

// waitx
int waitx(uint64 addr, uint *w_time, uint *r_time)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      { 
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);
        
        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          allpid[pid]=0;
          dequeueFromMultiCircularQueue(&multiQueue, np); //remove proc from queue
          // *rtime = np->rtime;
          *r_time = np->r_time;
          // *wtime = np->etime - np->ctime - np->rtime;
          *w_time = np->etime - np->ctime - np->r_time;//
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
      p->r_time++;
    }
    release(&p->lock);
  }
}