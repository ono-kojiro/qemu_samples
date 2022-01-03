/* CellOS - An experimental OS focus specially on studying PowerPC machines
 * Copy right (C) 2009 cory.xie@gmail.com
 */

/*
 *  Copyright (C) 1998	Dan Malek <dmalek@jlc.net>
 *  Copyright (C) 1999	Magnus Damm <kieraypc01.p.y.kie.era.ericsson.se>
 *  Copyright (C) 2000,2001,2002 Wolfgang Denk <wd@denx.de>
 *  Copyright (C) 2007 Stefan Roese <sr@denx.de>, DENX Software Engineering
 *  Copyright (c) 2008 Nuovation System Designs, LLC
 *    Grant Erickson <gerickson@nuovations.com>
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */
/*------------------------------------------------------------------------------+
 *
 *	 This source code has been made available to you by IBM on an AS-IS
 *	 basis.	 Anyone receiving this source is licensed under IBM
 *	 copyrights to use it in any way he or she deems fit, including
 *	 copying it, modifying it, compiling it, and redistributing it either
 *	 with or without modifications.	 No license under IBM patents or
 *	 patent applications is to be implied by the copyright license.
 *
 *	 Any user of this software should understand that IBM cannot provide
 *	 technical support for this software and will not be responsible for
 *	 any consequences resulting from the use of this software.
 *
 *	 Any person who transfers this source code or any derivative work
 *	 must include the IBM copyright notice, this paragraph, and the
 *	 preceding two paragraphs in the transferred software.
 *
 *	 COPYRIGHT   I B M   CORPORATION 1995
 *	 LICENSED MATERIAL  -  PROGRAM PROPERTY OF I B M
 *-------------------------------------------------------------------------------
 */

/*  U-Boot - Startup Code for AMCC 4xx PowerPC based Embedded Boards
 *
 *
 *  The processor starts at 0xfffffffc and the code is executed
 *  from flash/rom.
 *  in memory, but as long we don't jump around before relocating.
 *  board_init lies at a quite high address and when the cpu has
 *  jumped there, everything is ok.
 *  This works because the cpu gives the FLASH (CS0) the whole
 *  address space at startup, and board_init lies as a echo of
 *  the flash somewhere up there in the memorymap.
 *
 *  board_init will change CS0 to be positioned at the correct
 *  address and (s)dram will be positioned at address 0
 */
#include <common.h>

#include <asm/ppc_asm.S>
#include <asm/ppc_defs.h>

#include <asm/cache.h>
#include <asm/mmu.h>
#include <asm/ppc4xx.h>
#include <asm/ppc4xx-isram.h>

#if !defined(CONFIG_SYS_ICACHE_SACR_VALUE)
# define CONFIG_SYS_ICACHE_SACR_VALUE		\
		(PPC_128MB_SACR_VALUE(CONFIG_SYS_SDRAM_BASE + (  0 << 20)) | \
		 PPC_128MB_SACR_VALUE(CONFIG_SYS_SDRAM_BASE + (128 << 20)) | \
		 PPC_128MB_SACR_VALUE(CONFIG_SYS_FLASH_BASE))
#endif /* !defined(CONFIG_SYS_ICACHE_SACR_VALUE) */

#if !defined(CONFIG_SYS_DCACHE_SACR_VALUE)
# define CONFIG_SYS_DCACHE_SACR_VALUE		\
		(0x00000000)
#endif /* !defined(CONFIG_SYS_DCACHE_SACR_VALUE) */

#define function_prolog(func_name)	.text; \
					.align 2; \
					.globl func_name; \
					func_name:
#define function_epilog(func_name)	.type func_name,@function; \
					.size func_name,.-func_name

/* We don't want the  MMU yet.
*/
#undef	MSR_KERNEL
#define MSR_KERNEL ( MSR_ME  )	/* Machine Check */

#define SYNC    \
        sync;   \
        isync

