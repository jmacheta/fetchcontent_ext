include(ecpp/FetchContentExt)

message("\n======================== MINIMAL EXAMPLE ========================")
# Download the tarball from latest release
FetchContentExt_Declare(
  static_vector_mvp GITHUB_REPOSITORY jmacheta/static_vector DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(static_vector_mvp)

message("\n======================== USING GIT_REPOSITORY ========================")
# Same as above, but uses syntax similar to FetchContent_Declare. Note that the underlying artifact
# is declared using resolved URL
FetchContentExt_Declare(
  static_vector_git_repo GIT_REPOSITORY https://github.com/jmacheta/static_vector.git
                         DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(static_vector_git_repo)

message("\n======================== IMPLICIT ASSET TYPE ========================")
# Fetches tarball from mentioned tag
FetchContentExt_Declare(
  json_tarball_implicit GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_implicit)
if (NOT EXISTS ${json_tarball_implicit_SOURCE_DIR}/sources.tar.gz)
  message("Fetching json_tarball_implicit failed")
endif ()

message("\n======================== EXPLICIT TARBALL ========================")
# FEtches tarball from mentioned tag
FetchContentExt_Declare(
  json_tarball_explicit
  GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 ASSET tarball DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_explicit)
if (NOT EXISTS ${json_tarball_explicit_SOURCE_DIR}/sources.tar.gz)
  message("Fetching json_tarball_explicit failed")
endif ()

message("\n======================== EXPLICIT ZIPBALL ========================")
# Fetches zipball from mentioned tag
FetchContentExt_Declare(
  json_zipball GITHUB_REPOSITORY nlohmann/json GIT_TAG v3.11.3 ASSET zipball DOWNLOAD_NO_EXTRACT
                                                                             TRUE
)
FetchContent_MakeAvailable(json_zipball)
if (NOT EXISTS ${json_zipball_SOURCE_DIR}/sources.zip)
  message("Fetching json_zipball failed")
endif ()

message("\n======================== MANUAL ASSET ========================")
# Fetches asset from mentioned release. Note that there is a difference between GIT_TAG and
# GIT_RELEASE - only GIT_RELEASE supports assets other than tarball and zipball
FetchContentExt_Declare(
  json_asset GITHUB_REPOSITORY nlohmann/json GIT_RELEASE v3.11.3 ASSET include.zip
                               DOWNLOAD_NO_EXTRACT TRUE EXCLUDE_FROM_ALL FIND_PACKAGE_ARGS
)
FetchContent_MakeAvailable(json_asset)
if (NOT EXISTS ${json_asset_SOURCE_DIR}/include.zip)
  message("Fetching json_asset failed")
endif ()

message("\n======================== IMPLICIT LATEST ========================")
# Download the tarball from latest release
FetchContentExt_Declare(
  static_vector_implicit_version GITHUB_REPOSITORY jmacheta/static_vector ASSET tarball DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(static_vector_implicit_version)
