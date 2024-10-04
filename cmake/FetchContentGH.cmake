cmake_minimum_required(VERSION 3.25)

include(FetchContent)

function (FetchContent_DeclareGH NAME)
  set(options TARBALL ZIPBALL)
  set(oneValueArgs REPOSITORY RELEASE_TAG TOKEN ASSET_NAME)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(ASSET_TYPE_DEFINED)
  set(ASSET_TYPE_HEADER)
  
  if (ARG_ASSET_NAME)
    message(DEBUG "Asset name provided: ${ARG_ASSET_NAME}")
    set(ASSET_TYPE_DEFINED TRUE)
    set(ASSET_TYPE_HEADER "Accept: application/octet-stream")
  endif ()

  if (ARG_ZIPBALL)
    message(DEBUG "zipball requested")
    if (ASSET_TYPE_DEFINED)
      message(FATAL_ERROR "Specifying multiple asset types is not allowed")
    endif ()
    set(ASSET_TYPE_DEFINED TRUE)
    set(ASSET_TYPE_HEADER "Accept: application/vnd.github+json")
  endif ()


  if ((NOT ASSET_TYPE_DEFINED) AND (NOT ARG_TARBALL))
    message(WARNING "No asset type provided. Defaulting to tarball")
    set(ARG_TARBALL TRUE)
  endif ()


  if (ARG_TARBALL)
    message(DEBUG "tarball requested")
    if (ASSET_TYPE_DEFINED)
      message(FATAL_ERROR "Specifying multiple asset types is not allowed")
    endif ()
    set(ASSET_TYPE_DEFINED TRUE)
    set(ASSET_TYPE_HEADER "Accept: application/vnd.github+json")

  endif ()

  if (NOT ASSET_TYPE_DEFINED)
    message(WARNING "No asset type provided. Defaulting to tarball")
    set(ARG_TARBALL TRUE)
    set(ASSET_TYPE_DEFINED TRUE)
  endif ()

  set(TOKEN ${ARG_TOKEN})
  set(AUTH_HEADER)
  if (NOT TOKEN)
    message(DEBUG "No token provided. Checking for environment variable GITHUB_PAT")
    if (NOT ENV{GITHUB_PAT})
      message(DEBUG "No token found.")
    endif ()
  endif ()

  if (TOKEN)
    set(AUTH_HEADER "Authorization: Bearer ${TOKEN}")
  endif ()

  string(CONCAT RELEASE_INFO_FILENAME ${ARG_REPOSITORY} "_" ${ARG_RELEASE_TAG} ".json")
  string(REGEX REPLACE "[\\/]" "_" RELEASE_INFO_FILENAME ${RELEASE_INFO_FILENAME})

  set(RELEASE_INFO_FILEPATH ${FetchContentGH_BINARY_DIR}/info/${RELEASE_INFO_FILENAME})
  message(DEBUG "Release Info file: ${RELEASE_INFO_FILEPATH}")
  if (NOT IS_READABLE ${RELEASE_INFO_FILEPATH})
    message(VERBOSE "Fetching release info")
    file(DOWNLOAD https://api.github.com/repos/${ARG_REPOSITORY}/releases/tags/${ARG_RELEASE_TAG}
         ${RELEASE_INFO_FILEPATH} HTTPHEADER "Accept: application/vnd.github+json"
         HTTPHEADER "${AUTH_HEADER}" HTTPHEADER "X-GitHub-Api-Version: 2022-11-28"
         STATUS RELEASE_INFO_STATUS
    )
    list(GET RELEASE_INFO_STATUS 0 RELEASE_INFO_ERROR_CODE)
    if(NOT (RELEASE_INFO_ERROR_CODE EQUAL 0))
      message(FATAL_ERROR "Failed to fetch release info: ${RELEASE_INFO_STATUS}")
    endif()
    endif ()

  file(READ ${RELEASE_INFO_FILEPATH} RELEASE_INFO)

  set(ASSET_URL)

  if (ARG_TARBALL)
    message(DEBUG "Looking for tarball URL")
    string(
      JSON
      ASSET_URL
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${RELEASE_INFO}"
      "tarball_url"
    )

    if (NOT ASSET_URL)
      message(FATAL_ERROR "No tarball URL found in release info")
    endif ()

    message(DEBUG "Found tarball URL: ${ASSET_URL}")

  endif ()

  if (ARG_ZIPBALL)
    message(DEBUG "Looking for zipball URL")
    string(
      JSON
      ASSET_URL
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${RELEASE_INFO}"
      "zipball_url"
    )

    if (NOT ASSET_URL)
      message(FATAL_ERROR "No tarball URL found in release info")
    endif ()

    message(DEBUG "Found tarball URL: ${ASSET_URL}")

  endif ()

  if (ARG_ASSET_NAME)
    string(
      JSON
      ASSETS
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${RELEASE_INFO}"
      "assets"
    )

    if (NOT ASSETS)
      message(FATAL_ERROR "No assets found in release info")
    endif ()

    string(JSON ASSETS_COUNT LENGTH ${ASSETS})
    message(DEBUG "Found ${ASSETS_COUNT} assets in ${ARG_REPOSITORY} ${ARG_RELEASE_TAG}")

    if (ASSETS_COUNT LESS_EQUAL 0)
      message(FATAL_ERROR "No assets found in release info")
    endif ()

    math(EXPR ASSETS_COUNT "${ASSETS_COUNT} - 1")

    set(FOUND_ASSET_NAME)
    set(FOUND_ASSET_URL)
    foreach (INDEX RANGE ${ASSETS_COUNT})
      string(JSON ASSET GET ${ASSETS} "${INDEX}")
      string(JSON ASSET_NAME GET "${ASSET}" "name")
      string(JSON ASSET_URL GET "${ASSET}" "url")
      if (${ASSET_NAME} MATCHES ${ARG_ASSET_NAME})
        list(APPEND FOUND_ASSET_NAME ${ASSET_NAME})
        list(APPEND FOUND_ASSET_URL ${ASSET_URL})
        message(DEBUG "match: ${ASSET_NAME} - ${ASSET_URL}")
      else ()
        message(DEBUG "no match: ${ASSET_NAME} - ${ASSET_URL}")
      endif ()
    endforeach ()

    list(LENGTH FOUND_ASSET_NAME FOUND_ASSET_COUNT)
    if (FOUND_ASSET_COUNT EQUAL 0)
      message(FATAL_ERROR "No matching asset found")
    endif ()

    if (FOUND_ASSET_COUNT GREATER 1)
      message(DEBUG "Multiple matching assets found. Looking for exact match")

      list(FIND FOUND_ASSET_NAME "${ARG_ASSET_NAME}" ASSET_INDEX)
      if (ASSET_INDEX EQUAL -1)
        list(TRANSFORM FOUND_ASSET_NAME PREPEND "\n- ")
        list(JOIN FOUND_ASSET_NAME "," ASSET_MSG)
        string(APPEND ASSET_MSG "\n")
        message(FATAL_ERROR "Multiple assets found with no exact match: ${ASSET_MSG}")
      else()
      message(DEBUG "Exact match found at index ${ASSET_INDEX}")
      list(GET  FOUND_ASSET_NAME ${ASSET_INDEX} FOUND_ASSET_NAME)
      list(GET  FOUND_ASSET_URL ${ASSET_INDEX} FOUND_ASSET_URL)

      endif ()
    endif()
    set(ASSET_URL ${FOUND_ASSET_URL})
  endif ()

  message(VERBOSE "Asset URL: ${ASSET_URL}")

  FetchContent_Declare(
    ${NAME} HTTP_HEADER "${ASSET_TYPE_HEADER}" "${AUTH_HEADER}" URL ${ASSET_URL}
    ${ARG_UNPARSED_ARGUMENTS}
  )

endfunction ()
