project(bootblock LANGUAGES C ASM)

add_executable(${PROJECT_NAME}
  ${XV6_SOURCE_DIR}/bootasm.S
  ${XV6_SOURCE_DIR}/bootmain.c
)

target_compile_options(${PROJECT_NAME}
  PRIVATE -fno-builtin
  PRIVATE -fno-pic
  PRIVATE -m32
  PRIVATE -nostdinc
  PRIVATE $<$<COMPILE_LANGUAGE:C>:-O>
)

target_include_directories(${PROJECT_NAME}
	PRIVATE "${XV6_SOURCE_DIR}/include"
)

#target_link_options(${PROJECT_NAME}
#  PRIVATE -m elf_i386
#  PRIVATE -nodefaultlibs
#  PRIVATE -N
#  PRIVATE -e start
#  PRIVATE -Ttext 0x7C00
#)

set_target_properties(${PROJECT_NAME}
	PROPERTIES LINK_FLAGS
	"-m elf_i386 -nodefaultlibs -N -e start -Ttext 0x7C00"
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
	COMMAND ${OBJDUMP} -S bootblock.elf > bootblock.asm
	COMMAND ${OBJCOPY} -S -O binary -j .text bootblock.elf bootblock
	COMMAND perl ${XV6_SOURCE_DIR}/sign.pl bootblock
)

set_property(TARGET ${PROJECT_NAME}
  APPEND PROPERTY 
	  ADDITIONAL_CLEAN_FILES bootblock.asm
	  ADDITIONAL_CLEAN_FILES bootblock.bin
	  ADDITIONAL_CLEAN_FILES bootblock
)

