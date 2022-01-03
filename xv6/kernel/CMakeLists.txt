project(kernel LANGUAGES C ASM)

set(BINARY_FILES "initcode entryother")

# change link command
set(CMAKE_LINKER ld)
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES> -b binary ${BINARY_FILES}")

add_custom_command(
  OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/vectors.S
  COMMAND perl ${XV6_SOURCE_DIR}/vectors.pl > ${CMAKE_CURRENT_BINARY_DIR}/vectors.S
	DEPENDS ${XV6_SOURCE_DIR}/vectors.pl
  COMMENT "generate vectors.S"
  VERBATIM
)

set(SOURCES
	${XV6_SOURCE_DIR}/entry.S
	${CMAKE_CURRENT_BINARY_DIR}/vectors.S
	${XV6_SOURCE_DIR}/swtch.S
	${XV6_SOURCE_DIR}/trapasm.S
	${XV6_SOURCE_DIR}/bio.c
	${XV6_SOURCE_DIR}/console.c
	${XV6_SOURCE_DIR}/exec.c
	${XV6_SOURCE_DIR}/file.c
	${XV6_SOURCE_DIR}/fs.c
	${XV6_SOURCE_DIR}/ide.c
	${XV6_SOURCE_DIR}/ioapic.c
	${XV6_SOURCE_DIR}/kalloc.c
	${XV6_SOURCE_DIR}/kbd.c
	${XV6_SOURCE_DIR}/lapic.c
	${XV6_SOURCE_DIR}/log.c
	${XV6_SOURCE_DIR}/main.c
	${XV6_SOURCE_DIR}/mp.c
	${XV6_SOURCE_DIR}/picirq.c
	${XV6_SOURCE_DIR}/pipe.c
	${XV6_SOURCE_DIR}/proc.c
 	${XV6_SOURCE_DIR}/spinlock.c
	${XV6_SOURCE_DIR}/string.c
	${XV6_SOURCE_DIR}/syscall.c
	${XV6_SOURCE_DIR}/sysfile.c
	${XV6_SOURCE_DIR}/sysproc.c
	${XV6_SOURCE_DIR}/trap.c
	${XV6_SOURCE_DIR}/uart.c
	${XV6_SOURCE_DIR}/vm.c
	${XV6_SOURCE_DIR}/sleeplock.c
)

if(ENABLE_NET)
# for xv6-net only
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/fs.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/printfmt.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/socket.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/e1000.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/pci.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/tcp.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/udp.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/ip.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/net.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/icmp.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/arp.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/ethernet.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/sysnet.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/syssocket.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/mt19937ar.c)
set(SOURCES ${SOURCES} ${XV6_SOURCE_DIR}/common.c)
endif()

add_executable(${PROJECT_NAME}
	${SOURCES}
)

# common
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-fno-pic")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-gdwarf-2")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-m64")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-DX64")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-mcmodel=kernel")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-mtls-direct-seg-refs")
#target_compile_options(${PROJECT_NAME} PRIVATE
#  "-mno-red-zone")

# asm only
#target_compile_options(${PROJECT_NAME}
#  PRIVATE $<$<COMPILE_LANGUAGE:ASM>:-Wa,-divide>
#)

# C only
target_compile_options(${PROJECT_NAME}
  PRIVATE $<$<COMPILE_LANGUAGE:ASM>:-m32>
  PRIVATE $<$<COMPILE_LANGUAGE:ASM>:-dwarf-2>
  PRIVATE $<$<COMPILE_LANGUAGE:ASM>:-Wa,-divide>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-pic>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-static>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-builtin>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-strict-aliasing>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-O2>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-Wall>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-MD>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-ggdb>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-m32>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-omit-frame-pointer>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-ffreestanding>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-common>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-nostdlib>
#	PRIVATE -gdwarf-2
#	PRIVATE -m64
#	PRIVATE -DX64
#	PRIVATE -mcmodel=kernel
#  PRIVATE -mtls-direct-seg-refs
#  PRIVATE -mno-red-zone
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-O0>
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-fno-stack-protector>
)

target_include_directories(${PROJECT_NAME}
	PRIVATE "${XV6_SOURCE_DIR}/include"
)

#target_link_options(${PROJECT_NAME} PRIVATE -m elf_x86_64)
#target_link_options(${PROJECT_NAME} PRIVATE -nodefaultlibs)
#target_link_options(${PROJECT_NAME} PRIVATE -T ${XV6_SOURCE_DIR}/kernel/kernel64.ld)

#target_link_libraries(${PROJECT_NAME}
#	INTERFACE "-m elf_i386 -nodefaultlibs -T ${XV6_SOURCE_DIR}/kernel/kernel64.ld"
#)

set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_FLAGS
	"-m elf_i386 -T ${XV6_SOURCE_DIR}/kernel.ld"
)

set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_LIBRARIES
	"-L/usr/lib/gcc-cross/i686-linux-gnu/7/ -lgcc"
)



set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS) # remove -rdynamic option

add_custom_command(TARGET ${PROJECT_NAME}
  PRE_BUILD
	COMMAND mkdir -p out
	COMMAND cp -f ../initcode/initcode .
	COMMAND cp -f ../bootblockother/entryother .
)