/*
 * Macros for storing registers into and loading registers from
 * exception frames.
 */
#define SAVE_GPR(n, base)       stw     n,GPR0+4*(n)(base)
#define SAVE_2GPRS(n, base)     SAVE_GPR(n, base); SAVE_GPR(n+1, base)
#define SAVE_4GPRS(n, base)     SAVE_2GPRS(n, base); SAVE_2GPRS(n+2, base)
#define SAVE_8GPRS(n, base)     SAVE_4GPRS(n, base); SAVE_4GPRS(n+4, base)
#define SAVE_10GPRS(n,base) 	SAVE_8GPRS(n, base); SAVE_2GPRS(n+8, base)
#define REST_GPR(n, base)       lwz     n,GPR0+4*(n)(base)
#define REST_2GPRS(n, base)     REST_GPR(n, base); REST_GPR(n+1, base)
#define REST_4GPRS(n, base)     REST_2GPRS(n, base); REST_2GPRS(n+2, base)
#define REST_8GPRS(n, base)     REST_4GPRS(n, base); REST_4GPRS(n+4, base)
#define REST_10GPRS(n,base)     REST_8GPRS(n, base); REST_2GPRS(n+8, base)

/*
 * GCC sometimes accesses words at negative offsets from the stack
 * pointer, although the SysV ABI says it shouldn't.  To cope with
 * this, we leave this much untouched space on the stack on exception
 * entry.
 */
#define STACK_UNDERHEAD 64

/*
 * Exception entry code.  This code runs with address translation
 * turned off, i.e. using physical addresses.
 * We assume sprg3 has the physical address of the current
 * task's thread_struct.
 */
 /* Save:
  * CR, r0, r1 (sp), r2, r3, r4, r5, r6, r20, r21, r22, r23,
  * LR, CTR, XER, DAR, SRR0, SRR1
  */
#define EXCEPTION_PROLOG(reg1, reg2)    \
        mtspr   SPRG0,r20;              \
        mtspr   SPRG1,r21;              \
        mfcr    r20;                    \
        subi    r21,r1,INT_FRAME_SIZE+STACK_UNDERHEAD;  /* alloc exc. frame */\
        stw     r20,_CCR(r21);  /* save registers */  \
        stw     r22,GPR22(r21); 		\
        stw     r23,GPR23(r21); 		\
        mfspr   r20,SPRG0;              \
        stw     r20,GPR20(r21); 		\
        mfspr   r22,SPRG1;              \
        stw     r22,GPR21(r21); 		\
        mflr    r20;                    \
        stw     r20,_LINK(r21); 		\
        mfctr   r22;                    \
        stw     r22,_CTR(r21);  		\
        mfspr   r20,XER;                \
        stw     r20,_XER(r21);  		\
        mfspr   r20, DAR_DEAR;  		\
        stw     r20,_DAR(r21);  		\
        mfspr   r22,reg1;               \
        mfspr   r23,reg2;               \
        stw		r0,GPR0(r21);   		\
        stw		r1,GPR1(r21);   		\
        stw		r2,GPR2(r21);   		\
        stw		r1,0(r21);/* back chain */		\
        mr		r1,r21;/* set new kernel sp */ 	\
        SAVE_4GPRS(3, r21);
/*
 * Note: code which follows this uses cr0.eq (set if from kernel),
 * r21, r22 (SRR0), and r23 (SRR1).
 */

/*
 * Exception vectors.
 *
 * The data words for `hdlr' and `int_return' are initialized with
 * OFFSET values only; they must be relocated first before they can
 * be used!
 */
#define STD_EXCEPTION(n, label, hdlr)                   		\
        . = n;                                          		\
label:                                                  		\
        EXCEPTION_PROLOG(SRR0, SRR1);                           \
        lwz	r3,GOT(transfer_to_handler);            			\
        mtlr    r3;                                             \
        addi    r3,r1,STACK_FRAME_OVERHEAD;                    	\
        li 		r20,MSR_KERNEL;                         		\
        rlwimi  r20,r23,0,25,25;                                \
        blrl;                                                  	\
