cmake_minimum_required(VERSION 3.0...3.5)
project(cake C)
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED 1)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

if(MSVC)
  add_definitions(-D_CRT_NONSTDC_NO_WARNINGS)
  add_compile_options(
    /wd4996     # Your code uses a function, class member, variable, or typedef that's marked deprecated.
    /wd4100     # unreferenced formal paramet
    /wd4068     # unknown pragma
  )
else()
  add_compile_options(-Wno-multichar -Wno-switch)
endif()
if(WIN32)
  add_definitions(-DWIN32)
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cake_sources.cmake")

set(CAKECONFIG_H)
if(NOT MSVC)
  set(d "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
  if(NOT d)
    set(d "${CMAKE_CURRENT_BINARY_DIR}")
  endif()
  set(CAKECONFIG_H "${d}/cakeconfig.h")
  add_custom_command(OUTPUT "${CAKECONFIG_H}"
    COMMAND "${CMAKE_COMMAND}"
      "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
      "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}"
      "-DOUT=${CAKECONFIG_H}"
      "-P" "${CMAKE_CURRENT_SOURCE_DIR}/cmake/extract-stdinc.cmake"
    DEPENDS "${CMAKE_C_COMPILER}" "${CMAKE_CURRENT_SOURCE_DIR}/cmake/extract-stdinc.cmake"
  )
endif()

add_executable(build build.c)
set_property(TARGET build PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
add_custom_target(run-build COMMAND build WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

add_executable(cake main.c ${CAKE_SOURCES} ${CAKE_HEADERS} ${CAKECONFIG_H})
target_compile_options(cake PRIVATE "-UTEST")
add_custom_target(regen-cakeconfig COMMAND cake -autoconfig WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

add_executable(cake_unittests main.c ${CAKE_SOURCES} ${CAKE_HEADERS})
target_compile_definitions(cake_unittests PRIVATE "TEST")

enable_testing()
add_test(NAME "unittest_all" COMMAND cake ${UNIT_TESTS_SOURCES} "-test-mode")
add_test(NAME cake_cake
  COMMAND cake -ownership=enable -Wstyle -fanalyzer -Wno-unused-parameter -Wno-unused-variable -sarif ${CAKE_SOURCES} ${CAKE_HEADERS}
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
)
add_test(NAME cake_unittests COMMAND cake_unittests)
set_property(TEST cake_cake cake_unittests PROPERTY TIMEOUT "10")
file(GLOB_RECURSE test_sources "../tests/unit-tests/*.c")
foreach(src ${test_sources})
  get_filename_component(name "${src}" NAME_WE)
  get_filename_component(dir "${src}" DIRECTORY)
  if(NOT dir MATCHES "(out|_Out)$")
    set(test_name "unittest_${name}")
    add_test(NAME "${test_name}" COMMAND cake "${src}" "-test-mode")
    set_property(TEST "${test_name}" PROPERTY TIMEOUT "5")
    if(dir MATCHES "fail$")
      set_property(TEST "${test_name}" PROPERTY WILL_FAIL "1")
    endif()
  endif()
endforeach()
file(GLOB_RECURSE test_sources "../tests/en-cpp-reference-c/*.c")
foreach(src ${test_sources})
  get_filename_component(name "${src}" NAME_WE)
  get_filename_component(dir "${src}" DIRECTORY)
  if(NOT dir MATCHES "(out|_Out)$")
    set(test_name "cpp_ref_${name}")
    add_test(NAME "${test_name}" COMMAND cake "${src}" "-test-mode")
    set_property(TEST "${test_name}" PROPERTY TIMEOUT "5")
    if(dir MATCHES "failing$")
      set_property(TEST "${test_name}" PROPERTY WILL_FAIL "1")
    endif()
  endif()
endforeach()
add_test(NAME "sqlite" COMMAND cake "${CMAKE_CURRENT_SOURCE_DIR}/../tests/sqlite/sqlite3.c" -DSQLITE_OMIT_SEH -fanalyzer)

option(BUILD_TOOLS "Build cake tools" ON)
if(BUILD_TOOLS)
  add_executable(amalgamator tools/amalgamator.c)
  add_custom_target(run-amalgamator ALL amalgamator ${CAKE_SOURCES} "-olib.c" WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  add_executable(maketest tools/maketest.c)
  add_custom_target(run-maketest maketest unit_test.c ${CAKE_SOURCES} WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  add_executable(hoedown ${HOEDOWN_SOURCES})

  set(html_docs )
  macro(generate_doc MARKDOWN OUTPUT)
    list(APPEND html_docs "${OUTPUT}")
    add_custom_command(OUTPUT ${OUTPUT}
      COMMAND "${CMAKE_COMMAND}" -E cat "${CMAKE_CURRENT_SOURCE_DIR}/html_header.txt"  ">${OUTPUT}"
      COMMAND hoedown --html-toc --toc-level 3  --autolink --fenced-code "${MARKDOWN}" ">>${OUTPUT}"
      COMMAND hoedown            --toc-level 3  --autolink --fenced-code "${MARKDOWN}" ">>${OUTPUT}"
      COMMAND "${CMAKE_COMMAND}" -E cat "${CMAKE_CURRENT_SOURCE_DIR}/html_tail.txt"    ">>${OUTPUT}"
      DEPENDS "${MARKDOWN}"  "${CMAKE_CURRENT_SOURCE_DIR}/html_tail.txt" "${CMAKE_CURRENT_SOURCE_DIR}/html_header.txt"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
  endmacro()
  generate_doc("${CMAKE_CURRENT_SOURCE_DIR}/../manual.md" "${CMAKE_CURRENT_SOURCE_DIR}/web/manual.html")
  generate_doc("${CMAKE_CURRENT_SOURCE_DIR}/../README.md" "${CMAKE_CURRENT_SOURCE_DIR}/web/index.html")
  generate_doc("${CMAKE_CURRENT_SOURCE_DIR}/../warnings.md" "${CMAKE_CURRENT_SOURCE_DIR}/web/warnings.html")
  generate_doc("${CMAKE_CURRENT_SOURCE_DIR}/../ownership.md" "${CMAKE_CURRENT_SOURCE_DIR}/web/ownership.html")
  add_custom_target(html ALL DEPENDS ${html_docs})

endif()
