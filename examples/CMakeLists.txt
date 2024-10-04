include(ecpp/FetchContentExt)

message("======================== MINIMAL EXAMPLE ========================")
FetchContentExt_Declare(
  static_vector_mvp GITHUB_REPOSITORY jmacheta/static_vector DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(static_vector_mvp)
if (NOT EXISTS ${static_vector_mvp_SOURCE_DIR}/v1.0.0)
  message("Fetching static_vector_mvp failed")
endif ()

message("\n======================== IMPLICIT ASSET TYPE ========================")
FetchContentExt_Declare(
  json_tarball_implicit GITHUB_REPOSITORY nlohmann/json GITHUB_TAG v3.11.3 DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_implicit)
if (NOT EXISTS ${static_vector_tarball_implicit_SOURCE_DIR}/v1.0.0)
  message("Fetching static_vector_tarball_implicit failed")
endif ()

message("\n======================== EXPLICIT TARBALL ========================")
FetchContentExt_Declare(
  json_tarball_explicit GITHUB_REPOSITORY nlohmann/json GITHUB_TAG v3.11.3
  GITHUB_ASSET tarball DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_tarball_explicit)
if (NOT EXISTS ${json_tarball_explicit_SOURCE_DIR}/v3.11.3)
  message("Fetching json_tarball_explicit failed")
endif ()

message("\n======================== EXPLICIT ZIPBALL ========================")
FetchContentExt_Declare(
  json_zipball GITHUB_REPOSITORY nlohmann/json GITHUB_TAG v3.11.3
  GITHUB_ASSET zipball DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_zipball)
if (NOT EXISTS ${json_zipball_SOURCE_DIR}/v3.11.3)
  message("Fetching json_zipball failed")
endif ()

message("\n======================== MANUAL ASSET ========================")
FetchContentExt_Declare(
  json_asset GITHUB_REPOSITORY nlohmann/json GITHUB_TAG v3.11.3
  GITHUB_ASSET include.zip DOWNLOAD_NO_EXTRACT TRUE
)
FetchContent_MakeAvailable(json_asset)
if (NOT EXISTS ${json_zipball_SOURCE_DIR}/include.zip)
  message("Fetching json_asset failed")
endif ()
