#include <asm/types.h>
#include <asm/byteorder.h>

#ifdef __GNUC__
__inline__ unsigned ld_le16(const volatile unsigned short *addr)
{
	unsigned val;

	__asm__ __volatile__ ("lhbrx %0,0,%1" : "=r" (val) : "r" (addr), "m" (*addr));
	return val;
}

__inline__ void st_le16(volatile unsigned short *addr, const unsigned val)
{
	__asm__ __volatile__ ("sthbrx %1,0,%2" : "=m" (*addr) : "r" (val), "r" (addr));
}

__inline__ unsigned ld_le32(const volatile unsigned *addr)
{
	unsigned val;

	__asm__ __volatile__ ("lwbrx %0,0,%1" : "=r" (val) : "r" (addr), "m" (*addr));
	return val;
}

__inline__ void st_le32(volatile unsigned *addr, const unsigned val)
{
	__asm__ __volatile__ ("stwbrx %1,0,%2" : "=m" (*addr) : "r" (val), "r" (addr));
}
#endif

