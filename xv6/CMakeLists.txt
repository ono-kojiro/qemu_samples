cmake_minimum_required(VERSION 3.10)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

set(CMAKE_SYSTEM_NAME Generic)

set(XV6_SOURCE_DIR "${CMAKE_SOURCE_DIR}/xv6-net")
#set(XV6_SOURCE_DIR "${CMAKE_SOURCE_DIR}/xv6-public")

set(ENABLE_NET ON)

set(OBJCOPY objcopy)
set(OBJDUMP objdump)


set(TARGET "x86_64-linux-gnu-")
set(CMAKE_C_COMPILER "${TARGET}gcc")

project(xv6_cmake LANGUAGES C ASM)

set(CMAKE_LINKER "${TARGET}ld")
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS>")
set(CMAKE_ASM_LINK_EXECUTABLE "<CMAKE_LINKER> <LINK_FLAGS> -o <TARGET> <OBJECTS>")

add_subdirectory(bootblock ${CMAKE_CURRENT_BINARY_DIR}/bootblock)
add_subdirectory(bootblockother ${CMAKE_CURRENT_BINARY_DIR}/bootblockother)
add_subdirectory(initcode  ${CMAKE_CURRENT_BINARY_DIR}/initcode)
add_subdirectory(kernel    ${CMAKE_CURRENT_BINARY_DIR}/kernel)
add_subdirectory(tools     ${CMAKE_CURRENT_BINARY_DIR}/tools)
add_subdirectory(user      ${CMAKE_CURRENT_BINARY_DIR}/user)
add_subdirectory(tests     ${CMAKE_CURRENT_BINARY_DIR}/tests)

