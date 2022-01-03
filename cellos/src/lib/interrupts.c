/*
 * (C) Copyright 2000-2002
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 *
 * (C) Copyright 2003
 * Gleb Natapov <gnatapov@mrv.com>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <common.h>
#include <asm/watchdog.h>
#include <asm/processor.h>
#include <asm/interrupt.h>
#include <asm/ppc4xx.h>
#include <asm/ppc_asm.S>

DECLARE_GLOBAL_DATA_PTR;

/*
 * CPM interrupt vector functions.
 */
struct	irq_action {
	interrupt_handler_t *handler;
	void *arg;
	int count;
};
static struct irq_action irq_vecs[IRQ_MAX];


static __inline__ void set_pit(unsigned long val)
{
	asm volatile("mtpit %0" : : "r" (val));
}


static __inline__ void set_tcr(unsigned long val)
{
	asm volatile("mttcr %0" : : "r" (val));
}


static __inline__ void set_evpr(unsigned long val)
{
	asm volatile("mtevpr %0" : : "r" (val));
}


int interrupt_init_cpu (unsigned *decrementer_count)
{
	int vec;
	unsigned long val;

	/* decrementer is automatically reloaded */
	*decrementer_count = 0;

	/*
	 * Mark all irqs as free
	 */
	for (vec = 0; vec < IRQ_MAX; vec++) {
		irq_vecs[vec].handler = NULL;
		irq_vecs[vec].arg = NULL;
		irq_vecs[vec].count = 0;
	}

	/*
	 * Init PIT
	 */
	set_pit(CONFIG_SYS_PIT_RELOAD);


	/*
	 * Enable PIT
	 */
	val = mfspr(SPRN_TCR);
	val |= 0x04400000; /* PIT Interrupt Enable and Auto Reload Enable */
	mtspr(SPRN_TCR, val);

	/*
	 * Set EVPR to 0
	 */
	set_evpr(0x00000000);

	/*
	 * Call uic pic_enable
	 */
	pic_enable();

	return (0);
}

void timer_interrupt_cpu(struct pt_regs *regs)
{
	/* nothing to do here */
	return;
}

void interrupt_run_handler(int vec)
{
	irq_vecs[vec].count++;

	if (irq_vecs[vec].handler != NULL) {
		/* call isr */
		(*irq_vecs[vec].handler) (irq_vecs[vec].arg);
	} else {
		pic_irq_disable(vec);
		printf("Masking bogus interrupt vector %d\n", vec);
	}

	pic_irq_ack(vec);
	return;
}

void irq_install_handler(int vec, interrupt_handler_t * handler, void *arg)
{
	/*
	 * Print warning when replacing with a different irq vector
	 */
	if ((irq_vecs[vec].handler != NULL) && (irq_vecs[vec].handler != handler)) {
		printf("Interrupt vector %d: handler 0x%x replacing 0x%x\n",
		       vec, (uint) handler, (uint) irq_vecs[vec].handler);
	}
	irq_vecs[vec].handler = handler;
	irq_vecs[vec].arg = arg;

	pic_irq_enable(vec);
	return;
}

void irq_free_handler(int vec)
{
	debug("Free interrupt for vector %d ==> %p\n",
	      vec, irq_vecs[vec].handler);

	pic_irq_disable(vec);

	irq_vecs[vec].handler = NULL;
	irq_vecs[vec].arg = NULL;
	return;
}

void board_show_activity (int dummy)
{
	printf("active [%d]\r\n",dummy);

	return;
}


#ifndef CONFIG_SYS_WATCHDOG_FREQ
#define CONFIG_SYS_WATCHDOG_FREQ (CONFIG_SYS_HZ / 2)
#endif

extern int interrupt_init_cpu (unsigned *);
extern void timer_interrupt_cpu (struct pt_regs *);

static unsigned decrementer_count; /* count value for 1e6/HZ microseconds */

unsigned long get_msr (void)
{
	unsigned long msr;

	asm volatile ("mfmsr %0":"=r" (msr):);

	return msr;
}

static __inline__ void set_msr (unsigned long msr)
{
	asm volatile ("mtmsr %0"::"r" (msr));
}

static __inline__ unsigned long get_dec (void)
{
	unsigned long val;

	asm volatile ("mfdec %0":"=r" (val):);

	return val;
}


static __inline__ void set_dec (unsigned long val)
{
	if (val)
		asm volatile ("mtdec %0"::"r" (val));
}

/*
 * The MSR[EE] bit may be set/cleared atomically using
 * the wrtee or wrteei instructions.
 */

void enable_interrupts (void)
{
	set_msr (get_msr () | MSR_EE);
}

/* returns flag if MSR_EE was set before */
int disable_interrupts (void)
{
	ulong msr = get_msr ();

	set_msr (msr & ~MSR_EE);
	return ((msr & MSR_EE) != 0);
}

int interrupt_init (void)
{
	int ret;

	/* call cpu specific function from $(CPU)/interrupts.c */
	ret = interrupt_init_cpu (&decrementer_count);

	if (ret)
		return ret;

	set_dec (decrementer_count);

	set_msr (get_msr () | MSR_EE);

	return (0);
}

static volatile ulong timestamp = 0;

void timer_interrupt (struct pt_regs *regs)
{
	/* call cpu specific function from $(CPU)/interrupts.c */
	timer_interrupt_cpu (regs);

	/* Restore Decrementer Count */
	set_dec (decrementer_count);

	timestamp++;

#if defined(CONFIG_WATCHDOG) || defined (CONFIG_HW_WATCHDOG)
	if ((timestamp % (CONFIG_SYS_WATCHDOG_FREQ)) == 0)
		WATCHDOG_RESET ();
#endif    /* CONFIG_WATCHDOG || CONFIG_HW_WATCHDOG */

    if ((timestamp % 500) == 1)
        board_show_activity (timestamp);

    /*DebugException(regs);*/

    cellTimerInterrupt(regs);
}

void reset_timer (void)
{
	timestamp = 0;
}

ulong get_timer (ulong base)
{
	return (timestamp - base);
}

void set_timer (ulong t)
{
	timestamp = t;
}
