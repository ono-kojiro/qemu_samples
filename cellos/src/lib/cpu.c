/*
 * (C) Copyright 2000-2007
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

/*
 * CPU specific code
 *
 * written or collected and sometimes rewritten by
 * Magnus Damm <damm@bitsmart.com>
 *
 * minor modifications by
 * Wolfgang Denk <wd@denx.de>
 */

#include <common.h>
#include <asm/watchdog.h>
#include <asm/cache.h>
#include <asm/ppc4xx.h>

DECLARE_GLOBAL_DATA_PTR;

/*
 * Get timebase clock frequency
 */
unsigned long get_tbclk (void)
{
	sys_info_t  sys_info;

	get_sys_info(&sys_info);
	return (sys_info.freqProcessor);
}


#if defined(CONFIG_WATCHDOG)
void watchdog_reset(void)
{
	int re_enable = disable_interrupts();
	reset_4xx_watchdog();
	if (re_enable) enable_interrupts();
}

void reset_4xx_watchdog(void)
{
	/*
	 * Clear TSR(WIS) bit
	 */
	mtspr(SPRN_TSR, 0x40000000);
}
#endif	/* CONFIG_WATCHDOG */
