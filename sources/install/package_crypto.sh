#!/bin/bash
# Author: The Mandalore Project

source common.sh

function install_tls-map() {
    colorecho "Installing TLS map"
    rvm use 3.2.2@tls-map --create
    gem install tls-map
    rvm use 3.2.2@default
    add-aliases tls-map
    add-history tls-map
    add-test-command "tls-map --help"
    add-to-list "tls-map,https://github.com/sec-it/tls-map,tls-map is a library for mapping TLS cipher algorithm names."
}

function install_rsactftool() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Rsactftool"
    fapt libmpc-dev
    # using python 3.11 and manual venv to pre-install z3-solver and avoid build failure on aarch64
    uv venv --python 3.11 --seed /opt/tools/rsactftool/venv
    source /opt/tools/rsactftool/venv/bin/activate
    # Pinning z3-solver to avoid compilation issues with GCC 12 (C++20 <format> error)
    uv pip install "z3-solver<4.13.0"
    uv pip install git+https://github.com/RsaCtfTool/RsaCtfTool
    deactivate
    add-aliases rsactftool
    add-history rsactftool
    add-test-command "RsaCtfTool --help"
    add-to-list "rsactftool,https://github.com/RsaCtfTool/RsaCtfTool,The rsactftool tool is used for RSA cryptographic operations and analysis."
}

function install_rsacracker() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing RsaCracker"
    source "$HOME/.cargo/env"
    cargo install rsacracker
    add-history rsacracker
    add-test-command "rsacracker --help"
    add-to-list "RsaCracker,https://github.com/skyf0l/RsaCracker,Powerful RSA cracker for CTFs. Supports RSA - X509 - OPENSSH in PEM and DER formats."
}

# Package dedicated to attack crypto
function package_crypto() {
    set_env
    init_failure_tracking
    local start_time
    local end_time
    start_time=$(date +%s)
    safe_install crypto install_rsactftool              # attack rsa
    safe_install crypto install_tls-map                 # CLI & library for mapping TLS cipher algorithm names: IANA, OpenSSL, GnuTLS, NSS
    safe_install crypto install_rsacracker              # Powerful RSA cracker for CTFs. Supports RSA, X509, OPENSSH in PEM and DER formats.
    print_failure_summary
    post_install
    end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    colorecho "Package crypto completed in $elapsed_time seconds."
}
