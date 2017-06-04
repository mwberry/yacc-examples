cmake_minimum_required(VERSION 3.8)
project(java)
set(CMAKE_VERBOSE_MAKEFILE ON)

# Directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_JAVA_TARGET_OUTPUT_DIR   ${CMAKE_CURRENT_SOURCE_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PROJECT_INCLUDE_DIRECTORY      ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(D                              ${CMAKE_CURRENT_SOURCE_DIR}/com/mwberry/yacc/examples)

# Java Configuration
find_package(Java REQUIRED)
include(UseJava)
set(CMAKE_JAVA_COMPILE_FLAGS "${CMAKE_JAVA_COMPILE_FLAGS}"
        "-Werror" "-Xlint:all"
        "-Xlint:-cast" # Bison puts an ugly cast in where it is not needed
        "-Xlint:-fallthrough") # Bison even left a /* Fall Through */ comment

# C Configuration
set(CMAKE_C_STANDARD 11)
# Don't include line numbers from the .lex and .yacc files in the final binaries
# Doing so breaks CLion debugging because CLion doesn't see them as C source files
add_definitions(-P)
set(SED_STRIP_LINE_DECLS 's/^\#line.*\$$//')

include_directories(
        ${PROJECT_INCLUDE_DIRECTORY}
        /usr/lib/jvm/default/include/
        /usr/lib/jvm/default/include/linux)


# Source Files

set(LEX_FILE ${D}/java.lex)
set(LEX_C_SOURCE ${D}/java.lex.c)
set(LEX_H ${PROJECT_INCLUDE_DIRECTORY}/java.lex.h)
set(YACC_JAVA_FILE ${D}/java.yacc)
set(YACC_NATIVE_FILE ${D}/java.yacc.native)
set(YACC_C_SOURCE ${D}/java.yacc.c)
set(YACC_H ${PROJECT_INCLUDE_DIRECTORY}/java.yacc.h)
set(YACC_JAVA_SOURCE ${D}/YYParser.java)

# Sets of source files

set(YACC_NATIVE_SOURCES ${LEX_C_SOURCE} ${YACC_C_SOURCE})
set(YACC_JAVA_SOURCES ${YACC_JAVA_SOURCE})

# Native C based lexer, which includes JNI bindings

add_library(javalexer SHARED ${LEX_C_SOURCE} ${YACC_H})
target_compile_options(javalexer PRIVATE "-Wall" "-Werror" "-Wno-unused-function") # input and yyunput are unused
add_custom_target(lexHeader DEPENDS ${LEX_H})

add_custom_command(OUTPUT ${LEX_C_SOURCE} ${LEX_H}
        DEPENDS ${LEX_FILE}
        PRE_BUILD
        COMMAND flex ARGS -8 -d --header-file=${LEX_H} -o java.lex.c java.lex
        COMMAND sed ARGS -i -re ${SED_STRIP_LINE_DECLS} java.lex.c
        WORKING_DIRECTORY ${D})


# Native C based implementation of the parser

add_executable(nativeparser ${YACC_NATIVE_SOURCES} ${LEX_H})
target_compile_options(nativeparser PRIVATE "-Wall" "-Werror" "-Wno-unused-function") # input and yyunput are unused
add_custom_target(yaccHeader DEPENDS ${YACC_H})

add_custom_command(OUTPUT ${YACC_C_SOURCE} ${YACC_H}
        DEPENDS ${YACC_NATIVE_FILE}
        PRE_BUILD
        COMMAND bison ARGS -vt --debug --defines=${YACC_H} -o java.yacc.c java.yacc.native
        COMMAND sed ARGS -i -re ${SED_STRIP_LINE_DECLS} java.yacc.c
        WORKING_DIRECTORY ${D})


# Hybrid Java/JNI implementation of the parser

add_jar(javaparser ${YACC_JAVA_SOURCE})
add_dependencies(javaparser javalexer)

add_custom_command(OUTPUT ${YACC_JAVA_SOURCE}
        DEPENDS ${YACC_JAVA_FILE}
        PRE_BUILD
        COMMAND bison ARGS -vt --debug --language=Java -o YYParser.java java.yacc
        WORKING_DIRECTORY ${D})