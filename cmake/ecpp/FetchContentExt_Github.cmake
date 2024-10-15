cmake_minimum_required(VERSION 3.25)
# FetchContentExt_DeclareGithub
#
# Validates user-provided arguments and sets necessary defaults for github fetch content
macro (_FetchContentExt_GithubValidate)
  string(REGEX REPLACE "^https://github.com/([^/]*)/(.*)$" "\\1;\\2" organization_repo ${url})
  list(GET organization_repo 0 organization)
  list(GET organization_repo 1 repository)
  unset(organization_repo)

  if (NOT arg_ASSET)
    set(arg_ASSET TARBALL)
  endif ()

  if (${arg_ASSET} STREQUAL "TARBALL" OR ${arg_ASSET} STREQUAL "tarball")
    set(asset_type tarball)
    set(asset_download_name "sources.tar.gz")
    set(asset_info_strategy tag_file)
    set(asset_json_key "tarball_url")
    set(asset_type_header "Accept: application/vnd.github+json")

  elseif (${arg_ASSET} STREQUAL "ZIPBALL" OR ${arg_ASSET} STREQUAL "zipball")
    set(asset_type zipball)
    set(asset_download_name "sources.zip")
    set(asset_info_strategy tag_file)
    set(asset_json_key "zipball_url")
    set(asset_type_header "Accept: application/vnd.github+json")

  else ()
    set(asset_type artifact)
    set(asset_download_name ${arg_ASSET})
    set(asset_info_strategy release_file)
    set(asset_json_key "name")
    set(asset_type_header "Accept: application/octet-stream")

  endif ()

  if (arg_GIT_TAG AND arg_GIT_RELEASE)
    message(FATAL_ERROR "Both GIT_TAG and GIT_RELEASE provided. Please provide only one.")
  endif ()

  if (asset_info_strategy STREQUAL release_file AND arg_GIT_TAG)
    message(FATAL_ERROR "GIT_TAG provided for artifact asset. Use GIT_RELEASE.")
  endif ()

  if (asset_info_strategy STREQUAL release_file AND NOT arg_GIT_RELEASE)
    set(arg_GIT_RELEASE latest)
  endif ()

  if (asset_info_strategy STREQUAL tag_file AND (NOT arg_GIT_TAG))
    set(asset_info_strategy release_file)
    if (NOT arg_GIT_RELEASE)
      set(arg_GIT_RELEASE latest)
    endif ()
  endif ()

  set(git_tag_release ${arg_GIT_TAG}${arg_GIT_RELEASE})

  if (arg_TOKEN)
    set(token_found_in argument)
  elseif (DEFINED ENV{GITHUB_TOKEN})
    set(token_found_in env.GITHUB_TOKEN)
    set(arg_TOKEN $ENV{GITHUB_TOKEN})
  elseif (DEFINED ENV{GH_TOKEN})
    set(token_found_in env.GH_TOKEN)
    set(arg_TOKEN $ENV{GH_TOKEN})
  elseif (DEFINED ENV{GITHUB_PAT})
    set(token_found_in env.GITHUB_PAT)
    set(arg_TOKEN $ENV{GITHUB_PAT})
  else ()
    set(token_found_in "none")
  endif ()

  if (arg_TOKEN)
    set(github_auth_header "Authorization: Bearer ${arg_TOKEN}")
  else ()
    set(github_auth_header "")
    if (NOT arg_NO_TOKEN)
      message(WARNING "No token found. If this is intentional, consider adding NO_TOKEN option."
                      "Be aware that Github limits unauthenticated requests to 60 per hour."
      )
    endif ()
  endif ()

  message(
    VERBOSE
    "Github Asset:
    repo: ${organization}/${repository},
    tag: ${git_tag_release},
    type: ${asset_type},
    name: ${asset_download_name},
    info_strategy: ${asset_info_strategy}
    using_token: ${token_found_in}"
  )
endmacro ()

function (_FetchContentExt_GithubGetReleaseinfo output_file organization repository auth_header)
  message(VERBOSE "Fetching release info for ${organization}/${repository}")
  file(DOWNLOAD https://api.github.com/repos/${organization}/${repository}/releases ${output_file}
       HTTPHEADER "Accept: application/vnd.github+json" HTTPHEADER "${auth_header}"
       HTTPHEADER "X-GitHub-Api-Version: 2022-11-28" STATUS download_status
  )

  list(GET download_status 0 status_code)
  list(GET download_status 1 status_msg)
  if (NOT status_code EQUAL 0)
    message(
      FATAL_ERROR
        "Fetching release info for ${organization}/${repository} failed with code ${status_code}: ${status_msg}"
    )
  endif ()

