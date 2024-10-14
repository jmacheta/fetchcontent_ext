cmake_minimum_required(VERSION 3.25)

include(FetchContent)

# FetchContentExt_DeclareGithub
#
# Validates user-provided arguments and sets necessary defaults for github fetch content
macro (_FetchContentExt_DeclareGithubValidate)
  string(REGEX REPLACE "^https://github.com/([^/]*)/(.*)$" "\\1;\\2" organization_repo ${url})
  list(GET organization_repo 0 organization)
  list(GET organization_repo 1 repository)
  unset(organization_repo)
  message(VERBOSE "organization: ${organization}, repository: ${repository}")

  if (NOT arg_GIT_TAG)
    message(VERBOSE "No tag provided. Assuming to latest")
    set(arg_GIT_TAG latest)
  endif ()

  set(git_tag "${arg_GIT_TAG}")
  message(DEBUG "git_tag: ${git_tag}")

  if (NOT arg_ASSET)
    message(VERBOSE "No asset name provided. Assuming tarball")
    set(arg_ASSET tarball)
  endif ()

  if (${arg_ASSET} STREQUAL "TARBALL")
    set(asset tarball)
  elseif (${arg_ASSET} STREQUAL "ZIPBALL")
    set(asset zipball)
  else ()
    set(asset "${arg_ASSET}")
  endif ()

  message(DEBUG "asset: ${asset}")

  if (NOT arg_TOKEN)
    message(DEBUG "No TOKEN. Checking Environment Variables")
    if (DEFINED ENV{GITHUB_TOKEN})
      message(DEBUG "Enviroment variable GITHUB_TOKEN found")
      set(arg_TOKEN $ENV{GITHUB_TOKEN})
    elseif (DEFINED ENV{GH_TOKEN})
      message(DEBUG "Enviroment variable GH_TOKEN found")
      set(arg_TOKEN $ENV{GH_TOKEN})
    elseif (DEFINED ENV{GITHUB_PAT})
      message(DEBUG "Enviroment variable GITHUB_PAT found")
      set(arg_TOKEN $ENV{GITHUB_PAT})
    endif ()
  endif ()

  if (arg_TOKEN)
    message(DEBUG "TOKEN found")
    set(github_auth_header "Authorization: Bearer ${arg_TOKEN}")
  else ()
    set(github_auth_header "")
    message(DEBUG "TOKEN not found")

    if (NOT arg_NO_TOKEN)
      message(WARNING "No token found. If this is intentional, consider adding NO_TOKEN option."
                      "Be aware that Github limits unauthenticated requests to 60 per hour."
      )
    endif ()
  endif ()
endmacro ()

