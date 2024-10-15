cmake_minimum_required(VERSION 3.25)

include(FetchContent)
include(${CMAKE_CURRENT_LIST_DIR}/FetchContentExt_Github.cmake)
# Declares a FetchContent target for a repository asset
#
# FetchContentExt_DeclareGithub(name [GITHUB_REPOSITORY <organization/repo>] [GIT_REPOSITORY <url>]
# [URL <url>] [options]
#
# Currently supporting only Github assets. For options, refer to FetchContentExt_DeclareGithub
#
function (FetchContentExt_Declare name)
  set(options)
  set(single_value GITHUB_REPOSITORY GIT_REPOSITORY URL)
  message(VERBOSE "FetchContentExt_Declare parsing target info")
  list(APPEND CMAKE_MESSAGE_INDENT "  ")

  cmake_parse_arguments(arg "${options}" "${single_value}" "${multi_value}" ${ARGN})
  set(multi_value)
  _FetchContentExt_DetectType()

  if (repo_type STREQUAL "github")
    FetchContentExt_DeclareGithub(${name} ${url} ${arg_UNPARSED_ARGUMENTS})
  else ()
    message(FATAL_ERROR "No supported downloadable target")
  endif ()

  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction ()