.L_ ## label :                                                 	\
        .long   hdlr - _start + _START_OFFSET;          		\
        .long   int_return - _start + _START_OFFSET

#define CRIT_EXCEPTION(n, label, hdlr)                  		\
        . = n;                                                 	\
label:                                                         	\
        EXCEPTION_PROLOG(CSRR0, CSRR1);                        	\
        lwz		r3,GOT(transfer_to_handler);            		\
        mtlr    r3;                                            	\
        addi    r3,r1,STACK_FRAME_OVERHEAD;                    	\
        li		r20,(MSR_KERNEL & ~(MSR_ME|MSR_DE|MSR_CE));    	\
        rlwimi  r20,r23,0,25,25;                                \
        blrl;                                                   \
.L_ ## label :                                                  \
        .long   hdlr - _start + _START_OFFSET;          		\
        .long   crit_return - _start + _START_OFFSET

#define MCK_EXCEPTION(n, label, hdlr)                   		\
        . = n;                                                  \
label:                                                          \
        EXCEPTION_PROLOG(MCSRR0, MCSRR1);                    	\
        lwz	r3,GOT(transfer_to_handler);    		     		\
        mtlr    r3;                                             \
        addi    r3,r1,STACK_FRAME_OVERHEAD;                   	\
        li	r20,(MSR_KERNEL & ~(MSR_ME|MSR_DE|MSR_CE));     	\
        rlwimi  r20,r23,0,25,25;                                \
        blrl;                                                   \
.L_ ## label :                                                  \
        .long   hdlr - _start + _START_OFFSET;          		\
        .long   mck_return - _start + _START_OFFSET


/***************************************************************************
 *
 * These definitions simplify the ugly declarations necessary for GOT
 * definitions.
 *
 * Stolen from prepboot/bootldr.h, (C) 1998 Gabriel Paubert, paubert@iram.es
 *
 * Uses r14 to access the GOT
 */

#define START_GOT                               \
        .section        ".got2","aw";           \
.LCTOC1 = .+32768

#define END_GOT                                 \
        .text

#define GET_GOT                                 \
        bl      1f                      ;       \
        .text   2                       ;       \
0:      .long   .LCTOC1-1f              ;       \
        .text                           ;       \
1:      mflr    r14                     ;       \
        lwz             r0,0b-1b(r14)   ;       \
        add             r14,r0,r14              ;

#define GOT_ENTRY(NAME)         .L_ ## NAME = . - .LCTOC1 ; .long NAME

#define GOT(NAME)  		.L_ ## NAME (r14)

/*
 * Set up GOT: Global Offset Table
 *
 * Use r14 to access the GOT
 */
 START_GOT
 GOT_ENTRY(_GOT2_TABLE_)
 GOT_ENTRY(_FIXUP_TABLE_)

 GOT_ENTRY(_start)
 GOT_ENTRY(_start_of_vectors)
 GOT_ENTRY(_end_of_vectors)
 GOT_ENTRY(transfer_to_handler)

 GOT_ENTRY(__init_end)
 GOT_ENTRY(_end)
 GOT_ENTRY(__bss_start)
 END_GOT

/*
 * r3 - 1st arg to board_init(): IMMP pointer
 * r4 - 2nd arg to board_init(): boot flag
 */
	.text
version_string:
	.ascii "CelloOS 0.0.1"

	. = EXC_OFF_SYS_RESET
_start_of_vectors:

/* Critical input. */
	CRIT_EXCEPTION(0x100, CritcalInput, UnknownException)

	CRIT_EXCEPTION(0x200, MachineCheck, MachineCheckException)

/* Data Storage exception. */
	STD_EXCEPTION(0x300, DataStorage, UnknownException)

