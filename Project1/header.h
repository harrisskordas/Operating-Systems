//You will find more details in README.txt

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/file.h>
#include <unistd.h>
#include <errno.h>
#include <sys/wait.h>
#include <assert.h>
#include <time.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>

struct  Shared_Memory{
    int seg_req;     //requested segment from .txt
    int line_req;    //requested line number from .txt
    char buffer[256];      //In char buffer[256] the father puts the line from the textfile...max 256 characters
    int l;          //temporary save of line number from .txt
};

int children(int , int , int , int , sem_t* , sem_t* , sem_t* , struct Shared_Memory* );
int parent(char* , int , int , int );

int *pid;

