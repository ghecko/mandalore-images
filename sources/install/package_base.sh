#!/bin/bash
# Author: The Mandalore Project

source common.sh

function update() {
    colorecho "Updating, upgrading, cleaning"
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    apt-get -y update && apt-get -y install apt-utils dialog && apt-get -y upgrade && apt-get -y autoremove && apt-get clean
}

function install_exegol-history() {
    colorecho "Installing exegol-history"
    git -C /opt/tools/ clone --depth 1 https://github.com/ThePorgs/exegol-history
    cd /opt/tools/exegol-history || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    # requirements.txt is incomplete (misses argcomplete): install the project itself
    uv pip install .
    deactivate
    add-aliases exegol-history
    add-history exegol-history
    add-test-command "exh -h"
    add-to-list "exegol-history,https://github.com/ThePorgs/Exegol-history,Credentials management for Mandalore"
}

function install_rust_cargo() {
    # CODE-CHECK-WHITELIST=add-aliases,add-to-list,add-history
    colorecho "Installing rustc, cargo, rustup"
    # splitting curl | sh to avoid having additional logs put in curl output being executed because of catch_and_retry
    curl https://sh.rustup.rs -sSf -o /tmp/rustup.sh
    sh /tmp/rustup.sh -y
    source "$HOME/.cargo/env"
    add-test-command "cargo --version"
}

function filesystem() {
    colorecho "Preparing filesystem"
    mkdir -p /opt/tools/bin/ /data/ /var/log/mandalore /.mandalore/ /opt/rules/ /opt/lists
    touch /.mandalore/unit_tests_all_commands.txt
    touch /.mandalore/installed_tools.csv
    echo "Tool,Link,Description" >> /.mandalore/installed_tools.csv
}

function install_go() {
    # CODE-CHECK-WHITELIST=add-aliases,add-to-list,add-history
    colorecho "Installing go (Golang)"
    asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
    # 1.26.1 needed for ruler, BloodHound-CE, GoExec, s3scanner
    asdf install golang 1.26.1
    # 1.23.0 needed for bettercap, subzy
    asdf install golang 1.23.0
    # Default GO version: 1.22.2
    asdf install golang 1.22.2

    asdf set --home golang 1.22.2 1.23.0 1.26.1

    add-test-command "go version"
}

function install_nim() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history
    colorecho "Installing nim"
    # Debian 13 no longer ships nim. Managed via asdf (prebuilt binaries) so it can be
    # updated in the image with: asdf install nim latest && asdf set --home nim latest
    asdf plugin add nim https://github.com/asdf-community/asdf-nim.git
    asdf install nim latest:2
    asdf set --home nim latest:2
    add-test-command "nim --version"
    add-test-command "nimble --version"
    add-to-list "nim,https://github.com/nim-lang/Nim,Nim programming language compiler and nimble package manager (managed with asdf)."
}