/* Instruction Storage exception. */
	STD_EXCEPTION(0x400, InstStorage, UnknownException)

/* External Interrupt exception. */
	STD_EXCEPTION(0x500, ExtInterrupt, external_interrupt)

/* Alignment exception. */
	. = 0x600
Alignment:
	EXCEPTION_PROLOG(SRR0, SRR1)
	mfspr	r4,DAR
	stw	r4,_DAR(r21)
	mfspr	r5,DSISR
	stw	r5,_DSISR(r21)
	addi	r3,r1,STACK_FRAME_OVERHEAD
	li	r20,MSR_KERNEL
	rlwimi	r20,r23,0,16,16		/* copy EE bit from saved MSR */
	lwz	r6,GOT(transfer_to_handler)
	mtlr	r6
	blrl
.L_Alignment:
	.long	AlignmentException - _start + _START_OFFSET
	.long	int_return - _start + _START_OFFSET

/* Program check exception */
	. = 0x700
ProgramCheck:
	EXCEPTION_PROLOG(SRR0, SRR1)
	addi	r3,r1,STACK_FRAME_OVERHEAD
	li	r20,MSR_KERNEL
	rlwimi	r20,r23,0,16,16		/* copy EE bit from saved MSR */
	lwz	r6,GOT(transfer_to_handler)
	mtlr	r6
	blrl
.L_ProgramCheck:
	.long	ProgramCheckException - _start + _START_OFFSET
	.long	int_return - _start + _START_OFFSET

	STD_EXCEPTION(0xc00, SystemCall, UnknownException)
	STD_EXCEPTION(0x1000, PIT, DecrementerPITException)
	STD_EXCEPTION(0x1100, InstructionTLBMiss, UnknownException)
	STD_EXCEPTION(0x1200, DataTLBMiss, UnknownException)

	CRIT_EXCEPTION(0x2000, DebugBreakpoint, DebugException )

_end_of_vectors:
	. = _START_OFFSET

	/*
	 * start and end addresses of the BSS section
	 * they are taken from the linker script
	 */

	.set	START_BSS,	__bss_start
	.set	END_BSS,	__bss_end

	/* stack top address exported from linker script */
	.set 	STACK_TOP,	__stack_top

cellEntry:
_start:
	/*----------------------------------------------------------------------- */
	/* Clear and set up some registers. */
	/*----------------------------------------------------------------------- */
	addi	r4,r0,0x0000
	mtsgr	r4	/* Configure guarded attribute for performance. */
	mtsler  r4	/* Configure endinanness */
	mtsu0r 	r4 	/* and compression. */

	/*------------------------------------------------------------------------
	 * Initialize vector tables and other registers
	 * set them all to 0. The Interrupt Handler implementation
	 * has to set these registers later on
	 *-----------------------------------------------------------------------*/
	mtdcwr  r4
	mtesr	r4			/* clear Exception Syndrome Reg */
	mttcr	r4			/* clear Timer Control Reg */
	mtxer	r4			/* clear Fixed-Point Exception Reg */
	mtevpr	r4			/* clear Exception Vector Prefix Reg */

	addi	r4,r0,(0xFFFF-0x10000)	/* set r4 to 0xFFFFFFFF (status in the */
					/* dbsr is cleared by setting bits to 1) */
	mtdbsr	r4			/* clear/reset the dbsr */

	/* Invalidate the i- and d-caches. */
	bl	invalidate_icache
	bl	invalidate_dcache

	/* Set-up icache cacheability. */
	lis	r4, CONFIG_SYS_ICACHE_SACR_VALUE@h
	ori	r4, r4, CONFIG_SYS_ICACHE_SACR_VALUE@l
	mticcr	r4
	isync

	/* Set-up dcache cacheability. */
	lis	r4, CONFIG_SYS_DCACHE_SACR_VALUE@h
	ori	r4, r4, CONFIG_SYS_DCACHE_SACR_VALUE@l
	mtdccr	r4


	/*----------------------------------------------------------------------- */
	/* DMA Status, clear to come up clean */
	/*----------------------------------------------------------------------- */
	addis	r3,r0, 0xFFFF		/* Clear all existing DMA status */
	ori	r3,r3, 0xFFFF
	mtdcr	dmasr, r3

