//You will find more details in README.txt

#include "header.h"

int main(int argc, char *argv[]) 
{
    if (argc != 5){
        printf("\nYou must give filename.txt, number of procceses, number of transactions and number of lines for every segmentation\n\n");
        return (1);
    }

    int numproc = atoi(argv[2]);
    if (numproc == 0){
        printf("Number of processes cannot be 0\n");
        return (1);
    }

    int numtrans = atoi(argv[3]);
    if (numtrans == 0){
        printf("Number of transactions cannot be 0\n");
        return (1);
    }

    int lps = atoi(argv[4]);
    if (lps == 0){
        printf("Number of lines for every segmentation cannot be 0\n");
        return (1);
    }

    char* fname = argv[1];
    
    parent(fname, numproc, numtrans, lps);

    return 0;
}

int parent(char *fname, int numproc, int numtrans, int lps){

    int value;
    char* line[100000];
    char l[100000];     // In the file there must be  maximum 100000 lines
    FILE *fptr = NULL; 
    int i = 0;
    int tot = 0;
    int segNum = 0;

    printf("Welcome to parent process");

    printf("\nThe file you entered is: %s \n", fname);
    fptr = fopen(fname, "r");
    while(fgets(l , sizeof l , fptr)!=NULL){

        line[i]=malloc(sizeof(l));             // Add each line into an array
        strcpy(line[i] , l);
        i++;        // Count number of lines in file
    }

    tot = i;
    segNum = (tot/lps);
    if (segNum * lps != tot){
        segNum++;
    }

    printf("Number of lines of file is: %d\n", tot);
    printf("Number of children: %d\n", numproc);
    printf("Number of transactions for every children: %d\n", numtrans);
    printf("Number of segmentations: %d\n", segNum);
    printf("Each segmentation has got: %d lines\n", lps);


    //Creating the semaphores 
    sem_t *semparent = sem_open("semparent" , O_CREAT|O_EXCL , S_IRUSR|S_IWUSR , 0);    // Semaphore for block parent process.
    if(semparent != SEM_FAILED){
        printf("Succefully created new semaphore with name <<semparent>>!\n");
    }else if(errno == EEXIST ){
        printf("Semaphore with name <<semparent>> appears to exist already!\n");
        semparent = sem_open("semparent", 0);
    }
    assert(semparent != SEM_FAILED);
    sem_getvalue(semparent , &value);
    printf("Semparent before action has value: %d\n", value);


    sem_t *semchildren=sem_open("semchildren" , O_CREAT|O_EXCL , S_IRUSR|S_IWUSR , 1);       // Semaphore for block children processes.
    if(semchildren != SEM_FAILED){
        printf("Succefully created new semaphore with name <<semchildren>>!\n");
    }else if(errno == EEXIST ){
        printf("Semaphore with name <<semchildren>> appears to exist already!\n");
        semchildren = sem_open("semchildren", 0);
    }
    assert(semchildren != SEM_FAILED);
    sem_getvalue(semchildren , &value);
    printf("semchildren before action has value: %d\n", value);


    sem_t *semchild=sem_open("semchild" , O_CREAT|O_EXCL , S_IRUSR|S_IWUSR , 0);      // Semaphore for block child process.
    if(semchild != SEM_FAILED){
        printf("Succefully created new semaphore with name <<semchild>>!\n");
    }else if(errno == EEXIST){
        printf("Semaphore with name <<semchild>> appears to exist already!\n");
        semchild = sem_open("semchild", 0);
    }
    assert(semchild != SEM_FAILED);
    sem_getvalue(semchild , &value);
    printf("Semchild before action has value: %d\n", value);

    /* Make shared memory segment */
    int id=0;
    struct Shared_Memory *memo;
    id = shmget(IPC_PRIVATE,sizeof(struct Shared_Memory),0666); 
    if (id == -1) {
        perror ("Creation");
        return 1;
    } else {
        printf("Allocated Shared Memory with ID: %d\n",(int)id);
    }

    /* Attach the segment */
    memo = shmat(id, NULL, 0);
    if ( *(int *) memo == -1) {
        perror("Attachment.");
        return 1;
    } else {
        printf("Just Attached Shared Memory.\n");
    }

    children(numproc , numtrans , segNum, lps, semparent , semchildren , semchild , memo);

    for(int i = 0 ; i < numproc ; i++){
        if(pid[i]!=0){
            for(int j = 0 ; j < numtrans ; j++){
                sem_wait(semparent);                                     //Parent waits child to write the number of line
                memo->l = (memo->seg_req * lps) + memo->line_req;
                strcpy(memo->buffer,line[memo->l]);                 //Parent reads the number of line and writes the line content
                printf("Server is delivering the line...\n");
                /*Signals from parent to children that wrote the line */
                sem_post(semchildren);
                sem_post(semchild);
            }
        }
    }
    for(int i = 0 ; i < numproc ; i++){
        if(waitpid(pid[i],NULL,0) < 0 ){
            perror("waitpid");
        return 1;
        }
    }

    /* Detach segment */
    int err = 0;
    err = shmdt((void *) memo);
    if(err == -1){
        perror("Detachment.");
        return 1;
    }else{
        printf(">> Detachment of Shared Segment %d\n", err);
    }

    /* Remove segment */
    err = shmctl(id, IPC_RMID, 0);
    if(err == -1) {
        perror("Removal.");
        return 1;
    }else{
        printf(">> Just Removed Shared Segment. %d\n", err);
    }

    //Closing the semaphores
    printf("Clearing up semparent semaphore\n");
    sem_close(semparent);                // close the semaphore
    sem_unlink("semparent");             // remove it from system

    printf("Clearing up semchildren semaphore\n");
    sem_close(semchildren);
    sem_unlink("semchildren");

    printf("Clearing up semchild semaphore\n");
    sem_close(semchild);
    sem_unlink("semchild");

    fclose(fptr);

    return 0;
}

