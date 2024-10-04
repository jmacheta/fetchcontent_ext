cmake_minimum_required(VERSION 3.25)

include(FetchContent)

macro (_FetchContentExt_DeclareGithubValidate)

  if (NOT arg_GITHUB_TAG)
    message(VERBOSE "No tag provided. Assuming to latest")
    set(arg_GITHUB_TAG latest)
  endif ()

  set(github_tag "${arg_GITHUB_TAG}")
  message(DEBUG "github_tag: ${github_tag}")

  if (NOT arg_GITHUB_ASSET)
    message(VERBOSE "No asset name provided. Assuming tarball")
    set(arg_GITHUB_ASSET tarball)
  endif ()

  if (${arg_GITHUB_ASSET} STREQUAL "TARBALL")
    set(github_asset tarball)
  elseif (${arg_GITHUB_ASSET} STREQUAL "ZIPBALL")
    set(github_asset zipball)
  else ()
    set(github_asset "${arg_GITHUB_ASSET}")
  endif ()

  message(DEBUG "github_asset: ${github_asset}")

  if (NOT arg_GITHUB_TOKEN)
    message(VERBOSE "No GITHUB_TOKEN. Checking Environment Variables")
    if (DEFINED ENV{GITHUB_TOKEN})
      set(arg_GITHUB_TOKEN $ENV{GITHUB_TOKEN})
    elseif (DEFINED ENV{GH_TOKEN})
      set(arg_GITHUB_TOKEN $ENV{GH_TOKEN})
    elseif (DEFINED ENV{GITHUB_PAT})
      set(arg_GITHUB_TOKEN $ENV{GITHUB_PAT})
    endif ()
  endif ()

  if (arg_GITHUB_TOKEN)
    message(DEBUG "GITHUB_TOKEN found")
    set(github_auth_header "Authorization: Bearer ${arg_GITHUB_TOKEN}")
  else ()
    set(github_auth_header "")
    message(DEBUG "GITHUB_TOKEN not found")

    if (NOT arg_NO_TOKEN)
      message(WARNING "No token found. If this is intentional, consider adding NO_TOKEN option."
                      "Be aware that Github limits unauthenticated requests to 60 per hour."
      )
    endif ()

  endif ()
endmacro ()