#if CONFIG_SYS_CLK_RECFG
	/* This can be ignored for Qemu */
	 bl	ppc405ep_init 		/* do ppc405ep specific init */
#endif /* CONFIG_SYS_CLK_RECFG */

	/* clear the BSS section */
	lis	r3,START_BSS@h	// load start of BSS into r3
	ori	r3,r3,START_BSS@l
	lis	r4,END_BSS@h	// load end of BSS into r4
	ori	r4,r4,END_BSS@l
	sub	r4,r4,r3	// calculate length of BSS
	srwi	r4,r4,2		// convert byte-length to word-length
	li	r5,0		// zero r5
	cmplw	0,r4,r5		// check to see whether length equals 0
	beql	0,2f		// in case of length 0 we're already done
	subi	r3,r3,4		// because of offset start 4 bytes lower
	mtctr	r4		// use word-length of BSS section as counter
1:	/* bss clear start */
	stwu	r5,4(r3)	// zero one word of BSS section
	bdnz	1b		// keep going until BSS is entirely clean
2:	/* bss clear done */

/*
 * We can use the OCM for temp stack area to call C code to init the SDRAM;
 * But in QEMU we do not have to init the SDRAM
 */
#if CONFIG_SYS_TEMP_STACK_OCM
	/********************************************************************
	 * Setup OCM - On Chip Memory
	 *******************************************************************/
	lis	r0, 0x7FFF
	ori	r0, r0, 0xFFFF
	mfdcr	r3, ocmiscntl		/* get instr-side IRAM config */
	mfdcr	r4, ocmdscntl		/* get data-side IRAM config */
	and	r3, r3, r0		/* disable data-side IRAM */
	and	r4, r4, r0		/* disable data-side IRAM */
	mtdcr	ocmiscntl, r3		/* set instr-side IRAM config */
	mtdcr	ocmdscntl, r4		/* set data-side IRAM config */
	isync

	lis	r3,CONFIG_SYS_OCM_DATA_ADDR@h	/* OCM location */
	ori	r3,r3,CONFIG_SYS_OCM_DATA_ADDR@l
	mtdcr	ocmdsarc, r3
	addis	r4, 0, 0xC000		/* OCM data area enabled */
	mtdcr	ocmdscntl, r4
	isync


	/*----------------------------------------------------------------------- */
	/* Setup temporary stack in DCACHE or OCM if needed for SDRAM SPD. */
	/*----------------------------------------------------------------------- */
	/*
	 * Stack in OCM.
	 */

	/* Set up Stack at top of OCM */
	lis	r1, (CONFIG_SYS_INIT_RAM_ADDR + CONFIG_SYS_INIT_SP_OFFSET)@h
	ori	r1, r1, (CONFIG_SYS_INIT_RAM_ADDR + CONFIG_SYS_INIT_SP_OFFSET)@l
#else /* CONFIG_SYS_TEMP_STACK_OCM */
	/* Set up stack in the linker script defined RAM area */
	lis	r1, STACK_TOP@h
	ori	r1, r1, STACK_TOP@l
#endif
	/* Set up a zeroized stack frame so that backtrace works right */
	li	r0, 0
	stwu	r0, -4(r1)
	stwu	r0, -4(r1)

	/*
	 * Set up a dummy frame to store reset vector as return address.
	 * this causes stack underflow to reset board.
	 */
	stwu	r1, -8(r1)		/* Save back chain and move SP */
	lis	r0, RESET_VECTOR@h	/* Address of reset vector */
	ori	r0, r0, RESET_VECTOR@l
	stwu	r1, -8(r1)		/* Save back chain and move SP */
	stw	r0, +12(r1)		/* Save return addr (underflow vect) */

	GET_GOT				/* initialize GOT access	*/

	/* NEVER RETURNS! */
	bl	cellMain
