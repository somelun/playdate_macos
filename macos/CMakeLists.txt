# Generates an Xcode target that builds a fixed-size, non-resizable macOS window
# which renders your 1-bpp Playdate framebuffer (bytesPerRow=52, height=240) via Metal.
# Window size defaults to 800x480 (2x scale of 400x240). You can change SCALE below in code.

cmake_minimum_required(VERSION 3.15)

# --- macOS & Metal frameworks
find_library(COCOA_LIBRARY Cocoa REQUIRED)
find_library(METAL_LIBRARY Metal REQUIRED)
find_library(METALKIT_LIBRARY MetalKit REQUIRED)
find_library(QUARTZCORE_LIBRARY QuartzCore REQUIRED)

set(SOURCES
    main.m
    AppDelegate.h AppDelegate.m
    MetalRenderer.h MetalRenderer.m
    MetalShaders.metal
    ../shared/framebuffer.h
)

add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SOURCES})

# Ensure .metal compiles into a default library in Xcode
set_source_files_properties(MetalShaders.metal PROPERTIES LANGUAGE METAL)

# Objective‑C ARC for convenience
if (CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang")
    target_compile_options(${PROJECT_NAME} PRIVATE -fobjc-arc)
endif()

# You can expose preprocessor toggles here if you want (e.g., invert colors)
# target_compile_definitions(${PROJECT_NAME} PRIVATE PD_INVERT_PIXELS=1)

# Link frameworks
target_link_libraries(${PROJECT_NAME}
    ${COCOA_LIBRARY}
    ${METAL_LIBRARY}
    ${METALKIT_LIBRARY}
    ${QUARTZCORE_LIBRARY}
)

# Set bundle + Info.plist basics for a clean Xcode app target
set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE YES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.myplaydategame.macos
    MACOSX_BUNDLE_BUNDLE_NAME "MyPlaydateGame (Metal Dev)"
)
