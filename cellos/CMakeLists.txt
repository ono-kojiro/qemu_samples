cmake_minimum_required(VERSION 3.10)

set(CMAKE_VERBOSE_MAKEFILE ON)

#set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_NAME Generic)

project(cellos C)

#set(cross "powerpc-none-eabi")
#set(cross_version "10.2.0")
set(cross "powerpc-eabi")
set(cross_version "4.3.3")

find_program(CC "${cross}-gcc")
find_program(AS "${cross}-as")
find_program(LD "${cross}-ld")
find_program(OBJCOPY "${cross}-objcopy")

message(STATUS "CC is ${CC}")
message(STATUS "AS is ${AS}")
message(STATUS "LD is ${LD}")

get_filename_component(GCC_BIN_DIR ${CC} DIRECTORY)
set(LIBGCC_DIR "${GCC_BIN_DIR}")
string(APPEND LIBGCC_DIR "/../lib/gcc/${cross}/${cross_version}/nof")

set(CROSS_ROOT "${GCC_BIN_DIR}")
string(APPEND CROSS_ROOT "/../${cross}")
message(STATUS "CROSS_ROOT is ${CROSS_ROOT}")

set(CMAKE_C_COMPILER ${CC} CACHE STRING "${cross}-gcc" FORCE)
set(CMAKE_ASM_COMPILER ${AS} CACHE STRING "${cross}-as" FORCE)
set(CMAKE_LINKER ${LD} CACHE STRING "${cross}-ld" FORCE)

#set(CMAKE_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> -o <OBJECT> <SOURCE>")

set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> -o <TARGET>     <LINK_FLAGS> <OBJECTS> <LINK_LIBRARIES>")
set(CMAKE_ASM_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_ASM_LINK_FLAGS> -o <TARGET> <LINK_FLAGS> <OBJECTS> <LINK_LIBRARIES>")

set(CELLOS_ROOT ${CMAKE_SOURCE_DIR}/src)

add_subdirectory(driver driver)
add_subdirectory(kernel kernel)
add_subdirectory(cellos cellos)
add_subdirectory(startup startup)
add_subdirectory(bootrom bootrom)

