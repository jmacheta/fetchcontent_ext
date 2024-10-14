include(ecpp/FetchContentExt)

message("======================== MINIMAL EXAMPLE ========================")
FetchContentExt_Declare(
  static_vector_mvp GIT_REPOSITORY git@github.com:jmacheta/static_vector.git DOWNLOAD_NO_EXTRACT
                    TRUE
)
FetchContent_MakeAvailable(static_vector_mvp)
if (NOT EXISTS ${static_vector_mvp_SOURCE_DIR}/sources.tar.gz)
  message("Fetching static_vector_mvp failed")
endif ()

message("\n======================== IMPLICIT ASSET TYPE ========================")
FetchContentExt_Declare(
  json_tarball_implicit GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_implicit)
if (NOT EXISTS ${json_tarball_implicit_SOURCE_DIR}/sources.tar.gz)
  message("Fetching json_tarball_implicit failed")
endif ()

message("\n======================== EXPLICIT TARBALL ========================")
FetchContentExt_Declare(
  json_tarball_explicit GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 ASSET tarball
                                          DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_explicit)
if (NOT EXISTS ${json_tarball_explicit_SOURCE_DIR}/sources.tar.gz)
  message("Fetching json_tarball_explicit failed")
endif ()

message("\n======================== EXPLICIT ZIPBALL ========================")
FetchContentExt_Declare(
  json_zipball GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 ASSET zipball DOWNLOAD_NO_EXTRACT
                                 TRUE
)
FetchContent_MakeAvailable(json_zipball)
if (NOT EXISTS ${json_zipball_SOURCE_DIR}/sources.zip)
  message("Fetching json_zipball failed")
endif ()

message("\n======================== MANUAL ASSET ========================")
FetchContentExt_Declare(
  json_asset GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 ASSET include.zip DOWNLOAD_NO_EXTRACT
                               TRUE EXCLUDE_FROM_ALL FIND_PACKAGE_ARGS
)
FetchContent_MakeAvailable(json_asset)
if (NOT EXISTS ${json_asset_SOURCE_DIR}/include.zip)
  message("Fetching json_asset failed")
endif ()
