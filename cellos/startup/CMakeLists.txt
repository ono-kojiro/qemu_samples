project(startup LANGUAGES ASM C)

set(CMAKE_ASM_COMPILER ${CC})

set(LDSCRIPT ${CMAKE_CURRENT_BINARY_DIR}/cellos.ld)

set(ASM_SOURCES
    ${CELLOS_ROOT}/arch/ppc32/ppc405/cellStartup.S
)

add_executable(${PROJECT_NAME}
	${ASM_SOURCES}
)

set_source_files_properties(${ASM_SOURCES}
    PROPERTIES LANGUAGE C
)

set_source_files_properties(${ASM_SOURCES}
    PROPERTIES COMPILE_DEFINITIONS __ASSEMBLY__
)

target_compile_definitions(${PROJECT_NAME}
    PUBLIC -DTEXT_BASE=0x0
)

target_include_directories(${PROJECT_NAME}
    PUBLIC ${CELLOS_ROOT}/arch/ppc32/ppc405/include
    PUBLIC ${CELLOS_ROOT}/arch/ppc32/ppc405
    PUBLIC ${CELLOS_ROOT}/arch/ppc32/ppc405/platforms/taihu
    PUBLIC ${CELLOS_ROOT}/include
    PUBLIC ${CELLOS_ROOT}/kernel
    PUBLIC ${CELLOS_ROOT}/lib
    PUBLIC ${CELLOS_ROOT}/drivers
    PUBLIC ${CELLOS_ROOT}/drivers/serial
    PUBLIC ${CELLOS_ROOT}/tools
)

target_compile_options(${PROJECT_NAME}
	PUBLIC -Wall
	PUBLIC -g
	PUBLIC -fno-exceptions
	PUBLIC -fno-builtin
	PUBLIC -msoft-float
	PUBLIC -Xassembler
	PUBLIC -m405
	PUBLIC -mregnames
)
	
# cmake 3.11 has no target_link_options.
set(CMAKE_C_LINK_FLAGS "")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -g")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} --script=${LDSCRIPT}")
set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Ttext 0x0")
#set(CMAKE_ASM_LINK_FLAGS "${CMAKE_ASM_LINK_FLAGS} -lstdc++")

target_link_libraries(${PROJECT_NAME}
	PUBLIC -L${LIBGCC_DIR}
	PUBLIC -L${CROSS_ROOT}/lib
	PUBLIC ${CMAKE_BINARY_DIR}/kernel/libkernel.a
	PUBLIC ${CMAKE_BINARY_DIR}/driver/libdriver.a
	PUBLIC ${CMAKE_BINARY_DIR}/cellos/libcellos.a
	PUBLIC -lgcc
)

set_target_properties(startup PROPERTIES OUTPUT_NAME "cellos.elf")

add_custom_command(TARGET ${PROJECT_NAME}
	POST_BUILD
	COMMAND ${OBJCOPY} -O binary cellos.elf cellos.bin
)

set_directory_properties(
	PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES cellos.bin
)

add_custom_command(TARGET ${PROJECT_NAME}
	PRE_LINK
	COMMAND sh ${CMAKE_CURRENT_SOURCE_DIR}/update_ld_script.sh -o ${CMAKE_CURRENT_BINARY_DIR}/cellos.ld ${CMAKE_CURRENT_SOURCE_DIR}/cellos.ld.in
)

add_custom_target(qemu
	COMMAND qemu-system-ppc -L ../bootrom -nographic -M taihu
		-cpu 401100c4 -kernel cellos.bin
)

