cmake_minimum_required(VERSION 3.15)
project(MyPlaydateGame LANGUAGES C CXX OBJC OBJCXX)

# Option for target type
set(BUILD_TARGET "playdate" CACHE STRING "Choose build target: playdate or macos")
set_property(CACHE BUILD_TARGET PROPERTY STRINGS playdate macos)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(BUILD_TARGET STREQUAL "playdate")
    message(STATUS "Building for Playdate")
    add_subdirectory(playdate)
elseif(BUILD_TARGET STREQUAL "macos")
    message(STATUS "Building native macOS Metal dev version")
    add_subdirectory(macos)
else()
    message(FATAL_ERROR "Unknown build target: ${BUILD_TARGET}")
endif()
