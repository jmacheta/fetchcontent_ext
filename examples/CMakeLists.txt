include(FetchContentGH)


FetchContent_DeclareGH(
  json_tarball_implicit REPOSITORY nlohmann/json RELEASE_TAG v3.11.3
  DOWNLOAD_NO_EXTRACT TRUE TOKEN $ENV{TEST}
)


FetchContent_DeclareGH(
  json_tarball_explicit REPOSITORY nlohmann/json RELEASE_TAG v3.11.3 TARBALL
  DOWNLOAD_NO_EXTRACT TRUE TOKEN $ENV{TEST}
)

FetchContent_DeclareGH(
    json_zipball REPOSITORY nlohmann/json RELEASE_TAG v3.11.3 ZIPBALL
    DOWNLOAD_NO_EXTRACT TRUE TOKEN $ENV{TEST}
)

FetchContent_DeclareGH(
    json_header REPOSITORY nlohmann/json RELEASE_TAG v3.11.3 ASSET_NAME json.hpp
    DOWNLOAD_NO_EXTRACT TRUE
)

FetchContent_MakeAvailable(json_tarball_implicit json_tarball_explicit json_zipball json_header)

if(NOT EXISTS ${json_tarball_implicit_SOURCE_DIR}/v3.11.3)
  message("Fetching json_tarball_implicit failed")
endif()

if(NOT EXISTS ${json_tarball_explicit_SOURCE_DIR}/v3.11.3)
  message("Fetching json_tarball_explicit failed")
endif()


if(NOT EXISTS ${json_zipball_SOURCE_DIR}/v3.11.3)
  message("Fetching json_zipball failed")
endif()


if(NOT TARGET ecpp::static_vector)
  message("Fetching static_vector_zipball failed")
endif()