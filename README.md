# fetchcontent_ext

This component extends the functionality of CMakeFetchContent module by allowing download repository artifacts from private Git repositories from popular services like Github.

## Features

- **Private Repository Access**: Easily download artifacts from private Git repositories.
- **Service Compatibility**: Supports popular services like GitHub, (GitLab, and Bitbucket are WIP).
- **Authentication**: Handles authentication seamlessly using personal access tokens.
- **Seamless Integration**: Downloading tarball from private repo is as easy as changing FetchContent_Declare to FetchContentExt_Declare.
- **Download tags and releases**: FetchContentExt understands the difference between tags and releases. You can use either to download your tarballs

## MVP

Install `fetchcontent_ext`, add the following to your `CMakeLists.txt`:

```cmake
# Setup Personal access token in your environment variables (for this example, use GITHUB_TOKEN).
# For details refer to the Environment section of this document. 

# Download the module using the original FetchContent

include(FetchContent)
FetchContent_Declare(fetchcontent_ext URL https://github.com/jmacheta/fetchcontent_ext/archive/main.zip)
FetchContent_MakeAvailable(fetchcontent_ext)

# Now you can include the module by invoking
include(ecpp/FetchContentExt)

# Declare FetchContent target:
FetchContentExt_Declare(json GIT_REPOSITORY https://github.com/nlohmann/json.git GIT_RELEASE v3.11.3 ASSET include.zip)

# Download as usual

FetchContent_MakeAvailable(json)

# Enjoy!
```

## Usage

### API synopsis

```cmake
FetchContentExt_Declare( name [URL | GIT_REPOSITORY | GITHUB_REPOSITORY | GITLAB_REPOSITORY] <repo> 
                              [GIT_TAG <tag>]
                              [GIT_RELEASE <release>]
                              [ASSET <asset>]
                              [TOKEN <token>] ...
)
```

Declare a FetchContent target with given `name` from the `<repo>`.
The repo may take the repository in one of the following formats:

- **`GITHUB_REPOSITORY`**: string with `organization/repository`, e.g. jmacheta/fetchcontent_ext
- **`GIT_REPOSITORY`**: string with GIT URL, like:
  - `https://github.com/jmacheta/fetchcontent_ext.git`,
  - `git@github.com:jmacheta/fetchcontent_ext.git`
- **`URL`**: same as above, but skips trailing `.git`

**`GIT_TAG`** controls, which tag the **`ASSET`** should be downloaded from. If not provided, it will use **the most recent** available tag. This is valid only for _`TARBALL`_ and _`ZIPBALL`_ assets.

Alternatively you may specify **`GIT_RELEASE`** to point to the release name that **`ASSET`** should be downloaded from. This method is valid for all asset types.

Use **`ASSET`** to provide the filename of the file to be downloaded. there are two special asset values:

- **`TARBALL`** - download the tar archive from given **`GIT_TAG`** / **`GIT_RELEASE`**  - _**DEFAULT IF NOT PROVIDED**_
- **`ZIPBALL`** - like above, but download the zip archive.

The other values should point to the exact name of the artifact to be downloaded.

The component will use provided **`TOKEN`** to authenticate all API calls. If not provided explicitly, it will look for predefined environment variables. Please refer to the [implementation details section](#environment)

> [!NOTE]
> Providing **`TOKEN`** explicitly might leak your token to the public in case of a bad commit, so it is not the best idea.

### Examples

#### Most recent TARBALL

```cmake
FetchContentExt_Declare(static_vector GITHUB_REPOSITORY jmacheta/static_vector EXCLUDE_FROM_ALL FIND_PACKAGE_ARGS)
```

Declares a FetchContent target _**static_vector**_ that downloads the **`TARBALL`** from the most recent tag of the Github repository `jmacheta/static_vector` using the **`TOKEN`** from the environment variables. The **`EXCLUDE_FROM_ALL`** and **`FIND_PACKAGE_ARGS`** are passed directly to the underlying FetchContent_Declare.

#### Release asset

```cmake
FetchContentExt_Declare(json GIT_REPOSITORY https://github.com/nlohmann/json.git GIT_RELEASE v3.11.3 ASSET include.zip)
```

Declare a FetchContent target _**json**_ that downloads [include.zip](https://github.com/nlohmann/json/releases/download/v3.11.3/include.zip) archive from release v3.11.3 of `nlohmann/json`

## Environment

The component does not need extra setup steps to be used with public repositories, _**However**_, some of the services impose API limits for unauthenticated users (e.g. Github allows only 60 queries/h). In most cases the limits are lifted when authenticated, so it is highly advisable to setup the environment variables with _Access Tokens_ for your favorite services.
For more information, check the documentation below:

- [**Github**](doc/github.md)
- [**Gitlab**](doc/gitlab.md)

## Principle of operation

When invoking FetchContentExt_Declare the following things happen:

- We use provided arguments to determine the repository location
- The dedicated function fetches the repository information using services API (e.g. using Github REST API). Those calls are authenticated using either provided, or injected TOKEN from your environment
- We look for the download URL of interesting artifact.
- The found URL is then passed to the FetchContent_Declare, together with authentication header (based on the mentioned TOKEN).

The approach provides almost seamless integration with your existing FetchContent targets. Other arguments are always forwarded to the original FetchContent_Declare call, so you can modify the behaviour (other that the URL) to your liking.

## Limitations

This component ALWAYS declares a FetchContent target using **URL** strategy. This is due to the fact, that downloading tarballs and release artifacts lies outside of the Git protocol. Because of that, if your repository uses Git submodules, they **WILL NOT** be populated automatically, which may lead to CMake configuration errors. If this is the case, consider disabling automatic configuration of FetchContent target and populate submodules beforehand.
