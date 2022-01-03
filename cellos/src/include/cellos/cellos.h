#ifndef _CELLOS_H
#define _CELLOS_H

#include <cellos/types.h>
#include <asm/ptrace.h>
#include <asm/ppc_defs.h>

#define CELL_MAX_NAME_SIZE  32

typedef struct cell_task
    {
    char    taskName[CELL_MAX_NAME_SIZE]; /* task name */
    int     taskId;     /* task indentifier */
    uint    priority;   /* task priority */
    char *  pStackStart; /* stack start address */
    char *  pStackPtr;   /* current stack pointer */
    uint    nStackSize; /* stack size */
    uint    nStackFrameType; /* type of stack frame */
    uint    nInitTimeSlice; /* initial time slice */
    uint    nRemainTimeSlice; /* remaining time slice */
    uint    taskState;   /* task state */
    void    (*taskEntry)(ulong);
    ulong   entryParameter;
    }CELL_TASK;

typedef enum cell_task_state
    {
    TASK_READY = 0,
    TASK_SUSPEND,
    TASK_PENDING,
    TASK_DEAD
    }CELL_TASK_STATE;

typedef enum cell_stack_frame_type
    {
    STACK_FRAME_INT_TYPE = 0,
    STACK_FRAME_SYNC_TYPE
    }CELL_STACK_FRAME_TYPE;

#define CELL_STACK_FRAME_SIZE (STACK_FRAME_OVERHEAD + INT_FRAME_SIZE)

#endif /* _CELLOS_H */