cellDead:
	b cellDead

/**************************************************************************/
/* PPC405EP specific stuff						  */
/**************************************************************************/
#ifdef CONFIG_405EP
ppc405ep_init:
	/*
	!-----------------------------------------------------------------------
	! Check to see if chip is in bypass mode.
	! If so, write stored CPC0_PLLMR0 and CPC0_PLLMR1 values and perform a
	! CPU reset   Otherwise, skip this step and keep going.
	! Note:	 Running BIOS in bypass mode is not supported since PLB speed
	!	 will not be fast enough for the SDRAM (min 66MHz)
	!-----------------------------------------------------------------------
	*/
	mfdcr	r5, CPC0_PLLMR1
	rlwinm	r4,r5,1,0x1		/* get system clock source (SSCS) */
	cmpi	cr0,0,r4,0x1

	beq    pll_done			/* if SSCS =b'1' then PLL has */
					/* already been set */
					/* and CPU has been reset */
					/* so skip to next section */

#ifdef CONFIG_TAIHU
	mfdcr	r4, CPC0_BOOT
	andi.	r5, r4, CPC0_BOOT_SEP@l
	bne	strap_1			/* serial eeprom present */
	addis	r5,0,CPLD_REG0_ADDR@h
	ori	r5,r5,CPLD_REG0_ADDR@l
	andi.	r5, r5, 0x10
	bne	_pci_66mhz
#endif /* CONFIG_TAIHU */

	addis	r3,0,PLLMR0_DEFAULT@h	/* PLLMR0 default value */
	ori	r3,r3,PLLMR0_DEFAULT@l	/* */
	addis	r4,0,PLLMR1_DEFAULT@h	/* PLLMR1 default value */
	ori	r4,r4,PLLMR1_DEFAULT@l	/* */

#ifdef CONFIG_TAIHU
	b	1f
_pci_66mhz:
	addis	r3,0,PLLMR0_DEFAULT_PCI66@h
	ori	r3,r3,PLLMR0_DEFAULT_PCI66@l
	addis	r4,0,PLLMR1_DEFAULT_PCI66@h
	ori	r4,r4,PLLMR1_DEFAULT_PCI66@l
	b	1f
strap_1:
	mfdcr	r3, CPC0_PLLMR0
	mfdcr	r4, CPC0_PLLMR1
#endif /* CONFIG_TAIHU */

1:
	b	pll_write		/* Write the CPC0_PLLMR with new value */

pll_done:
	/*
	!-----------------------------------------------------------------------
	! Clear Soft Reset Register
	! This is needed to enable PCI if not booting from serial EPROM
	!-----------------------------------------------------------------------
	*/
	addi	r3, 0, 0x0
	mtdcr	CPC0_SRR, r3

	addis	 r3,0,0x0010
	mtctr	r3
pci_wait:
	bdnz	pci_wait

	blr				/* return to main code */

