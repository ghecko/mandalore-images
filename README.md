
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