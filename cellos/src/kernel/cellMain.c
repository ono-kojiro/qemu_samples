/*
 CellOS - An experimental OS focus specially on studying PowerPC machines

 Copyright (C) 2009 cory.xie@gmail.com

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <common.h>

// heap_start and heap_end address used to clear the memory
extern u32 __heap_start;
extern u32 __heap_end;

extern u32 __stack_bottom;
extern u32 __stack_top;

/*
 * Begin and End of memory area for malloc(), and current "brk"
 */
static	ulong	mem_malloc_start = 0;
static	ulong	mem_malloc_end	 = 0;
static	ulong	mem_malloc_brk	 = 0;

/************************************************************************
 * Utilities								*
 ************************************************************************
 */

/*
 * The Malloc area is immediately below the monitor copy in DRAM
 */
static void mem_malloc_init (void)
{
	mem_malloc_start = (ulong)&__heap_start;
	mem_malloc_end = (ulong)&__heap_end;
	mem_malloc_brk = mem_malloc_start;

	memset ((void *) mem_malloc_start,
		0,
		mem_malloc_end - mem_malloc_start);
}

void *sbrk (ptrdiff_t increment)
{
	ulong old = mem_malloc_brk;
	ulong new = old + increment;

	if ((new < mem_malloc_start) || (new > mem_malloc_end)) {
		return (NULL);
	}
	mem_malloc_brk = new;
	return ((void *) old);
}

extern u64 readTB(void);
extern u32 readTBL(void);

/*!
 * \ingroup startup
 * The main "C" entry point for the OS after the assembler startup code has been executed.
 */
void cellMain()
{
    u32  idx;
    u64  tb;
    u32  tbl;
    caddr_t buffer;
    size_t  heapSize = (caddr_t)&__heap_end - (caddr_t)&__heap_start;
    size_t  stackSize = (caddr_t)&__stack_top - (caddr_t)&__stack_bottom;

    memset(&__heap_start, 0, heapSize);

    mem_malloc_init();

    serial0_init();
    serial1_init();

    printf("\r\nHello Qemu\r\n");

    printf("stack size %p [%p -> %p]\r\n", stackSize, &__stack_bottom, &__stack_top);
    printf("heap size %p [%p -> %p]\r\n", heapSize, &__heap_start, &__heap_end);
    printf("TB CLK = %d, BUS CLK = %d\r\n", get_tbclk(), get_bus_freq());

    buffer = malloc(64);
    if (buffer == NULL)
        {
	printf("No memory\r\n");
        }
    else
        {
	printf("Got memory at %p\r\n",buffer);
        }

    interrupt_init();

    cellSchedInit();
    taskTestInit();
    while(1)
	{
	tb = (u64)readTB();
	tbl = (u32)readTBL();
	printf("[%d] Hello Qemu %d, TB = %ld, TBL = %d\r\n", idx, heapSize, (long int)tb, tbl);
       	idx++;
	udelay(1000000);
	}


    // we shouldn't get here!
    while (1) {;}
}

