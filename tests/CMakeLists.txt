# List of our unit tests
set(unit_tests subtract_time timer)

# ---------------- Shouldn't need to change anything below here ----------------

# Get and install CMakeTest
include(FetchContent)
FetchContent_Declare(
    cmake_test
    GIT_REPOSITORY https://github.com/CMakePP/CMakeTest
    GIT_TAG install
)
FetchContent_MakeAvailable(cmake_test)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR} "${cmake_test_SOURCE_DIR}")

include(cmake_test/cmake_test)
add_cmake_unit_tests("${CMAKE_MODULE_PATH}" ${unit_tests})

