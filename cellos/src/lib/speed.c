/*
 * (C) Copyright 2000-2008
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
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
#include <asm/ppc4xx.h>
#include <asm/processor.h>

DECLARE_GLOBAL_DATA_PTR;

#define ONE_BILLION        1000000000
#ifdef DEBUG
#define DEBUGF(fmt,args...) printf(fmt ,##args)
#else
#define DEBUGF(fmt,args...)
#endif

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))


void get_sys_info (sys_info_t * sysInfo)
{
	unsigned long pllmr0;
	unsigned long pllmr1;
	unsigned long sysClkPeriodPs = ONE_BILLION / (CONFIG_SYS_CLK_FREQ / 1000);
	unsigned long m;
	unsigned long pllmr0_ccdv;

	/*
	 * Read PLL Mode registers
	 */
	pllmr0 = mfdcr (cpc0_pllmr0);
	pllmr1 = mfdcr (cpc0_pllmr1);

	/*
	 * Determine forward divider A
	 */
	sysInfo->pllFwdDiv = 8 - ((pllmr1 & PLLMR1_FWDVA_MASK) >> 16);

	/*
	 * Determine forward divider B (should be equal to A)
	 */
	sysInfo->pllFwdDivB = 8 - ((pllmr1 & PLLMR1_FWDVB_MASK) >> 12);

	/*
	 * Determine FBK_DIV.
	 */
	sysInfo->pllFbkDiv = ((pllmr1 & PLLMR1_FBMUL_MASK) >> 20);
	if (sysInfo->pllFbkDiv == 0)
		sysInfo->pllFbkDiv = 16;

	/*
	 * Determine PLB_DIV.
	 */
	sysInfo->pllPlbDiv = ((pllmr0 & PLLMR0_CPU_TO_PLB_MASK) >> 16) + 1;

	/*
	 * Determine PCI_DIV.
	 */
	sysInfo->pllPciDiv = (pllmr0 & PLLMR0_PCI_TO_PLB_MASK) + 1;

	/*
	 * Determine EXTBUS_DIV.
	 */
	sysInfo->pllExtBusDiv = ((pllmr0 & PLLMR0_EXB_TO_PLB_MASK) >> 8) + 2;

	/*
	 * Determine OPB_DIV.
	 */
	sysInfo->pllOpbDiv = ((pllmr0 & PLLMR0_OPB_TO_PLB_MASK) >> 12) + 1;

	/*
	 * Determine the M factor
	 */
	m = sysInfo->pllFbkDiv * sysInfo->pllFwdDivB;

	/*
	 * Determine VCO clock frequency
	 */
	sysInfo->freqVCOHz = (1000000000000LL * (unsigned long long)m) /
		(unsigned long long)sysClkPeriodPs;

	/*
	 * Determine CPU clock frequency
	 */
	pllmr0_ccdv = ((pllmr0 & PLLMR0_CPU_DIV_MASK) >> 20) + 1;
	if (pllmr1 & PLLMR1_SSCS_MASK) {
		/*
		 * This is true if FWDVA == FWDVB:
		 * sysInfo->freqProcessor = (CONFIG_SYS_CLK_FREQ * sysInfo->pllFbkDiv)
		 *	/ pllmr0_ccdv;
		 */
		sysInfo->freqProcessor = (CONFIG_SYS_CLK_FREQ * sysInfo->pllFbkDiv * sysInfo->pllFwdDivB)
			/ sysInfo->pllFwdDiv / pllmr0_ccdv;
	} else {
		sysInfo->freqProcessor = CONFIG_SYS_CLK_FREQ / pllmr0_ccdv;
	}

	/*
	 * Determine PLB clock frequency
	 */
	sysInfo->freqPLB = sysInfo->freqProcessor / sysInfo->pllPlbDiv;

	sysInfo->freqEBC = sysInfo->freqPLB / sysInfo->pllExtBusDiv;

	sysInfo->freqOPB = sysInfo->freqPLB / sysInfo->pllOpbDiv;

	sysInfo->freqUART = sysInfo->freqProcessor * pllmr0_ccdv;
}


/********************************************
 * get_OPB_freq
 * return OPB bus freq in Hz
 *********************************************/
ulong get_OPB_freq (void)
{
	ulong val = 0;

	sys_info_t sys_info;

	get_sys_info (&sys_info);
	val = sys_info.freqPLB / sys_info.pllOpbDiv;

	return val;
}


/********************************************
 * get_PCI_freq
 * return PCI bus freq in Hz
 *********************************************/
ulong get_PCI_freq (void)
{
	ulong val;
	sys_info_t sys_info;

	get_sys_info (&sys_info);
	val = sys_info.freqPLB / sys_info.pllPciDiv;
	return val;
}

int get_clocks (void)
{
	sys_info_t sys_info;

	get_sys_info (&sys_info);
	gd->cpu_clk = sys_info.freqProcessor;
	gd->bus_clk = sys_info.freqPLB;

	return (0);
}


/********************************************
 * get_bus_freq
 * return PLB bus freq in Hz
 *********************************************/
ulong get_bus_freq (ulong dummy)
{
	ulong val;

	sys_info_t sys_info;

	get_sys_info (&sys_info);
	val = sys_info.freqPLB;

	return val;
}
