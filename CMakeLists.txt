cmake_minimum_required(VERSION 3.18)

project(testproj
    LANGUAGES C
)

add_executable(${PROJECT_NAME})

target_sources(${PROJECT_NAME} PRIVATE main.c)