function (FetchContentExt_DeclareGithub name repository)
  set(options NO_TOKEN)
  set(single_value GITHUB_REPOSITORY GITHUB_TAG GITHUB_ASSET GITHUB_TOKEN)
  set(multi_value)

  cmake_parse_arguments(arg "${options}" "${single_value}" "${multi_value}" ${ARGN})

  _FetchContentExt_DeclareGithubValidate()

  string(CONCAT release_info_filename ${repository} "_" ${github_tag} ".json")
  string(REGEX REPLACE "[\\/]" "_" release_info_filename ${release_info_filename})

  set(release_info_filepath ${FetchContentExt_BINARY_DIR}/info/${release_info_filename})
  message(DEBUG "Release Info file: ${release_info_filepath}")

  if (NOT IS_READABLE ${release_info_filepath})
    set(fetch_release_info TRUE)
  else ()
    file(SIZE ${release_info_filepath} release_info_size)
    if (release_info_size EQUAL 0)
      message(VERBOSE "Release info file is empty. Refetching")
      set(fetch_release_info TRUE)

    endif ()
  endif ()

  if (fetch_release_info)
    message(VERBOSE "Fetching release info for ${repository} ${github_tag}")
    if ("${github_tag}" STREQUAL "latest")
      set(tag_string "latest")
    else ()
      set(tag_string "tags/${github_tag}")
    endif ()

    file(
      DOWNLOAD https://api.github.com/repos/${repository}/releases/${tag_string}
      ${release_info_filepath}
      HTTPHEADER "Accept: application/vnd.github+json"
      HTTPHEADER "${github_auth_header}"
      HTTPHEADER "X-GitHub-Api-Version: 2022-11-28"
      STATUS release_info_fetch_status
    )

    list(GET release_info_fetch_status 0 release_info_fetch_error_code)
    if (NOT (release_info_fetch_error_code EQUAL 0))
      message(FATAL_ERROR "Failed to fetch release info: ${release_info_fetch_status}")
    endif ()

  endif ()

  file(READ ${release_info_filepath} release_info)

  if (github_asset STREQUAL "tarball")
    set(asset_type_header "Accept: application/vnd.github+json")

    message(DEBUG "Looking for tarball URL")
    string(
      JSON
      asset_url
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${release_info}"
      "tarball_url"
    )

    if (NOT asset_url)
      message(FATAL_ERROR "No tarball URL found in release info")
    endif ()

    message(VERBOSE "Found tarball URL: ${asset_url}")

  elseif (github_asset STREQUAL "zipball")
    set(asset_type_header "Accept: application/vnd.github+json")

    message(DEBUG "Looking for zipball URL")
    string(
      JSON
      asset_url
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${release_info}"
      "zipball_url"
    )

    if (NOT asset_url)
      message(FATAL_ERROR "No zipball URL found in release info")
    endif ()

    message(VERBOSE "Found zipball URL: ${asset_url}")

  else ()

    string(
      JSON
      json_assets
      ERROR_VARIABLE
      ASSET_PARSE_ERROR
      GET
      "${release_info}"
      "assets"
    )

    if (NOT json_assets)
      message(FATAL_ERROR "No assets found in release info")
    endif ()

    string(JSON asset_count LENGTH ${json_assets})
    message(DEBUG "Found ${asset_count} assets in ${repository} ${github_tag}")

    if (asset_count LESS_EQUAL 0)
      message(FATAL_ERROR "No assets found in release info")
    endif ()

    math(EXPR asset_count "${asset_count} - 1")

    foreach (index RANGE ${asset_count})
      string(JSON asset GET ${json_assets} "${index}")
      string(JSON asset_name GET "${asset}" "name")
      string(JSON asset_url GET "${asset}" "url")

      if (${asset_name} MATCHES ${github_asset})
        message(DEBUG "match: ${asset_name} - ${asset_url}")

        list(APPEND matching_asset_name ${asset_name})
        list(APPEND matching_asset_url ${asset_url})
      else ()
        message(DEBUG "no match: ${asset_name} - ${asset_url}")
      endif ()

    endforeach ()

    list(LENGTH matching_asset_name matching_asset_count)
    message(DEBUG "Found ${matching_asset_count} matching assets")

    if (matching_asset_count EQUAL 0)
      message(FATAL_ERROR "No matching asset found")
    endif ()

    if (matching_asset_count GREATER 1)
      message(DEBUG "Multiple matching assets found. Looking for exact match")

      list(FIND matching_asset_name "${github_asset}" asset_index)
      if (asset_index EQUAL -1)
        list(TRANSFORM matching_asset_name PREPEND "\n- ")
        list(JOIN matching_asset_name "," multiple_assets_error_msg)
        string(APPEND multiple_assets_error_msg "\n")
        message(
          FATAL_ERROR "Multiple assets found with no exact match: ${multiple_assets_error_msg}"
        )
      endif ()

      message(DEBUG "Exact match found at index ${asset_index}")
      list(GET matching_asset_name ${asset_index} matching_asset_name)
      list(GET matching_asset_url ${asset_index} matching_asset_url)

    endif ()

    set(asset_url ${matching_asset_url})

  endif ()

  message(VERBOSE "Asset URL: ${asset_url}")

  FetchContent_Declare(
    ${name} HTTP_HEADER "${asset_type_header}" "${github_auth_header}"
    URL ${asset_url} ${arg_UNPARSED_ARGUMENTS}
  )

endfunction ()

function (FetchContentExt_Declare name)
  set(options)
  set(single_value GITHUB_REPOSITORY)
  set(multi_value)

  cmake_parse_arguments(arg "${options}" "${single_value}" "${multi_value}" ${ARGN})

  if (arg_GITHUB_REPOSITORY)
    FetchContentExt_DeclareGithub(${name} ${arg_GITHUB_REPOSITORY} ${arg_UNPARSED_ARGUMENTS})
  else ()
    message(FATAL_ERROR "No supported downloadable target")
  endif ()

endfunction ()
