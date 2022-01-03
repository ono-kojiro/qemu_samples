/*
 * (C) Copyright 2002
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

#ifndef	__ASM_GBL_DATA_H
#define __ASM_GBL_DATA_H

#include <cellos/types.h>

#ifndef __ASSEMBLY__

typedef struct bd_info {
	unsigned long	bi_memstart;	/* start of DRAM memory */
	phys_size_t	bi_memsize;	/* size	 of DRAM memory in bytes */
	unsigned long	bi_flashstart;	/* start of FLASH memory */
	unsigned long	bi_flashsize;	/* size	 of FLASH memory */
	unsigned long	bi_flashoffset; /* reserved area for startup monitor */
	unsigned long	bi_sramstart;	/* start of SRAM memory */
	unsigned long	bi_sramsize;	/* size	 of SRAM memory */

	unsigned long	bi_bootflags;	/* boot / reboot flag (for LynxOS) */
	unsigned long	bi_ip_addr;	/* IP Address */
	unsigned char	bi_enetaddr[6];	/* OLD: see README.enetaddr */
	unsigned short	bi_ethspeed;	/* Ethernet speed in Mbps */
	unsigned long	bi_intfreq;	/* Internal Freq, in MHz */
	unsigned long	bi_busfreq;	/* Bus Freq, in MHz */

	unsigned long	bi_baudrate;	/* Console Baudrate */
#if defined(CONFIG_405)   || \
    defined(CONFIG_405GP) || \
    defined(CONFIG_405CR) || \
    defined(CONFIG_405EP) || \
    defined(CONFIG_405EZ) || \
    defined(CONFIG_405EX) || \
    defined(CONFIG_440)
	unsigned char	bi_s_version[4];	/* Version of this structure */
	unsigned char	bi_r_version[32];	/* Version of the ROM (AMCC) */
	unsigned int	bi_procfreq;	/* CPU (Internal) Freq, in Hz */
	unsigned int	bi_plb_busfreq;	/* PLB Bus speed, in Hz */
	unsigned int	bi_pci_busfreq;	/* PCI Bus speed, in Hz */
	unsigned char	bi_pci_enetaddr[6];	/* PCI Ethernet MAC address */
#endif

#ifdef CONFIG_HAS_ETH1
	unsigned char   bi_enet1addr[6];	/* OLD: see README.enetaddr */
#endif
#ifdef CONFIG_HAS_ETH2
	unsigned char	bi_enet2addr[6];	/* OLD: see README.enetaddr */
#endif
#ifdef CONFIG_HAS_ETH3
	unsigned char   bi_enet3addr[6];	/* OLD: see README.enetaddr */
#endif
#ifdef CONFIG_HAS_ETH4
	unsigned char   bi_enet4addr[6];	/* OLD: see README.enetaddr */
#endif
#ifdef CONFIG_HAS_ETH5
	unsigned char   bi_enet5addr[6];	/* OLD: see README.enetaddr */
#endif

#if defined(CONFIG_405GP) || defined(CONFIG_405EP) || \
    defined(CONFIG_405EZ) || defined(CONFIG_440GX) || \
    defined(CONFIG_440EP) || defined(CONFIG_440GR) || \
    defined(CONFIG_440EPX) || defined(CONFIG_440GRX) || \
    defined(CONFIG_460EX) || defined(CONFIG_460GT)
	unsigned int	bi_opbfreq;		/* OPB clock in Hz */
	int		bi_iic_fast[2];		/* Use fast i2c mode */
#endif

#if defined(CONFIG_4xx)
#if defined(CONFIG_440GX) || \
    defined(CONFIG_460EX) || defined(CONFIG_460GT)
	int		bi_phynum[4];           /* Determines phy mapping */
	int		bi_phymode[4];          /* Determines phy mode */
#elif defined(CONFIG_405EP) || defined(CONFIG_440)
	int		bi_phynum[2];           /* Determines phy mapping */
	int		bi_phymode[2];          /* Determines phy mode */
#else
	int		bi_phynum[1];           /* Determines phy mapping */
	int		bi_phymode[1];          /* Determines phy mode */
#endif
#endif /* defined(CONFIG_4xx) */
} bd_t;

/*
 * The following data structure is placed in some memory wich is
 * available very early after boot (like DPRAM on MPC8xx/MPC82xx, or
 * some locked parts of the data cache) to allow for a minimum set of
 * global variables during system initialization (until we have set
 * up the memory controller so that we can use RAM).
 *
 * Keep it *SMALL* and remember to set CONFIG_SYS_GBL_DATA_SIZE > sizeof(gd_t)
 */

typedef	struct	global_data {
	bd_t		*bd;
	unsigned long	flags;
	unsigned long	baudrate;
	unsigned long	cpu_clk;	/* CPU clock in Hz! */
	unsigned long	bus_clk;

	unsigned long   mem_clk;

	u32 core_clk;
	u32 enc_clk;
	u32 lbiu_clk;
	u32 lclk_clk;
	u32 pci_clk;

	phys_size_t	ram_size;	/* RAM size */
	unsigned long	reloc_off;	/* Relocation Offset */
	unsigned long	reset_status;	/* reset status register at boot	*/

	unsigned long	env_addr;	/* Address  of Environment struct	*/
	unsigned long	env_valid;	/* Checksum of Environment valid?	*/
	unsigned long	have_console;	/* serial_init() was called		*/

#if defined(CONFIG_4xx)
	u32  uart_clk;
#endif /* CONFIG_4xx */

	void		**jt;		/* jump table */
} gd_t;

/*
 * Global Data Flags
 */
#define	GD_FLG_RELOC	0x00001		/* Code was relocated to RAM		*/
#define	GD_FLG_DEVINIT	0x00002		/* Devices have been initialized	*/
#define	GD_FLG_SILENT	0x00004		/* Silent mode				*/
#define	GD_FLG_POSTFAIL	0x00008		/* Critical POST test failed		*/
#define	GD_FLG_POSTSTOP	0x00010		/* POST seqeunce aborted		*/
#define	GD_FLG_LOGINIT	0x00020		/* Log Buffer has been initialized	*/
#define GD_FLG_DISABLE_CONSOLE	0x00040		/* Disable console (in & out)	 */

#if 1
#define DECLARE_GLOBAL_DATA_PTR     register volatile gd_t *gd asm ("r2")
#else /* We could use plain global data, but the resulting code is bigger */
#define XTRN_DECLARE_GLOBAL_DATA_PTR	extern
#define DECLARE_GLOBAL_DATA_PTR     XTRN_DECLARE_GLOBAL_DATA_PTR \
				    gd_t *gd
#endif

#endif /* __ASSEMBLY__ */
#endif /* __ASM_GBL_DATA_H */
