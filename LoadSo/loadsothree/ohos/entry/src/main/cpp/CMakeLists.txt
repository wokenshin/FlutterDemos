cmake_minimum_required(VERSION 3.10)

project(native LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(native)

# Build C++ library
add_library(addition SHARED
    native/addition.cpp
)

# Build C wrapper library
add_library(addition_c SHARED
    native/addition_c_wrapper.cpp
)

# Link C wrapper against C++ library
target_link_libraries(addition_c PRIVATE addition)

# Set output directory for libraries
set_target_properties(addition addition_c PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/libs
)