endfunction ()

function (_FetchContentExt_GithubGetTaginfo output_filepath organization repository auth_header)
  message(VERBOSE "Fetching tag info for ${organization}/${repository}")
  file(DOWNLOAD https://api.github.com/repos/${organization}/${repository}/tags ${output_filepath}
       HTTPHEADER "Accept: application/vnd.github+json" HTTPHEADER "${auth_header}"
       HTTPHEADER "X-GitHub-Api-Version: 2022-11-28" STATUS download_status
  )

  list(GET download_status 0 status_code)
  list(GET download_status 1 status_msg)
  if (NOT status_code EQUAL 0)
    message(
      FATAL_ERROR
        "Fetching tag info for ${organization}/${repository} failed with code ${status_code}: ${status_msg}"
    )
  endif ()
endfunction ()

function (_FetchContentExt_GithubFindJSONArray result array key value)
  string(JSON count ERROR_VARIABLE error LENGTH ${array})
  if (NOT count)
    set(count 0)
  endif ()

  if (count GREATER 0)
    math(EXPR count "${count} - 1")
  endif ()
  foreach (index RANGE ${count})
    string(JSON entry GET ${array} "${index}")
    string(JSON entry_value ERROR_VARIABLE json_error GET "${entry}" "${key}")
    # Catch the first entry when value is set to latest
    if (entry_value STREQUAL ${value} OR ${value} STREQUAL "latest")
      set(${result} ${entry} PARENT_SCOPE)
      break()
    endif ()
  endforeach ()
endfunction ()

# Declares a FetchContent target for a github repository asset
#
# FetchContentExt_DeclareGithub(name repository [GIT_TAG <tag>] [ASSET <asset>] [TOKEN <token>]
# [NO_TOKEN] [FETCH_INFO_ONCE] )
#
function (FetchContentExt_DeclareGithub name url)
  set(options NO_TOKEN FETCH_INFO_ONCE)
  set(single_value GIT_TAG GIT_RELEASE ASSET TOKEN DOWNLOAD_NAME)
  set(multi_value)

  cmake_parse_arguments(arg "${options}" "${single_value}" "${multi_value}" ${ARGN})

  _FetchContentExt_GithubValidate()

  if (asset_info_strategy STREQUAL tag_file)
    set(file ${FetchContentExt_BINARY_DIR}/info/${organization}_${repository}_taginfo.json)
    message(DEBUG "Tag Info file: ${file}")
    _FetchContentExt_GithubGetTaginfo(${file} ${organization} ${repository} "${github_auth_header}")

    file(READ ${file} taginfo_json)

    _FetchContentExt_GithubFindJSONArray(tag_info ${taginfo_json} "name" ${git_tag_release})

    string(JSON download_url ERROR_VARIABLE json_error GET "${tag_info}" ${asset_json_key})

  elseif (asset_info_strategy STREQUAL release_file)
    set(file ${FetchContentExt_BINARY_DIR}/info/${organization}_${repository}_releaseinfo.json)
    message(DEBUG "Release Info file: ${file}")
    _FetchContentExt_GithubGetReleaseinfo(
      ${file} ${organization} ${repository} "${github_auth_header}"
    )

    file(READ ${file} releaseinfo_json)
    _FetchContentExt_GithubFindJSONArray(
      release_json ${releaseinfo_json} "tag_name" ${git_tag_release}
    )
    if (asset_type STREQUAL artifact)
      string(JSON assets_json ERROR_VARIABLE json_error GET "${release_json}" assets)
      _FetchContentExt_GithubFindJSONArray(asset_json ${assets_json} "name" ${asset_download_name})
      string(JSON download_url ERROR_VARIABLE json_error GET "${asset_json}" url)

    else ()
      string(JSON download_url ERROR_VARIABLE json_error GET "${release_json}" ${asset_json_key})

    endif ()

    set(asset_json_key "assets_url")

  else ()
    message(FATAL_ERROR "No known asset info strategy")
  endif ()

  if (NOT download_url)
    message(FATAL_ERROR "No asset URL found")
  endif ()
  message(VERBOSE "Asset URL: ${download_url}")

  if (arg_DOWNLOAD_NAME)
    message(VERBOSE "Using provided download name - ${arg_DOWNLOAD_NAME}")
    set(asset_download_name ${arg_DOWNLOAD_NAME})
  endif ()

  FetchContent_Declare(
    ${name} HTTP_HEADER "${asset_type_header}" "${github_auth_header}" URL ${download_url}
    DOWNLOAD_NAME ${asset_download_name} ${arg_UNPARSED_ARGUMENTS}
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
