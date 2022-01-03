/*
 * bitops.h: Bit string operations on the ppc
 */

#ifndef _PPC_BITOPS_H
#define _PPC_BITOPS_H

#include <config.h>
#include <asm/byteorder.h>

extern void set_bit(int nr, volatile void *addr);
extern void clear_bit(int nr, volatile void *addr);
extern void change_bit(int nr, volatile void *addr);
extern int test_and_set_bit(int nr, volatile void *addr);
extern int test_and_clear_bit(int nr, volatile void *addr);
extern int test_and_change_bit(int nr, volatile void *addr);

/*
 * Arguably these bit operations don't imply any memory barrier or
 * SMP ordering, but in fact a lot of drivers expect them to imply
 * both, since they do on x86 cpus.
 */
#ifdef CONFIG_SMP
#define SMP_WMB		"eieio\n"
#define SMP_MB		"\nsync"
#else
#define SMP_WMB
#define SMP_MB
#endif /* CONFIG_SMP */

#define __INLINE_BITOPS	1

#if __INLINE_BITOPS
/*
 * These used to be if'd out here because using : "cc" as a constraint
 * resulted in errors from egcs.  Things may be OK with gcc-2.95.
 */
extern __inline__ void set_bit(int nr, volatile void * addr);
extern __inline__ void clear_bit(int nr, volatile void *addr);
extern __inline__ void change_bit(int nr, volatile void *addr);
extern __inline__ int test_and_set_bit(int nr, volatile void *addr);
extern __inline__ int test_and_clear_bit(int nr, volatile void *addr);
extern __inline__ int test_and_change_bit(int nr, volatile void *addr);
#endif /* __INLINE_BITOPS */

extern __inline__ int test_bit(int nr, __const__ volatile void *addr);

/* Return the bit position of the most significant 1 bit in a word */
/* - the result is undefined when x == 0 */
extern __inline__ int __ilog2(unsigned int x);

extern __inline__ int ffz(unsigned int x);

#ifdef __KERNEL__

/*
 * ffs: find first bit set. This is defined the same way as
 * the libc and compiler builtin ffs routines, therefore
 * differs in spirit from the above ffz (man ffs).
 */
extern __inline__ int ffs(int x);

/*
 * hweightN: returns the hamming weight (i.e. the number
 * of bits set) of a N-bit word
 */

#define hweight32(x) generic_hweight32(x)
#define hweight16(x) generic_hweight16(x)
#define hweight8(x) generic_hweight8(x)

#endif /* __KERNEL__ */

/*
 * This implementation of find_{first,next}_zero_bit was stolen from
 * Linus' asm-alpha/bitops.h.
 */
#define find_first_zero_bit(addr, size) \
	find_next_zero_bit((addr), (size), 0)

extern __inline__ unsigned long find_next_zero_bit(void * addr,
	unsigned long size, unsigned long offset);
#define _EXT2_HAVE_ASM_BITOPS_

#ifdef __KERNEL__
/*
 * test_and_{set,clear}_bit guarantee atomicity without
 * disabling interrupts.
 */
#define ext2_set_bit(nr, addr)		test_and_set_bit((nr) ^ 0x18, addr)
#define ext2_clear_bit(nr, addr)	test_and_clear_bit((nr) ^ 0x18, addr)

#else
extern __inline__ int ext2_set_bit(int nr, void * addr);
extern __inline__ int ext2_clear_bit(int nr, void * addr);
#endif	/* __KERNEL__ */

extern __inline__ int ext2_test_bit(int nr, __const__ void * addr);

/*
 * This implementation of ext2_find_{first,next}_zero_bit was stolen from
 * Linus' asm-alpha/bitops.h and modified for a big-endian machine.
 */

#define ext2_find_first_zero_bit(addr, size) \
	ext2_find_next_zero_bit((addr), (size), 0)

/* Bitmap functions for the minix filesystem.  */
#define minix_test_and_set_bit(nr,addr) ext2_set_bit(nr,addr)
#define minix_set_bit(nr,addr) ((void)ext2_set_bit(nr,addr))
#define minix_test_and_clear_bit(nr,addr) ext2_clear_bit(nr,addr)
#define minix_test_bit(nr,addr) ext2_test_bit(nr,addr)
#define minix_find_first_zero_bit(addr,size) ext2_find_first_zero_bit(addr,size)

#endif /* _PPC_BITOPS_H */
