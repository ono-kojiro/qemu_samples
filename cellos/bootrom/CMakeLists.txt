project(bootrom LANGUAGES ASM)

set(CMAKE_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> -o <OBJECT> <SOURCE>")

set(LINKERSCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/bootrom.ld)

add_executable(${PROJECT_NAME}
	${CELLOS_ROOT}/arch/ppc32/ppc405/boot/bootrom.S
)

set(CMAKE_ASM_COMPILE_FLAGS "")

target_link_libraries(${PROJECT_NAME}
	PUBLIC --script=${LINKERSCRIPT}
)

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "bootrom.elf")

add_custom_command(TARGET ${PROJECT_NAME}
	POST_BUILD
	COMMAND ${OBJCOPY} -O binary bootrom.elf ppc405_rom.bin
)