int children(int numproc, int numtrans, int segNum, int lps, sem_t* semparent, sem_t* semchildren, sem_t* semchild,  struct Shared_Memory* memo){

    FILE *fp;

    pid = malloc(numproc *sizeof(int));
    for(int i = 0; i < numproc ; i++){
        pid[i] = fork();
        if(pid[i] < 0){
            perror("Failed to create process");
            return 1;
        }
        if(pid[i] == 0){
            double sum = 0.0, req = 0.0, del = 0.0, avg;
            clock_t start,end;
            srand(time(NULL) + getpid());

            char write_in[1000];
            sprintf(write_in, "%d", getpid());      //for naming the text files...it keeps the getppid and make it string as name of file

            sem_t *semsegment=sem_open("semsegment" , O_CREAT|O_EXCL , S_IRUSR|S_IWUSR , 0);       // Semaphore for block children processes.
            if(semsegment != SEM_FAILED){
                printf("Succefully created new semaphore with name <<semsegment>>!\n");
            }else if(errno == EEXIST ){
                printf("Semaphore with name <<semsegment>> appears to exist already!\n");                    
                semsegment = sem_open("semsegment", 0);
            }
            int value;
            assert(semsegment!= SEM_FAILED);
            sem_getvalue(semsegment , &value);
            printf("semsegment before action has value: %d\n", value);

            for(int j = 0 ; j < numtrans ; j++){
                start = clock();
                sem_wait(semchildren);                     // Block other children processes
                //for the possibility
                int x = rand() % (10);
                if(x > 7){      //else it keeps the previous selected segment
                    printf("New segment choosed!\n");
                    memo->seg_req = rand() % segNum;
                }else{
                    printf("Previous segment choosed!\n");
                }
                memo->line_req = rand() % lps;             // Child write the number of line
                end = clock();
                req = ((double)end - (double)start)/CLOCKS_PER_SEC;
                //printf("Child with id %d is requesting <%d,%d> at time: %.10lf\n",getpid() , memo->seg_req+1, memo->line_req+1, req);

                start = clock();
                sem_post(semparent);                     // Signal to parent for writing the number of line
                sem_wait(semchild);                     // Wait for delivering line
                fp  = fopen(write_in,"a");  //write_in=name of the child 
                fprintf(fp, "\n<%d,%d>", memo->seg_req+1, memo->line_req+1);
                fprintf(fp, "  Line: %s", memo->buffer);
                fprintf(fp, "Requested at: %.10lf", req);
                end = clock();
                del = (((double)end - (double)start)/CLOCKS_PER_SEC);
                fprintf(fp, "\nDelivered at: %.10lf", del);
                //printf("The line which is requested from child with %d,delivered after %.10lf, is : %s\n",getpid(), del, memo->buffer);
                sleep(0.02);
                end = clock();
                sum = sum + ((double)end - (double)start)/CLOCKS_PER_SEC;
            }
            avg = sum/numtrans;
            printf("Child with id %d is exiting with average time %.10lf\n",getpid(),avg);          // This will print 10 digits
            exit(EXIT_SUCCESS);
            sem_close(semsegment);                // close the semaphore
            sem_unlink("semsegment");             // remove it from system
        }
    }
    return 0;
}
