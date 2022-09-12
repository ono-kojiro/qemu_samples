project(bootblockother LANGUAGES ASM)

add_executable(${PROJECT_NAME}
  ${XV6_SOURCE_DIR}/entryother.S
)

target_compile_options(${PROJECT_NAME} PRIVATE "-fno-pic")
target_compile_options(${PROJECT_NAME} PRIVATE "-static")
target_compile_options(${PROJECT_NAME} PRIVATE "-fno-builtin")
target_compile_options(${PROJECT_NAME} PRIVATE "-fno-strict-aliasing")
target_compile_options(${PROJECT_NAME} PRIVATE "-O2")
target_compile_options(${PROJECT_NAME} PRIVATE "-Wall")
target_compile_options(${PROJECT_NAME} PRIVATE "-MD")
target_compile_options(${PROJECT_NAME} PRIVATE "-ggdb")
target_compile_options(${PROJECT_NAME} PRIVATE "-m32")
target_compile_options(${PROJECT_NAME} PRIVATE "-Werror")
target_compile_options(${PROJECT_NAME} PRIVATE "-fno-omit-frame-pointer")
target_compile_options(${PROJECT_NAME} PRIVATE "-fno-stack-protector")
#target_compile_options(${PROJECT_NAME} PRIVATE "-ffreestanding")
#target_compile_options(${PROJECT_NAME} PRIVATE "-fno-common")
#target_compile_options(${PROJECT_NAME} PRIVATE "-nostdlib")
#target_compile_options(${PROJECT_NAME} PRIVATE "-gdwarf-2")
#target_compile_options(${PROJECT_NAME} PRIVATE "-m64")
#target_compile_options(${PROJECT_NAME} PRIVATE "-DX64")
#target_compile_options(${PROJECT_NAME} PRIVATE "-mcmodel=kernel")
#target_compile_options(${PROJECT_NAME} PRIVATE "-mtls-direct-seg-refs")
#target_compile_options(${PROJECT_NAME} PRIVATE "-mno-red-zone")
#target_compile_options(${PROJECT_NAME} PRIVATE "-O0")
target_compile_options(${PROJECT_NAME} PRIVATE "-nostdinc")

target_include_directories(${PROJECT_NAME}
	PRIVATE "${XV6_SOURCE_DIR}/include"
	PRIVATE "${XV6_SOURCE_DIR}"
)

#target_link_options(${PROJECT_NAME} PRIVATE -m elf_x86_64)
#target_link_options(${PROJECT_NAME} PRIVATE -nodefaultlibs)
#target_link_options(${PROJECT_NAME} PRIVATE -N)
#target_link_options(${PROJECT_NAME} PRIVATE -e start)
#target_link_options(${PROJECT_NAME} PRIVATE -Ttext 0x7000)

set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_FLAGS
	"-m elf_i386 -nodefaultlibs -N -e start -Ttext 0x7000"
)



set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS) # remove -rdynamic option

set_target_properties(${PROJECT_NAME}
  PROPERTIES
	  OUTPUT_NAME ${PROJECT_NAME}
		SUFFIX ".elf"
)


add_custom_command(
	TARGET ${PROJECT_NAME}
	POST_BUILD
	COMMAND ${OBJCOPY} -S -O binary -j .text bootblockother.elf entryother
	COMMAND ${OBJDUMP} -S bootblockother.elf > entryother.asm
)

