cmake_minimum_required(VERSION 3.8)
project(yacc-examples)
#set(CMAKE_VERBOSE_MAKEFILE ON)

# A simple lexer/parser that communicate via a union and global variables
add_subdirectory(union)

# A more mature example that eschews globals for stateful structures
add_subdirectory(reentrant)

# A more flexible example that doesn't require all the input to be availabile at once
add_subdirectory(push)

