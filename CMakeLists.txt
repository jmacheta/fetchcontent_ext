cmake_minimum_required(VERSION 3.25)

project(FetchContentExt VERSION 1.0.0 LANGUAGES NONE)

option(FetchContentExt_EXAMPLES "Configure Examples" ${PROJECT_IS_TOP_LEVEL})

# Extend the module path to make our Modules available
set(EXTENDED_MODULE_PATH ${CMAKE_MODULE_PATH};${CMAKE_CURRENT_LIST_DIR}/cmake)
list(REMOVE_DUPLICATES EXTENDED_MODULE_PATH)
set(CMAKE_MODULE_PATH ${EXTENDED_MODULE_PATH} CACHE INTERNAL "" FORCE)

if (FetchContentExt_EXAMPLES)
  add_subdirectory(examples EXCLUDE_FROM_ALL)
endif ()
