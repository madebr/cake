separate_arguments(cflags NATIVE_COMMAND "${CMAKE_C_FLAGS}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E echo
  COMMAND "${CMAKE_C_COMPILER}"  ${cflags} -E -v -
  TIMEOUT 1
  RESULT_VARIABLE res
  OUTPUT_VARIABLE stdout
  ERROR_VARIABLE stdout
)
if(res)
  message(FATAL_ERROR "Failed to execute $CC -E -v")
endif()

string(REGEX REPLACE "[\r\n]" ";" lines "${stdout}")

set(text
    "/*\n * This file was generated reading the ouput of\n *\n * echo | ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -v -E - 2>&1\n *\n */\n\n"
)

foreach(line ${lines})
  string(STRIP line "${line}")
  if(line MATCHES "#include.*search starts here")
    set(in_include_search_group 1)
  elseif(line MATCHES "End of search list")
    set(in_include_search_group 0)
  elseif(in_include_search_group)
      string(APPEND text "#pragma dir \"${line}\"\n")
  endif()
endforeach()
string(APPEND text "\n")

file(WRITE "${OUT}" "${text}")
