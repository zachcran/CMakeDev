list(
    APPEND
    CMAKE_MODULE_PATH
    "/home/ryan/CLionProjects/CMakeTest"
    "${PROJECT_SOURCE_DIR}"
)
string(REGEX REPLACE ";" "\\\;" test_path "${CMAKE_MODULE_PATH}")
function(add_cmake_test)
    foreach(testi ${ARGN})
        set(full_path ${CMAKE_CURRENT_LIST_DIR}/${testi}.cmake)
        add_test(
            NAME "${testi}"
            COMMAND ${CMAKE_COMMAND}
            -DCMAKE_MODULE_PATH=${test_path}
            -P ${full_path}
        )
    endforeach()
endfunction()
add_cmake_test("subtract_time" "timer")
