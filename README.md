
> **📌 This repository hosts code for Mandalore images, a submodule of the Mandalore project. 
> If you were looking for Mandalore, go to [the main repo](https://github.com/ghecko/mandalore)**
___

# Mandalore images

This repository hosts Dockerfiles for each Mandalore image, an installation script, and various assets needed during the installation (custom configurations, a history file, an aliases file, etc.). These files can be used to locally build the docker images, there is however a pipeline in place to build, test and push images on DockerHub so that Mandalore users don't have to build their own image.

More information on [the Mandalore documentation](https://github.com/ghecko/mandalore-docs).

# Atomic Testing Guide

To test specific function changes without rebuilding the entire image:

1. Launch a container from your current base image (using --entrypoint /bin/bash to bypass the default wrapper):

```
docker run -it --rm -v $(pwd)/sources:/root/sources -w /root/sources/install --entrypoint /bin/bash lksec/mandalore-base:latest
```

2. Source the environment:

```
source common.sh
source package_network.sh # or whichever script you are testing
```

3. Run the function:

```
install_ligolo-ng
```

This allows you to iterate instantly on syntax or logic errors.

# Build Error Handling

The build system includes resilient error handling to avoid aborting the entire build when individual tools fail.

## How it works

- **Network-only retries**: Commands like `curl`, `wget`, `git`, `pip`, etc. are automatically retried (with exponential backoff) only when the failure is network-related (DNS resolution, timeouts, connection resets...). Non-network failures (compilation errors, missing dependencies...) fail immediately without wasting time on retries.
- **Skip & log**: When a tool fails for a non-network reason, the build skips it and continues to the next tool. The full output is saved to `/.mandalore/build_failures/<package>__<tool>.log` inside the container.
- **End-of-build summary**: At the end of each package and at the very end of `post_build`, a summary is printed listing all failed tools per package.

## Retrieving failure information

The failure summary is printed to **stdout** at the end of the build, so it's visible in your terminal. For example, after `make base && make full`, the last lines will show:

```
╔══════════════════════════════════════════════════╗
║     GLOBAL BUILD FAILURE SUMMARY                ║
╠══════════════════════════════════════════════════╣
║  Total failed tools: 3                           ║
╚══════════════════════════════════════════════════╝

Package 'ad': 2 tool(s) failed:
  1. bloodyAD
  2. certipy

Package 'web': 1 tool(s) failed:
  1. caido
```

To retrieve the **detailed per-tool logs** from the built image:

```bash
# View the summary
docker run --rm lksec/mandalore-full cat /.mandalore/build_failures/SUMMARY.txt

# Copy all failure logs to your host
ID=$(docker create lksec/mandalore-full)
docker cp "$ID:/.mandalore/build_failures" ./build_failures
docker rm "$ID"
```

> **Note**: `package_base` does **not** use skip & log — it contains foundational system setup (shell, languages, etc.) where failures should abort the build.