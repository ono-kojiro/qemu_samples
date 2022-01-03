

project(cellos LANGUAGES C ASM)

# change asm compiler temporarily 
set(CMAKE_ASM_COMPILER ${CC})

set(C_SOURCES 
	${CELLOS_ROOT}/lib/cpu.c
	${CELLOS_ROOT}/lib/ctype.c
	${CELLOS_ROOT}/lib/extable.c
	${CELLOS_ROOT}/lib/interrupts.c
	${CELLOS_ROOT}/lib/malloc.c
	${CELLOS_ROOT}/lib/speed.c
	${CELLOS_ROOT}/lib/string.c
	${CELLOS_ROOT}/lib/time.c
	${CELLOS_ROOT}/lib/traps.c
	${CELLOS_ROOT}/lib/uic.c
	${CELLOS_ROOT}/lib/vsprintf.c
)

set(ASM_SOURCES
	${CELLOS_ROOT}/lib/cache.S
	${CELLOS_ROOT}/lib/dcr.S
	${CELLOS_ROOT}/lib/ppccache.S
	${CELLOS_ROOT}/lib/ppcstring.S
	${CELLOS_ROOT}/lib/ticks.S
)

set_source_files_properties(${ASM_SOURCES}
    PROPERTIES LANGUAGE C
)

add_library(${PROJECT_NAME}
    ${C_SOURCES}
    ${ASM_SOURCES}
)

set_source_files_properties(${C_SOURCES}
    PROPERTIES COMPILE_DEFINITIONS __KERNEL__
)

set_source_files_properties(${ASM_SOURCES}
    PROPERTIES COMPILE_DEFINITIONS __ASSEMBLY__
)

target_compile_definitions(${PROJECT_NAME}
	PUBLIC TEXT_BASE=0x0
)

# PUBLIC $<$<COMPILE_LANGUAGE:ASM>:__ASSEMBLY__>

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

set_source_files_properties(${C_SOURCES}
    PROPERTIES COMPILE_FLAGS -O2
)

set_source_files_properties(${ASM_SOURCES} PROPERTIES
    COMPILE_FLAGS -Xassembler
    COMPILE_FLAGS -m405
    COMPILE_FLAGS -mregnames
)

target_compile_options(${PROJECT_NAME}
	PUBLIC -Wall
	PUBLIC -g
	PUBLIC -fno-exceptions
	PUBLIC -fno-builtin
	PUBLIC -msoft-float
)

