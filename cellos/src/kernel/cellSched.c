#include <asm/processor.h>
#include <cellos/cellos.h>
#include <cellos/cellUtil.h>

#define CELL_INIT_TASK_STACK_SIZE   (8192)

u8          initTaskStack[CELL_INIT_TASK_STACK_SIZE];
CELL_TASK   cellInitTask;

CELL_TASK * pCurrentTask = NULL;    /* current task pointer */
CELL_TASK * pNextReadyTask = NULL;  /* next highest priority ready task pointer */
uint        globalTimeSlice = 0;    /* global time slice remained for current task */

/* task schedule loop */
void cellSched (void)
    {
    /* enable interrupt so that things can go */
    CELL_INT_ENABLE();

    /* wait until the next highest priroty task comes */
    while (!pNextReadyTask);

    /* disable interrupt so that we can safely update the list */
    CELL_INT_DISABLE();

    /* Now point the current task pointer to the next highest priority ready task */
    pCurrentTask = pNextReadyTask;

    /* now save the remaining time slice to the global time slice variable */
    globalTimeSlice = pCurrentTask->nRemainTimeSlice;

    if (pCurrentTask->nStackFrameType == STACK_FRAME_INT_TYPE)
        {

        }
     else /* STACK_FRAME_SYNC_TYPE */
        {
        /* cope with syncronized  */
        }

    }

void cellSchedInit (void)
    {
    cellInitTask.nStackFrameType = STACK_FRAME_SYNC_TYPE;
    cellInitTask.nInitTimeSlice = 100;
    cellInitTask.nRemainTimeSlice = 1;
    cellInitTask.nStackSize = CELL_INIT_TASK_STACK_SIZE;
    cellInitTask.pStackStart = &initTaskStack[0];
    cellInitTask.pStackPtr = &initTaskStack[CELL_INIT_TASK_STACK_SIZE - 1];
    printf("cellInitTask.pStackPtr %p\r\n",cellInitTask.pStackPtr );
    cellInitTask.pStackPtr = (char *)(((ulong)cellInitTask.pStackPtr) & (~(0x7)));
    cellInitTask.taskState = TASK_READY;
    strcpy(cellInitTask.taskName, "cellInitTask");

    pCurrentTask = &cellInitTask;

    pNextReadyTask = NULL;
    }

void idle(void)
    {
    printf("end task %s stack %p\r\n",
        pCurrentTask->taskName, pCurrentTask->pStackPtr);
    while(1);
    }

ulong cellTaskCreate
    (
    CELL_TASK * pNewTask,
    char *      taskName,
    void        (* taskEntry)(ulong),
    ulong       entryParam,
    char *      pStackStart,
    uint        nStackSize,
    uint        nPriority,
    uint        nTimeSlice,
    uint        startNow
    )
    {
    struct pt_regs * pStackFrame;

    pNewTask->nStackFrameType = STACK_FRAME_INT_TYPE;
    pNewTask->nInitTimeSlice = nTimeSlice;
    pNewTask->nRemainTimeSlice = nTimeSlice;
    pNewTask->nStackSize = nStackSize;
    pNewTask->pStackStart = pStackStart;
    pNewTask->pStackPtr = pStackStart + nStackSize - 1;
    pNewTask->pStackPtr = (char *)(((ulong)pNewTask->pStackPtr) & (~(0x7)));
    pNewTask->taskState = TASK_READY;
    strcpy(pNewTask->taskName, taskName);

    memset(pNewTask->pStackStart, 0, nStackSize);

    pNewTask->pStackPtr -= (INT_FRAME_SIZE - STACK_FRAME_OVERHEAD);

    pStackFrame = (struct pt_regs *)(pNewTask->pStackPtr);

    pStackFrame->nip = (PPC_REG)taskEntry;

    /* Rembemer to preserve r14 !!! */

    pStackFrame->msr = (PPC_REG)get_msr() | MSR_EE;

    /* Set the task stack pointer so that it can "return" from this point */

    pStackFrame->gpr[1] = (PPC_REG)pNewTask->pStackPtr - STACK_FRAME_OVERHEAD;

    pStackFrame->gpr[3] = (PPC_REG)entryParam;

    /*
     * NOTE:
     *
     * r14 is special, it is used as the GOT anchor, which is not
     * changed throughout the system once it is setup (currently).
     * We MUST set this corrently (from the current task creating
     * this new task).
     * Adding this fixes the qemu reported problem before:
     * "invalid/unsupported opcode: 00 - 00 - 00 (00000000) 00000010 0"
     */

     /*
      * This will generate code like this:
      * 50d8:	91 dd 00 38 	stw     r14,56(r29)
      */

    __asm__ __volatile__("stw %%r14,%0":"=m"(pStackFrame->gpr[14]));

    /* For now let's just use a while loop if the task exited...*/
    /* This will surely be changed soon!!! */

    pStackFrame->link = (PPC_REG)idle;

    printf("new task %s stack %p\r\n",pNewTask->taskName, pNewTask->pStackPtr);

    if (startNow == TRUE)
        {
        pNextReadyTask = pNewTask;
        }

    return 0;
    }

void testTaskEntry
    (
    ulong param
    )
    {
    int count = 0;

    printf("%s task entered, param = 0x%x \r\n",
           pCurrentTask->taskName, param);

    while(1)
        {
        printf("%s count %d\r\n", pCurrentTask->taskName, count++);

        udelay(1000000);
        }
    }

CELL_TASK testTask;

#define CELL_STACK_SIZE_DEFAULT 4096

char testTaskStack[CELL_STACK_SIZE_DEFAULT];

void taskTestInit(void)
    {
    ulong ret;

    ret = cellTaskCreate(&testTask,
                        "testTask",
                        testTaskEntry,
                        0x12345678,
                        testTaskStack,
                        CELL_STACK_SIZE_DEFAULT,
                        1,
                        5,
                        1
                        );
    return;
    };

void cellTimerInterrupt
    (
    struct pt_regs * pSavedRegs /* on current task stack */
    )
    {
    CELL_TASK * pTempTask;
    struct pt_regs *pStackFrame;

    pSavedRegs->mq = 0;

    if (pCurrentTask == NULL)
        return;

    pCurrentTask->nRemainTimeSlice--;

    if (pCurrentTask->nRemainTimeSlice == 0)
        {
        printf("task %s run out\r\n",pCurrentTask->taskName);

        if (pNextReadyTask == NULL)
            {
            pCurrentTask->nRemainTimeSlice = pCurrentTask->nInitTimeSlice;
            }
        else
            {
            pCurrentTask->pStackPtr = (char*)pSavedRegs;

            printf("old stack at %p on task %s,new task stack at %p\r\n ",
                pCurrentTask->pStackPtr,pCurrentTask->taskName,pNextReadyTask->pStackPtr);

            pTempTask = pCurrentTask;

            pCurrentTask = pNextReadyTask;

            pNextReadyTask = pTempTask;

            pCurrentTask->nRemainTimeSlice = pCurrentTask->nInitTimeSlice;

            pStackFrame = pCurrentTask->pStackPtr;

            printf("switch to %s for %d ticks,stack at %p, msr %p\r\n",
                pCurrentTask->taskName,
                pCurrentTask->nRemainTimeSlice,
                (ulong)pCurrentTask->pStackPtr,
                pStackFrame->msr);

            pSavedRegs->mq = (PPC_REG)pCurrentTask->pStackPtr;

            printf("pSavedRegs %p, pSavedRegs->mq %p \r\n",
                (ulong)pSavedRegs, pSavedRegs->mq);

            /* show_regs(pStackFrame); */

            }
        }
    }

