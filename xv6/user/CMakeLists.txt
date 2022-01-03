#project(user LANGUAGES C ASM)

# change link command
set(CMAKE_LINKER ld)
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS>")

set(ULIB_C
  ${XV6_SOURCE_DIR}/ulib.c
	${XV6_SOURCE_DIR}/printf.c
	${XV6_SOURCE_DIR}/umalloc.c
)

set(ULIB_S ${XV6_SOURCE_DIR}/usys.S)

set(PROGS cat echo grep init kill ln ls mkdir rm sh
  stressfs usertests wc zombie
)

if(ENABLE_NET)
set(PROGS ${PROGS} ifconfig tcpechoserver udpechoserver)
endif()

function (target_common_options project)
target_compile_options(${project} PRIVATE "-fno-pic")
target_compile_options(${project} PRIVATE "-static")
target_compile_options(${project} PRIVATE "-fno-builtin")
target_compile_options(${project} PRIVATE "-fno-strict-aliasing")
target_compile_options(${project} PRIVATE "-O2")
target_compile_options(${project} PRIVATE "-Wall")
target_compile_options(${project} PRIVATE "-MD")
target_compile_options(${project} PRIVATE "-ggdb")
target_compile_options(${project} PRIVATE "-m32")
target_compile_options(${project} PRIVATE "-Werror")
target_compile_options(${project} PRIVATE "-fno-omit-frame-pointer")
target_compile_options(${project} PRIVATE "-fno-stack-protector")
#target_compile_options(${project} PRIVATE "-ffreestanding")
#target_compile_options(${project} PRIVATE "-fno-common")
#target_compile_options(${project} PRIVATE "-nostdlib")
#target_compile_options(${project} PRIVATE "-gdwarf-2")
#target_compile_options(${project} PRIVATE "-m64")
#target_compile_options(${project} PRIVATE "-DX64")
#target_compile_options(${project} PRIVATE "-mcmodel=kernel")
#target_compile_options(${project} PRIVATE "-mtls-direct-seg-refs")
#target_compile_options(${project} PRIVATE "-mno-red-zone")
#target_compile_options(${project} PRIVATE "-O0")
#target_compile_options(${project} PRIVATE "-nostdinc")

#target_link_options(${project} PRIVATE -m elf_x86_64)
#target_link_options(${project} PRIVATE -nodefaultlibs)
#target_link_options(${project} PRIVATE -N)
#target_link_options(${project} PRIVATE -e main)
#target_link_options(${project} PRIVATE -Ttext 0x0)

#target_link_libraries(${PROJECT_NAME}
#	INTERFACE "-m elf_i386 -nodefaultlibs -N -e main -Ttext 0x0"
#)
set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_FLAGS
	"-m elf_i386 -nodefaultlibs -N -e main -Ttext 0x0"
)



endfunction()

foreach(PROG ${PROGS})
  project(${PROG} LANGUAGES C ASM)
  add_executable(${PROJECT_NAME}
	  ${ULIB_C}
		${ULIB_S}
		${XV6_SOURCE_DIR}/${PROG}.c
	)

	target_include_directories(${PROJECT_NAME}
	  PRIVATE ${XV6_SOURCE_DIR}/include
  )

	target_common_options(${PROJECT_NAME})

endforeach()

project(forktest LANGUAGES C ASM)

add_executable(${PROJECT_NAME}
  ${XV6_SOURCE_DIR}/ulib.c 
  ${ULIB_S}
	${XV6_SOURCE_DIR}/forktest.c
)

set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_FLAGS
	"-m elf_i386 -N -e main -Ttext 0x0"
)

target_include_directories(${PROJECT_NAME}
  PRIVATE ${XV6_SOURCE_DIR}/include
)

target_common_options(${PROJECT_NAME})


### generate asm
foreach(PROG ${PROGS} forktest)
	add_custom_command(
		TARGET ${PROG}
		POST_BUILD
		COMMAND ${OBJDUMP} -S ${PROG} > ${PROG}.asm
	)
endforeach()

foreach(PROG ${PROGS} forktest)
	add_custom_command(
		TARGET ${PROG}
		POST_BUILD
		COMMAND ${OBJDUMP} -t ${PROG} | sed '1,/SYMBOL TABLE/d\; s/ .* / /\; /^$$/d' > ${PROG}.sym
	)
endforeach()

add_custom_target(fs ALL
	../tools/mkfs fs.img ${PROGS} forktest
	DEPENDS ${PROGS} forktest
)

