cmake_minimum_required(VERSION 3.8)
project(union)
set(CMAKE_VERBOSE_MAKEFILE ON)

# Directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_JAVA_TARGET_OUTPUT_DIR   ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PROJECT_INCLUDE_DIRECTORY      ${CMAKE_CURRENT_SOURCE_DIR}/include)

# C Configuration
set(CMAKE_C_STANDARD 11)
# Don't include line numbers from the .lex and .yacc files in the final binaries
# Doing so breaks CLion debugging because CLion doesn't see them as C source files
add_definitions(-P)
set(SED_STRIP_LINE_DECLS 's/^\#line.*\$$//')

include_directories(${PROJECT_INCLUDE_DIRECTORY})

# Source Files

set(LEX_FILE      ${CMAKE_CURRENT_SOURCE_DIR}/union.lex)
set(LEX_C_SOURCE  ${CMAKE_CURRENT_SOURCE_DIR}/union.lex.c)
set(LEX_H         ${PROJECT_INCLUDE_DIRECTORY}/union.lex.h)
set(YACC_FILE     ${CMAKE_CURRENT_SOURCE_DIR}/union.yacc)
set(YACC_C_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/union.yacc.c)
set(YACC_H        ${PROJECT_INCLUDE_DIRECTORY}/union.yacc.h)

# The lexer

add_custom_target(unionLexHeader DEPENDS ${LEX_H})
add_custom_command(OUTPUT ${LEX_C_SOURCE} ${LEX_H}
        DEPENDS ${LEX_FILE}
        PRE_BUILD
        COMMAND flex ARGS -8 -d --header-file=${LEX_H} -o union.lex.c union.lex
        COMMAND sed ARGS -i -re ${SED_STRIP_LINE_DECLS} union.lex.c
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

# The parser

add_custom_target(unionYaccHeader DEPENDS ${YACC_H})
add_custom_command(OUTPUT ${YACC_C_SOURCE} ${YACC_H}
        DEPENDS ${YACC_FILE}
        PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${PROJECT_INCLUDE_DIRECTORY}"
        COMMAND bison ARGS -vt --debug --defines=${YACC_H} -o union.yacc.c union.yacc
        COMMAND sed ARGS -i -re ${SED_STRIP_LINE_DECLS} union.yacc.c
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

# The binary

add_executable(unionParser ${LEX_C_SOURCE} ${YACC_C_SOURCE})
target_compile_options(unionParser PRIVATE "-Wall" "-Werror" "-Wno-unused-function") # input and yyunput are unused
