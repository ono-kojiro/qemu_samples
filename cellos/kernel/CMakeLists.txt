project(kernel LANGUAGES C)

add_library(${PROJECT_NAME}
	${CELLOS_ROOT}/kernel/cellSched.c
	${CELLOS_ROOT}/kernel/cellMain.c
	byteorder.c
	bitops.c
	ptrace.c
)


target_compile_definitions(${PROJECT_NAME}
	PUBLIC __KERNEL__
)

target_compile_definitions(${PROJECT_NAME} PUBLIC -DTEXT_BASE=0x0)

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
	PUBLIC -O2
	PUBLIC -fno-exceptions
	PUBLIC -fno-builtin
	PUBLIC -msoft-float
)