# Declares a FetchContent target for a github repository asset
#
# FetchContentExt_DeclareGithub(name repository [GIT_TAG <tag>] [ASSET <asset>] [TOKEN <token>]
# [NO_TOKEN] [FETCH_INFO_ONCE] )
#
function (FetchContentExt_DeclareGithub name url)
  set(options NO_TOKEN FETCH_INFO_ONCE)
  set(single_value GIT_TAG ASSET TOKEN DOWNLOAD_NAME)
  set(multi_value)

  cmake_parse_arguments(arg "${options}" "${single_value}" "${multi_value}" ${ARGN})

  _FetchContentExt_DeclareGithubValidate()

  string(
    CONCAT release_info_filename
           ${organization}
           "_"
           ${repository}
           "_"
           ${git_tag}
           ".json"
  )

  set(release_info_filepath ${FetchContentExt_BINARY_DIR}/info/${release_info_filename})
  message(DEBUG "Release Info file: ${release_info_filepath}")

  if (NOT EXISTS ${release_info_filepath})
    set(release_info_size 0)
  else ()
    file(SIZE ${release_info_filepath} release_info_size)
  endif ()
  if (release_info_size EQUAL 0)
    message(DEBUG "No cached release info found")
    set(fetch_release_info TRUE)
  elseif (arg_FETCH_INFO_ONCE)
    message(DEBUG "FETCH_INFO_ONCE provided. Not fetching info again")
  endif ()

  if (NOT fetch_release_info)
    message(DEBUG
            "Fetching release info for ${organization}/${repository}@${git_tag} is not required"
    )
  else ()
    message(VERBOSE "Fetching release info for ${organization}/${repository}@${git_tag}")
    if ("${git_tag}" STREQUAL "latest")
      set(tag_string "latest")
    else ()
      set(tag_string "tags/${git_tag}")
    endif ()

    file(
      DOWNLOAD https://api.github.com/repos/${organization}/${repository}/releases/${tag_string}
      ${release_info_filepath}
      HTTPHEADER "Accept: application/vnd.github+json"
      HTTPHEADER "${github_auth_header}"
      HTTPHEADER "X-GitHub-Api-Version: 2022-11-28"
      STATUS release_info_fetch_status
    )

    list(GET release_info_fetch_status 0 release_info_fetch_error_code)
    list(GET release_info_fetch_status 1 release_info_fetch_error_msg)
    if (NOT (release_info_fetch_error_code EQUAL 0))
      message(
        FATAL_ERROR
          "Fetching release info for ${organization}/${repository}@${git_tag} failed with code ${release_info_fetch_error_code}: ${release_info_fetch_error_msg}"
      )
    endif ()

  endif ()

  file(READ ${release_info_filepath} release_info)

  if (asset STREQUAL "tarball")
    set(asset_type_header "Accept: application/vnd.github+json")
    set(asset_name "sources.tar.gz")

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
  elseif (asset STREQUAL "zipball")
    set(asset_type_header "Accept: application/vnd.github+json")
    set(asset_name "sources.zip")
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
  else ()
    set(asset_type_header "Accept: application/octet-stream")
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

    string(JSON json_assets_count LENGTH ${json_assets})
    message(DEBUG "Found ${json_assets_count} assets in ${repository} ${github_tag}")

    if (json_assets_count LESS_EQUAL 0)
      message(FATAL_ERROR "No assets found in release info")
    endif ()

    math(EXPR json_assets_count "${json_assets_count} - 1")

    foreach (index RANGE ${json_assets_count})
      string(JSON current_asset GET ${json_assets} "${index}")
      string(JSON current_asset_name GET "${current_asset}" "name")
      string(JSON current_asset_url GET "${current_asset}" "url")

      if (${current_asset_name} MATCHES ${asset})
        message(DEBUG "match: ${current_asset_name} - ${current_asset_url}")

        list(APPEND matching_asset_name ${current_asset_name})
        list(APPEND matching_asset_url ${current_asset_url})
      else ()
        message(DEBUG "no match: ${current_asset_name} - ${current_asset_url}")
      endif ()

    endforeach ()

    list(LENGTH matching_asset_name matching_asset_count)
    message(DEBUG "Found ${matching_asset_count} matching assets")

    if (matching_asset_count EQUAL 0)
      message(FATAL_ERROR "No matching asset found")
    endif ()

    if (matching_asset_count GREATER 1)
      message(DEBUG "Multiple matching assets found. Looking for exact match")

      list(FIND matching_asset_name "${asset}" asset_index)
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

    set(asset_name ${matching_asset_name})
    set(asset_url ${matching_asset_url})

  endif ()

  message(VERBOSE "Asset URL: ${asset_url}")

  if (arg_DOWNLOAD_NAME)
    message(VERBOSE "Using provided download name - ${arg_DOWNLOAD_NAME}")
    set(asset_name ${arg_DOWNLOAD_NAME})
  endif ()

  FetchContent_Declare(
    ${name} HTTP_HEADER "${asset_type_header}" "${github_auth_header}" URL ${asset_url}
    DOWNLOAD_NAME ${asset_name} ${arg_UNPARSED_ARGUMENTS}
  )

endfunction ()

# Detects the repository provider based on the user-provided arguments:
#
# Checks using GITHUB_REPOSITORY, GIT_REPOSITORY, and URL If succesful, populates the url and
# repo_type variables
#
macro (_FetchContentExt_DetectType)
  if (arg_GITHUB_REPOSITORY)
    set(url "https://github.com/${arg_GITHUB_REPOSITORY}")
    set(repo_type "github")

  elseif (arg_GIT_REPOSITORY)
    if (arg_GIT_REPOSITORY MATCHES "^.*github.com")
      set(repo_type "github")
      string(REGEX REPLACE "^.*github.com[:/](.*).git$" "https://github.com/\\1" url
                           "${arg_GIT_REPOSITORY}"
      )

    endif ()
  elseif (arg_URL)
    if (arg_URL MATCHES "^.*//github.com")
      set(repo_type "github")
      set(url "${arg_URL}")
    endif ()
  endif ()

  message(VERBOSE "Repository type: '${repo_type}', url: ${url}")
endmacro ()

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