function deploy_mandalore() {
    colorecho "Installing Mandalore things"
    # Moving mandalore files to /
    # It's copied and not moved for caching and updating purposes (reusing mandalore_base to create mandalore_base)
    # mkdir -p /opt/packages
    # chown -Rv _apt:root /opt/packages
    rm -rf /.mandalore || true
    cp -r /root/sources/assets/mandalore /.mandalore
    cp -v /root/sources/assets/shells/history.d/_init ~/.zsh_history
    cp -v /root/sources/assets/shells/aliases.d/_init /opt/.mandalore_aliases
    # Moving supported custom configurations in /opt
    mv /.mandalore/skel/supported_setups.md /opt/
    mkdir -p /var/log/mandalore
    # Setup perms
    chown -R root:root /.mandalore
    chmod 500 /.mandalore/*.sh
    find /.mandalore/skel/ -type f -exec chmod 660 {} \;
}

function install_locales() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-test-command,add-to-list
    colorecho "Installing locales"
    fapt locales
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8
}

function install_python_versions() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-to-list,add-test-command
    colorecho "Installing Python versions with uv"
    
    # Python 2 support via system package (if available/needed)
    # fapt python2 python2-dev || echo "Python 2 install failed or not found, skipping"

    # Install Python versions using uv
    # This downloads standalone python builds
    # We install 3.10, 3.11, 3.12, 3.13
    uv python install 3.10 3.11 3.12 3.13
    
    # We can set a preference, but uv usually picks the latest or specified one.
    # To ensure 'python' or 'python3' uses a specific version globally with uv commands, 
    # we can use 'uv python pin'. But for system-wide usage, we rely on uv's discovery.
    
    add-test-command "uv python list"
    add-test-command "uv python find 3.11"
}

function install_pyenv_python2() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-to-list
    colorecho "Installing pyenv for Python 2.7.18"
    
    # 1. Prereqs for building Python 2
    fapt git curl build-essential libssl-dev zlib1g-dev libbz2-dev \
         libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
         libffi-dev liblzma-dev python-is-python3

    # 2. Install pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    if [ ! -d "$PYENV_ROOT" ]; then
        curl https://pyenv.run | bash
    fi

    # 3. Initialize pyenv for this session
    eval "$(pyenv init -)"

    # 4. Install Python 2.7.18
    if ! pyenv versions | grep -q "2.7.18"; then
        colorecho "Compiling Python 2.7.18..."
        # CFLAGS needed for some modern compilers/openssl issues, though 2.7.18 covers most.
        # Ensure we don't mess up system stuff.
        pyenv install 2.7.18
    else
        colorecho "Python 2.7.18 already installed via pyenv."
    fi

    # 5. Set up symlinks/environment
    # We DO NOT want to set 'pyenv global 2.7.18' because that might shadow 'python' -> 'python2' 
    # if pyenv shims are in PATH before /usr/bin.
    # Instead, we want 'python2' to be available explicitly.
    
    # Symlink the binary directly to /usr/local/bin/python2
    local py2_bin="$HOME/.pyenv/versions/2.7.18/bin/python"
    local pip2_bin="$HOME/.pyenv/versions/2.7.18/bin/pip"
    
    if [ -f "$py2_bin" ]; then
        ln -sf "$py2_bin" /usr/local/bin/python2
        ln -sf "$pip2_bin" /usr/local/bin/pip2
        
        colorecho "Python 2 available at /usr/local/bin/python2"
        /usr/local/bin/python2 --version
    else
        criticalecho "Python 2 compilation failed or binary not found."
    fi

    # Install virtualenv in python2
    /usr/local/bin/pip2 install virtualenv

    # 6. Ensure 'python' points to python3 (already handled by python-is-python3 apt package above)
    # But just in case:
    if ! command -v python &> /dev/null; then
        ln -s /usr/bin/python3 /usr/local/bin/python
    fi

}

function install_firefox() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing firefox"
    fapt firefox-esr
    mkdir /opt/tools/firefox
    mv /root/sources/assets/firefox/* /opt/tools/firefox/
    uv pip install --system --break-system-packages -r /opt/tools/firefox/requirements.txt
    python3 /opt/tools/firefox/generate_policy.py
    add-history firefox
    add-test-command "cat /usr/lib/firefox-esr/distribution/policies.json|grep 'Mandalore'"
    add-test-command "firefox --version"
    add-to-list "firefox,https://www.mozilla.org,A web browser"
}

function install_rvm() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-to-list
    colorecho "Installing rvm"
    # allow to fetch keys when behind a firewall (https://serverfault.com/questions/168826/how-to-install-gpg-keys-from-behind-a-firewall)
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    # kill all gpg processes
    # make sure gpgconf exists
    if command -v gpgconf > /dev/null; then
        gpgconf --kill all
    else
        :  # Do nothing, and return true
    fi
    # splitting curl | bash to avoid having additional logs put in curl output being executed because of catch_and_retry
    curl -sSL https://get.rvm.io -o /tmp/rvm.sh
    bash /tmp/rvm.sh --ruby="3.2.2" stable
    source /usr/local/rvm/scripts/rvm
    # RVM's Debian requirements check still asks for libncurses5-dev, which Debian 13 dropped
    # (now libncurses-dev). Install Ruby build deps ourselves and disable autolibs checks.
    fapt autoconf bison libncurses-dev libyaml-dev libssl-dev libreadline-dev zlib1g-dev libffi-dev libgdbm-dev libdb-dev
    rvm autolibs disable
    rvm rvmrc warning ignore allGemfiles
    rvm use 3.2.2@default
    rvm install ruby-3.3.8 # Needed by metasploits
    rvm get head
    rvm cleanup all
    gem update
    add-test-command "rvm --version"
}

function install_fzf() {
    # CODE-CHECK-WHITELIST=add-history
    colorecho "Installing fzf"
    git -C /opt/tools clone --depth 1 https://github.com/junegunn/fzf.git
    yes|/opt/tools/fzf/install
    add-aliases fzf
    add-test-command "source ~/.fzf.zsh && fzf-wordlists --help"
    add-test-command "source ~/.fzf.zsh && fzf --help"
    add-to-list "fzf,https://github.com/junegunn/fzf,🌸 A command-line fuzzy finder"
}

function install_ohmyzsh() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-test-command,add-to-list
    if [[ -d "/root/.oh-my-zsh" ]]; then
        return
    fi
    colorecho "Installing oh-my-zsh, config, history, aliases"
    # splitting wget and sh to avoid having additional logs put in curl output being executed because of catch_and_retry
    wget -O /tmp/ohmyzsh.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    sh /tmp/ohmyzsh.sh
    cp -v /root/sources/assets/shells/zshrc ~/.zshrc
    git -C ~/.oh-my-zsh/custom/plugins/ clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions
    git -C ~/.oh-my-zsh/custom/plugins/ clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting
    git -C ~/.oh-my-zsh/custom/plugins/ clone --depth 1 https://github.com/zsh-users/zsh-completions
    git -C ~/.oh-my-zsh/custom/plugins/ clone --depth 1 https://github.com/agkozak/zsh-z
    git -C ~/.oh-my-zsh/custom/plugins/ clone --depth 1 https://github.com/lukechilds/zsh-nvm
    zsh -c "source ~/.oh-my-zsh/custom/plugins/zsh-nvm/zsh-nvm.plugin.zsh" # this is needed to start an instance of zsh to have the plugin set up
}

function install_cargo_binstall() {
    # CODE-CHECK-WHITELIST=add-test-command
    colorecho "Installing cargo-binstall"
    # Install cargo-binstall for faster rust tool installation (binary download instead of compile)
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
    add-test-command "cargo binstall --help"
}



function install_uv() {
    # CODE-CHECK-WHITELIST=add-test-command
    colorecho "Installing uv (Python package manager)"
    
    # Force installation to /usr/local/bin so it persists in PATH across Docker layers
    export UV_INSTALL_DIR="/usr/local/bin"
    
    # Install using the official standalone script
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Ensure it's executable (installer usually handles this, but safety first)
    chmod +x /usr/local/bin/uv

    # Enable autocompletion for future interactive shells
    if command -v uv >/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc
        echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
    fi

    # Add to current path for immediate use
    export PATH="$HOME/.local/bin:$PATH"

    add-test-command "uv --version"
}

function install_pyftpdlib() {
    # CODE-CHECK-WHITELIST=add-history
    colorecho "Installing pyftpdlib"
    uv tool install pyftpdlib
    add-aliases pyftpdlib
    add-test-command "$(uv tool dir)/pyftpdlib/bin/python -c 'import pyftpdlib'"
    add-to-list "pyftpdlib,https://github.com/giampaolo/pyftpdlib/,Extremely fast and scalable Python FTP server library"
}

function install_tldr() {
    # CODE-CHECK-WHITELIST=add-history,add-test-command
    colorecho "Installing tldr"
    uv tool install tldr
    export PATH="$HOME/.local/bin:$PATH"
    tldr --update
    add-history tldr
    add-test-command "tldr --version"
}

function install_yarn() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-to-list
    colorecho "Installing yarn"
    wget -O /tmp/yarn.gpg.armored https://dl.yarnpkg.com/debian/pubkey.gpg
    # doing wget, gpg, chmod, to avoid the warning of apt-key being deprecated
    gpg --dearmor --output /etc/apt/trusted.gpg.d/yarn.gpg /tmp/yarn.gpg.armored
    chmod 644 /etc/apt/trusted.gpg.d/yarn.gpg
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt-get update
    fapt yarn
    add-test-command "yarn --help"
}

function install_ultimate_vimrc() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-test-command,add-to-list
    if [[ -d "/root/.vim_runtime" ]]; then
        return
    fi
    colorecho "Installing The Ultimate vimrc"
    git clone --depth 1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
}

function install_neovim() {
    colorecho "Installing neovim/nvim"
    # CODE-CHECK-WHITELIST=add-aliases,add-history
    if [[ $(uname -m) = 'x86_64' ]]
    then
        curl --location --output nvim.appimage "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        chmod u+x nvim.appimage
        ./nvim.appimage --appimage-extract
        mkdir /opt/tools/nvim
        cp -rv squashfs-root/usr/* /opt/tools/nvim
        rm -rf squashfs-root nvim.appimage
        ln -v -s /opt/tools/nvim/bin/nvim /opt/tools/bin/nvim
    elif [[ $(uname -m) = 'aarch64' ]]
    then
        # Building, because when using release, error is raised: "./bin/nvim: /lib/aarch64-linux-gnu/libm.so.6: version `GLIBC_2.38' not found (required by ./bin/nvim)"
        # https://github.com/neovim/neovim/issues/32496
        # Would require a bump in glibc, using old releases, or manually building. So manual build it is.
        fapt gettext
        git clone --depth 1 https://github.com/neovim/neovim.git
        cd neovim || exit
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        make install
        cd .. || exit
        rm -rf ./neovim
    fi
    add-test-command "nvim --version"
    add-to-list "neovim,https://neovim.io/,hyperextensible Vim-based text editor"
}

function install_mdcat() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing mdcat"
    source "$HOME/.cargo/env"
    cargo install mdcat --locked
    add-history mdcat
    add-test-command "mdcat --version"
    add-to-list "mdcat,https://github.com/swsnr/mdcat,Fancy cat for Markdown"
}

function install_gf() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing gf"
    # A wrapper around grep, to help you grep for things
    go install -v github.com/tomnomnom/gf@latest
    asdf reshim golang
    # Enable autocompletion
    {
      # adding new-line
      echo ''
      echo '# Enable gf autocompletion'
      cat "$(sh -c "go env GOPATH")"/pkg/mod/github.com/tomnomnom/gf@*/gf-completion.zsh
    } >> ~/.zshrc
    cp -r "$(sh -c "go env GOPATH")"/pkg/mod/github.com/tomnomnom/gf@*/examples ~/.gf
    # Add patterns from 1ndianl33t
    git -C /opt/tools/ clone --depth 1 https://github.com/1ndianl33t/Gf-Patterns
    cp -r /opt/tools/Gf-Patterns/*.json ~/.gf
    # Remove repo to save space
    rm -r /opt/tools/Gf-Patterns
    add-history gf
    add-test-command "gf --list"
    add-test-command "ls ~/.gf |& grep 'redirect.json'"
    add-to-list "gf,https://github.com/tomnomnom/gf,A wrapper around grep to avoid typing common patterns"
}

function install_java11() {
    # CODE-CHECK-WHITELIST=add-history,add-aliases,add-to-list
    colorecho "Installing java 11"
    if [[ $(uname -m) = 'x86_64' ]]
    then
        local arch="x64"

    elif [[ $(uname -m) = 'aarch64' ]]
    then
        local arch="aarch64"
    else
        criticalecho-noexit "This installation function doesn't support architecture $(uname -m)" && return
    fi
    local jdk_url
    jdk_url=$(gh_api "https://api.github.com/repos/adoptium/temurin11-binaries/releases" | grep 'browser_download_url.*jdk_'"$arch"'_linux.*tar.gz"' | grep -o 'https://[^"]*' | sort | tail -n1)
    curl --location -o /tmp/openjdk11-jdk.tar.gz "$jdk_url"
    tar -xzf /tmp/openjdk11-jdk.tar.gz --directory /tmp
    mkdir -p "/usr/lib/jvm"
    mv /tmp/jdk-11* /usr/lib/jvm/java-11-openjdk
    for x in /usr/lib/jvm/java-11-openjdk/bin/*; do
      BIN_NAME=$(echo "$x" | rev | cut -d '/' -f1 | rev)
      update-alternatives --install "/usr/bin/$BIN_NAME" "$BIN_NAME" "$x" 11;
    done
    ln -s -v /usr/lib/jvm/java-11-openjdk/bin/java /usr/bin/java11
    add-test-command "/usr/lib/jvm/java-11-openjdk/bin/java --version"
    add-test-command "java11 --version"
}

function install_java24() {
    # CODE-CHECK-WHITELIST=add-history,add-aliases,add-to-list
    colorecho "Installing java 24"
    if [[ $(uname -m) = 'x86_64' ]]
    then
        wget -O /tmp/openjdk24-jdk.tar.gz "https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_linux-x64_bin.tar.gz"

    elif [[ $(uname -m) = 'aarch64' ]]
    then
        wget -O /tmp/openjdk24-jdk.tar.gz "https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_linux-aarch64_bin.tar.gz"
    else
        criticalecho-noexit "This installation function doesn't support architecture $(uname -m)" && return
    fi
    tar -xzf /tmp/openjdk24-jdk.tar.gz --directory /tmp
    mkdir -p "/usr/lib/jvm"
    mv /tmp/jdk-24* /usr/lib/jvm/java-24-openjdk
    for x in /usr/lib/jvm/java-24-openjdk/bin/*; do
      BIN_NAME=$(echo "$x" | rev | cut -d '/' -f1 | rev)
      update-alternatives --install "/usr/bin/$BIN_NAME" "$BIN_NAME" "$x" 24;
    done
    ln -s -v /usr/lib/jvm/java-24-openjdk/bin/java /usr/bin/java24
    add-test-command "/usr/lib/jvm/java-24-openjdk/bin/java --version"
    add-test-command "java24 --version"
}

function add_debian_repository_components() {
    # add non-free non-free-firmware contrib repository
    # adding at the end of the line start with Components of the repository to add
    colorecho "add non-free non-free-firmware contrib repository"
    local source_file="/etc/apt/sources.list.d/debian.sources"
    local out_file="/etc/apt/sources.list.d/debian2.sources"

    while IFS= read -r line; do
      if [[ "$line" == "Components"* ]]; then
        echo  "${line} non-free non-free-firmware contrib" >> "$out_file"
      else
        echo "$line" >> "$out_file"
      fi
    done < "$source_file"
    mv "$out_file" "$source_file"
}

function install_asdf() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history
    colorecho "Installing asdf"
    local URL
    if [[ $(uname -m) = 'x86_64' ]]
    then
        URL=$(gh_api "https://api.github.com/repos/asdf-vm/asdf/releases/latest" | grep 'browser_download_url.*asdf.*linux-amd64.tar.gz"' | grep -o 'https://[^"]*')
    elif [[ $(uname -m) = 'aarch64' ]]
    then
        URL=$(gh_api "https://api.github.com/repos/asdf-vm/asdf/releases/latest" | grep 'browser_download_url.*asdf.*linux-arm64.tar.gz"' | grep -o 'https://[^"]*')
    else
        criticalecho-noexit "This installation function doesn't support architecture $(uname -m)" && return
    fi
    curl --location -o /tmp/asdf.tar.gz "$URL"
    tar -xf /tmp/asdf.tar.gz --directory /tmp
    rm /tmp/asdf.tar.gz
    mv /tmp/asdf /opt/tools/bin/asdf
    set_bin_path
    set_asdf_env
    # asdf completions
    mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
    add-test-command "asdf version"
    add-to-list "asdf,https://github.com/asdf-vm/asdf,Extendable version manager with support for ruby python go etc"
}

function install_pipx() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history,add-to-list
    colorecho "Installing pipx"
    # pip3 can't upgrade Debian's python3-platformdirs on trixie: use the distro package
    fapt pipx
    pipx ensurepath
    add-test-command "pipx --version"
}

# Package dedicated to the basic things the env needs
function package_base() {
    local start_time
    local end_time
    start_time=$(date +%s)
    update
    colorecho "Installing apt-fast for faster dep installs"
    apt-get install -y curl sudo wget
    # splitting curl | bash to avoid having additional logs put in curl output being executed because of catch_and_retry
    curl -sL https://git.io/vokNn -o /tmp/apt-fast-install.sh
    bash /tmp/apt-fast-install.sh
    deploy_mandalore
    # Re-init failure tracking because deploy_mandalore wipes /.mandalore
    init_failure_tracking
    add_debian_repository_components
    apt-get update
    colorecho "Starting main programs install"
    fapt man git lsb-release pciutils pkg-config zip unzip kmod gnupg2 wget \
    libffi-dev zsh asciinema npm gem automake autoconf make cmake time gcc g++ file lsof \
    less x11-apps net-tools vim nano jq iputils-ping iproute2 tidy plocate libtool \
    dos2unix ftp sshpass telnet nfs-common ncat netcat-traditional socat rdate putty \
    screen p7zip-full 7zip-rar unrar xz-utils xsltproc parallel tree ruby ruby-dev ruby-full bundler \
    perl libwww-perl openjdk-21-jdk openvpn openresolv \
    logrotate tmux bat libxml2-utils virtualenv chromium libsasl2-dev \
    libldap2-dev libssl-dev isc-dhcp-client sqlite3 dnsutils samba ssh snmp faketime php \
    python3 python3-dev grc emacs-nox xsel xxd libnss3-tools htop
    apt-mark hold tzdata  # Prevent apt upgrade error when timezone sharing is enable

    filesystem
    install_locales
    cp -v /root/sources/assets/shells/mandalore_shells_rc /opt/.mandalore_shells_rc
    cp -v /root/sources/assets/shells/bashrc ~/.bashrc

    install_asdf

    # Install uv before Python versions
    install_uv

    # Install Python 2.7.18 via pyenv (for legacy tools)
    install_pyenv_python2

    # setup Python environment
    # the order matters (if 2 is before 3, `python` will point to Python 2)
    # setup Python environment using uv
    install_python_versions
    # install_pipx is removed in favor of `uv tool install`

    # change default shell
    chsh -s /bin/zsh

    add-history sshpass
    add-history dnsutils
    add-history samba
    add-history ssh
    add-history snmp
    add-history faketime

    add-aliases php
    add-aliases python3
    add-aliases grc
    add-aliases emacs-nox
    add-aliases xsel

    # Rust, Cargo, rvm
    install_rust_cargo
    install_rvm                                         # Ruby Version Manager

    # java11 install (manual), java21 from Debian (openjdk-21-jdk, installed above) as default.
    # Debian 13 no longer ships openjdk-17; java21 replaces it as the default JVM.
    install_java11
    #install_java24  # Ready to be install when needed
    ln -s -v /usr/lib/jvm/java-21-openjdk-* /usr/lib/jvm/java-21-openjdk    # To avoid determining the correct path based on the architecture
    ln -s -v /usr/lib/jvm/java-21-openjdk/bin/java /usr/bin/java21          # Add java21 bin
    update-alternatives --set java /usr/lib/jvm/java-21-openjdk-*/bin/java  # Set the default openjdk version to 21
    add-test-command "/usr/lib/jvm/java-21-openjdk/bin/java --version"
    add-test-command "java21 --version"

    install_go                                          # Golang language
    install_nim                                         # Nim language (asdf)
    install_ohmyzsh                                     # Awesome shell
    install_fzf                                         # Fuzzy finder
    add-history curl
    install_yarn
    install_cargo_binstall
    install_pyftpdlib
    install_ultimate_vimrc                              # Make vim usable OOFB
    install_neovim
    install_mdcat                                       # cat markdown files
    add-aliases bat
    add-test-command "bat --version"
    DEBIAN_FRONTEND=noninteractive fapt macchanger      # Macchanger
    install_gf                                          # wrapper around grep
    install_firefox

    cp -v /root/sources/assets/grc/grc.conf /etc/grc.conf # grc

    # openvpn
    # Fixing openresolv to update /etc/resolv.conf without resolvectl daemon (with a fallback if no DNS server are supplied)
    LINE=$(($(grep -n 'up)' /etc/openvpn/update-resolv-conf | cut -d ':' -f1) +1))
    sed -i "${LINE}"'i cp /etc/resolv.conf /etc/resolv.conf.backup' /etc/openvpn/update-resolv-conf

    LINE=$(($(grep -n 'resolvconf -a' /etc/openvpn/update-resolv-conf | cut -d ':' -f1) +1))
    # shellcheck disable=SC2016
    sed -i "${LINE}"'i [ "$((resolvconf -l "tun*" 2>/dev/null || resolvconf -l "tap*") | grep -vE "^(\s*|#.*)$")" ] && /sbin/resolvconf -u || cp /etc/resolv.conf.backup /etc/resolv.conf' /etc/openvpn/update-resolv-conf
    ((LINE++))
    sed -i "${LINE}"'i rm /etc/resolv.conf.backup' /etc/openvpn/update-resolv-conf
    add-test-command "openvpn --version"

    # logrotate
    mv /root/sources/assets/logrotate/* /etc/logrotate.d/
    chmod 644 /etc/logrotate.d/*

    # tmux
    cp -v /root/sources/assets/shells/tmux.conf ~/.tmux.conf
    touch ~/.hushlogin

    install_tldr

    # NVM (install in context)
    zsh -c "source ~/.zshrc && nvm install node && nvm use default"

    # Set Global config path to vendor
    # All programs using bundle will store their deps in vendor/
    bundle config path vendor/

    # OpenSSL activate legacy support
    cat /root/sources/assets/patches/openssl.patch >> /etc/ssl/openssl.cnf
    add-test-command "echo -n '1337' | openssl dgst -md4"
    add-test-command "python3 -c 'import hashlib;print(hashlib.new(\"md4\", \"1337\".encode()).digest())'"

    # Global python dependencies
    uv pip install --system --break-system-packages -r /root/sources/assets/python/requirements.txt

    safe_install base install_pipx

    install_exegol-history

    post_install
    end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    colorecho "Package base completed in $elapsed_time seconds."
}