/*
!-----------------------------------------------------------------------------
! Function:	pll_write
! Description:	Updates the value of the CPC0_PLLMR according to CMOS27E documentation
!		That is:
!			  1.  Pll is first disabled (de-activated by putting in bypass mode)
!			  2.  PLL is reset
!			  3.  Clock dividers are set while PLL is held in reset and bypassed
!			  4.  PLL Reset is cleared
!			  5.  Wait 100us for PLL to lock
!			  6.  A core reset is performed
! Input: r3 = Value to write to CPC0_PLLMR0
! Input: r4 = Value to write to CPC0_PLLMR1
! Output r3 = none
!-----------------------------------------------------------------------------
*/
pll_write:
	mfdcr  r5, CPC0_UCR
	andis. r5,r5,0xFFFF
	ori    r5,r5,0x0101		/* Stop the UART clocks */
	mtdcr  CPC0_UCR,r5		/* Before changing PLL */

	mfdcr  r5, CPC0_PLLMR1
	rlwinm r5,r5,0,0x7FFFFFFF	/* Disable PLL */
	mtdcr	CPC0_PLLMR1,r5
	oris   r5,r5,0x4000		/* Set PLL Reset */
	mtdcr	CPC0_PLLMR1,r5

	mtdcr	CPC0_PLLMR0,r3		/* Set clock dividers */
	rlwinm r5,r4,0,0x3FFFFFFF	/* Reset & Bypass new PLL dividers */
	oris   r5,r5,0x4000		/* Set PLL Reset */
	mtdcr	CPC0_PLLMR1,r5		/* Set clock dividers */
	rlwinm r5,r5,0,0xBFFFFFFF	/* Clear PLL Reset */
	mtdcr	CPC0_PLLMR1,r5

	/*
	! Wait min of 100us for PLL to lock.
	! See CMOS 27E databook for more info.
	! At 200MHz, that means waiting 20,000 instructions
	 */
	addi	r3,0,20000		/* 2000 = 0x4e20 */
	mtctr	r3
pll_wait:
	bdnz	pll_wait

	oris   r5,r5,0x8000		/* Enable PLL */
	mtdcr	CPC0_PLLMR1,r5		/* Engage */

	b pll_done 			/* In real hardware, we may go */
					/* below to reset, but not here */
	/*
	 * Reset CPU to guarantee timings are OK
	 * Not sure if this is needed...
	 */
	#addis r3,0,0x1000
	#mtspr SPRN_DBCR0,r3		/* This will cause a CPU core reset, and */
					/* execution will continue from the poweron */
					/* vector of 0xfffffffc */
#endif /* CONFIG_405EP */

.extern pCurrentTask
	/*----------------------------------------------------------------------- */

/*
 * Note: code which follows this uses cr0.eq (set if from kernel),
 * r20(new MSR), r21(trap frame), r22 (SRR0), and r23 (SRR1).
 */

/*
 * This code finishes saving the registers to the exception frame
 * and jumps to the appropriate handler for the exception.
 * Register r21 is pointer into trap frame, r1 has new stack pointer.
 */
transfer_to_handler:
	stw		r22,_NIP(r21)
	lis		r22,MSR_POW@h		/* clear POW bit */
	andc	r23,r23,r22			/* use normal power management */
	stw		r23,_MSR(r21)		/* MSC value when the exception returns */
	SAVE_GPR(7, r21)
	SAVE_4GPRS(8, r21)
	SAVE_8GPRS(12, r21)
	SAVE_8GPRS(24, r21)
	mflr	r23					/* hdlr/int_return addr immediately follows */
	andi.	r24,r23,0x3f00		/* get vector offset */
	stw		r24,TRAP(r21)		/* vector address, such as 0x1000 for PIT */
	li		r22,0
	stw		r22,RESULT(r21)		/* clear the sc return value */
	mtspr	SPRG2,r22			/* r1 is now kernel sp */
	lwz		r24,0(r23)			/* virtual address of hdlr */
	lwz		r23,4(r23)			/* where to go when done */
	mtspr	SRR0,r24			/* hdlr */
	mtspr	SRR1,r20			/* MSR_KERNEL with ME enabled */
	mtlr	r23					/* call hdlr and then return to int_return */
	SYNC						/* note r3 has address for pt_regs on stack */
	rfi							/* jump to handler, enable ME */

int_return:
	addi    r3,r1,STACK_FRAME_OVERHEAD
	lwz		r4,_MQ(r1)
	cmpwi	r4, 0
	beq 	goon_return
switch_stack:
	subi	r1,r4,STACK_FRAME_OVERHEAD
