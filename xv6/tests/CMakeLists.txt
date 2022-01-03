project(tests)

set(CMAKE_SYSTEM_NAME Generic)

#set(IMAGE xv6.img)
#set(BOOTBLOCK ../bootblock/bootblock)
set(KERNEL ../kernel/kernel)
set(FS ../user/fs.img)

set(IMAGE ${CMAKE_BINARY_DIR}/xv6.img)
set(BOOTBLOCK ${CMAKE_BINARY_DIR}/bootblock/bootblock)

set(QEMU qemu-system-i386)

set(CPUS 2)
set(MEMSIZE 512)

set(QEMU_EXTRA "")

set(N1_PCAP ${CMAKE_SOURCE_DIR}/tests/n1.pcap)
#set(N1_PCAP n1.pcap)
set(N2_PCAP ${CMAKE_SOURCE_DIR}/tests/n2.pcap)
#set(N2_PCAP n2.pcap)

set(QEMUNET
	-netdev user,id=n1,hostfwd=udp::10007-:7,hostfwd=tcp::10007-:7)
set(QEMUNET ${QEMUNET} -device e1000,netdev=n1)
set(QEMUNET
	${QEMUNET} -object filter-dump,id=f1,netdev=n1,file=${N1_PCAP})
set(QEMUNET ${QEMUNET} -netdev tap,id=n2,ifname=tap0)
set(QEMUNET ${QEMUNET} -device e1000,netdev=n2)
set(QEMUNET
	${QEMUNET} -object filter-dump,id=f2,netdev=n2,file=${N2_PCAP})

add_custom_target(image ALL
	COMMAND ${CMAKE_COMMAND} -E remove -f ${IMAGE}
	COMMAND dd if=/dev/zero of=${IMAGE} count=10000
	COMMAND dd if=${BOOTBLOCK} of=${IMAGE} conv=notrunc
	COMMAND dd if=${KERNEL}    of=${IMAGE} seek=1 conv=notrunc
)

add_custom_target(tap
	COMMAND ip tuntap add mode tap name tap0
	COMMAND ip addr add 172.16.100.1/24 dev tap0
	COMMAND ip link set tap0 up
)

add_custom_target(qemu
	${QEMU} -nographic
		-drive file=${FS},index=1,media=disk,format=raw
		-drive file=${IMAGE},index=0,media=disk,format=raw
		-smp ${CPUS} -m ${MEMSIZE}
)

add_custom_target(qemu-net
	COMMAND ${QEMU} -nographic
		-drive file=${FS},index=1,media=disk,format=raw
		-drive file=${IMAGE},index=0,media=disk,format=raw
		-smp ${CPUS} -m ${MEMSIZE} ${QEMUNET}
)

