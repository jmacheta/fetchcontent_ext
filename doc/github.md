# FetchContentExt Github support

## Details

Variables that the component looks for:

- GITHUB_TOKEN
- GH_TOKEN
- GH_PAT
- GITHUB_PAT

When downloading **`TABALL`** the downloaded file will be named **sources.tar.gz**

When downloading **`ZIPBALL`** the file will be named **sources.zip**

## PAT setup

>[!NOTE]
> Full documentation can be found [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

1. Log in with your Github account and go to the [Settings page](https://github.com/settings/profile).
2. Go to `Developer settings` -> `Personal access tokens` -> [`Fine-grained tokens`](https://github.com/settings/tokens)
3. Generate a token with access scope of your choosing.
4. Go to the Environment Variables in your system (for windows, press `WIN` + `R` and paste `SystemPropertiesAdvanced`)
5. Create environment variable `GITHUB_TOKEN` and paste your generated token