goon_return:
	mfmsr	r28		/* Disable interrupts */
	li		r4,0
	ori		r4,r4,MSR_EE	/* clear External Interrupt Enable */
	ori     r4,r4,MSR_DE	/* clear Debug Interrupts Enable - 4xx */
	andc	r28,r28,r4
	SYNC			/* Some chip revs need this... */
	mtmsr	r28
	SYNC
	lwz		r2,_CTR(r1)
	lwz		r0,_LINK(r1)
	mtctr	r2
	mtlr	r0
	lwz		r2,_XER(r1)
	lwz		r0,_CCR(r1)
	mtspr	XER,r2
	mtcrf	0xFF,r0
	REST_10GPRS(3, r1)
	REST_10GPRS(13, r1)
	REST_8GPRS(23, r1)
	REST_GPR(31, r1)
	lwz		r2,_NIP(r1)	/* Restore environment */
	lwz		r0,_MSR(r1)
	mtspr	SRR0,r2
	mtspr	SRR1,r0
	lwz		r0,GPR0(r1)
	lwz		r2,GPR2(r1)
	lwz		r1,GPR1(r1)
	SYNC
	rfi
	b		.		/* prevent prefetch past rfi */

crit_return:
	mfmsr	r28		/* Disable interrupts */
	li	r4,0
	ori	r4,r4,MSR_EE
	andc	r28,r28,r4
	SYNC			/* Some chip revs need this... */
	mtmsr	r28
	SYNC
	lwz	r2,_CTR(r1)
	lwz	r0,_LINK(r1)
	mtctr	r2
	mtlr	r0
	lwz	r2,_XER(r1)
	lwz	r0,_CCR(r1)
	mtspr	XER,r2
	mtcrf	0xFF,r0
	REST_10GPRS(3, r1)
	REST_10GPRS(13, r1)
	REST_8GPRS(23, r1)
	REST_GPR(31, r1)
	lwz	r2,_NIP(r1)	/* Restore environment */
	lwz	r0,_MSR(r1)
	mtspr	SPRN_CSRR0,r2
	mtspr	SPRN_CSRR1,r0
	lwz	r0,GPR0(r1)
	lwz	r2,GPR2(r1)
	lwz	r1,GPR1(r1)
	SYNC
	rfci


get_pvr:
	mfspr	r3, PVR
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 out16 */
/* Description:	 Output 16 bits */
/*------------------------------------------------------------------------------- */
out16:
	sth	r4,0x0000(r3)
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 out16r */
/* Description:	 Byte reverse and output 16 bits */
/*------------------------------------------------------------------------------- */
out16r:
	sthbrx	r4,r0,r3
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 out32r */
/* Description:	 Byte reverse and output 32 bits */
/*------------------------------------------------------------------------------- */
out32r:
	stwbrx	r4,r0,r3
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 in16 */
/* Description:	 Input 16 bits */
/*------------------------------------------------------------------------------- */
in16:
	lhz	r3,0x0000(r3)
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 in16r */
/* Description:	 Input 16 bits and byte reverse */
/*------------------------------------------------------------------------------- */
in16r:
	lhbrx	r3,r0,r3
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 in32r */
/* Description:	 Input 32 bits and byte reverse */
/*------------------------------------------------------------------------------- */
in32r:
	lwbrx	r3,r0,r3
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 in8 */
/* Description:	 Input 8 bits */
/*------------------------------------------------------------------------------- */
in8:
	lbz	r3,0x0000(r3)
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 out8 */
/* Description:	 Output 8 bits */
/*------------------------------------------------------------------------------- */
out8:
	stb	r4,0x0000(r3)
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 out32 */
/* Description:	 Output 32 bits */
/*------------------------------------------------------------------------------- */
out32:
	stw	r4,0x0000(r3)
	blr

/*------------------------------------------------------------------------------- */
/* Function:	 in32 */
/* Description:	 Input 32 bits */
/*------------------------------------------------------------------------------- */
in32:
	lwz	3,0x0000(3)
	blr
