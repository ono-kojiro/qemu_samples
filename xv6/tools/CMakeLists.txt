project(mkfs LANGUAGES C)

add_executable(${PROJECT_NAME}
  ${XV6_SOURCE_DIR}/mkfs.c
)

target_compile_options(${PROJECT_NAME} PRIVATE "-Werror")
target_compile_options(${PROJECT_NAME} PRIVATE "-Wall")
target_compile_options(${PROJECT_NAME} PRIVATE "-DBUILD_MKFS")


