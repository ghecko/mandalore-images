#!/bin/bash
set -e

# This script will be executed on the first startup of each new container with the "my-resources" feature enabled.
# Arbitrary code can be added in this file, in order to customize Mandalore (dependency installation, configuration file copy, etc).
# It is strongly advised **not** to overwrite the configuration files provided by mandalore (e.g. /root/.zshrc, /opt/.mandalore_aliases, ...), official updates will not be applied otherwise.

# Mandalore also features a set of supported customization a user can make.
# The /opt/supported_setups.md file lists the supported configurations that can be made easily.

