#!/bin/bash
# Author: The Mandalore Project

source common.sh

function install_web_apt_tools() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing web apt tools"
    fapt dirb prips swaks

    add-history dirb
    add-history prips
    add-history swaks

    add-test-command "dirb | grep '<username:password>'" # Web fuzzer
    add-test-command "prips --help"                      # Print the IP addresses in a given range
    add-test-command "swaks --version"                   # Featureful, flexible, scriptable, transaction-oriented SMTP test tool

    add-to-list "dirb,https://github.com/v0re/dirb,Web Content Scanner"
    add-to-list "prips,https://manpages.ubuntu.com/manpages/focal/man1/prips.1.html,A utility for quickly generating IP ranges or enumerating hosts within a specified range."
    add-to-list "swaks,https://github.com/jetmore/swaks,Swaks is a featureful flexible scriptable transaction-oriented SMTP test tool."
}

function install_amass() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Amass"
    go install -v github.com/owasp-amass/amass/v3/...@master
    asdf reshim golang
    add-history amass
    add-test-command "amass -version"
    add-to-list "amass,https://github.com/OWASP/Amass,A DNS enumeration / attack surface mapping & external assets discovery tool"
}

function install_anew() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing anew"
    go install -v github.com/tomnomnom/anew@latest
    asdf reshim golang
    add-history anew
    add-test-command "anew --help"
    add-to-list "anew,https://github.com/tomnomnom/anew,A simple tool for filtering and manipulating text data / such as log files and other outputs."
}

function install_arjun() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing arjun"
    uv tool install arjun
    add-history arjun
    add-test-command "arjun --help"
    add-to-list "arjun,https://github.com/s0md3v/Arjun,HTTP parameter discovery suite."
}

function install_bbot() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing BBOT"
    uv tool install bbot
    add-history bbot
    add-test-command "bbot --help"
    add-to-list "BBOT,https://github.com/blacklanternsecurity/bbot,BEE·bot is a multipurpose scanner inspired by Spiderfoot built to automate your Recon and ASM."
}

function install_bolt() {
    colorecho "Installing Bolt"
    git -C /opt/tools/ clone --depth 1 https://github.com/s0md3v/Bolt.git
    cd /opt/tools/Bolt || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases bolt
    add-history bolt
    add-test-command "bolt.py --help"
    add-to-list "bolt,https://github.com/s0md3v/bolt,Bolt crawls the target website to the specified depth and stores all the HTML forms found in a database for further processing."
}

function install_caido() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Caido"
    fapt libxss1
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local arch
    arch=$(uname -m)

    # Fetch JSON once
    local caido_json
    # Use 'command curl' to bypass the common.sh wrapper which prints to stdout
    if ! caido_json=$(command curl -s https://api.caido.io/releases/latest); then
         colorecho "Error: Failed to fetch Caido release info"
         rm -rf "$tmp_dir"
         return
    fi
     # Verify strict JSON content
    if ! echo "$caido_json" | jq -e . >/dev/null 2>&1; then
        criticalecho-noexit "Error: Invalid JSON received from Caido API"
        echo "Received content:" >&2
        echo "$caido_json" >&2
        rm -rf "$tmp_dir"
        return
    fi

    # Desktop
    local caido_deb
    caido_deb=$(echo "$caido_json" | jq -r --arg arch "$arch" '.links[] | select(.kind=="desktop" and .format=="deb" and .arch==$arch) | .link')
    local caido_file_name
    caido_file_name=$(basename "$caido_deb")
    wget "$caido_deb" -O "$tmp_dir/$caido_file_name"
    dpkg -i "$tmp_dir/$caido_file_name"

    # CLI
    local caido_cli
    caido_cli=$(echo "$caido_json" | jq -r --arg arch "$arch" '.links[] | select(.kind=="cli" and .format=="tar.gz" and .arch==$arch) | .link')
    local caido_file_name_cli
    caido_file_name_cli=$(basename "$caido_cli")
    wget "$caido_cli" -O "$tmp_dir/$caido_file_name_cli"
    tar -xvzf "$tmp_dir/$caido_file_name_cli" -C /opt/tools/bin/

    add-history caido
    add-test-gui-command "caido --no-sandbox"
    add-test-command "caido-cli --help"
    add-to-list "caido,https://docs.caido.io/quickstart/,A lightweight web security auditing toolkit."
}

function install_cloudfail() {
    colorecho "Installing CloudFail"
    git -C /opt/tools/ clone --depth 1 https://github.com/m0rtem/CloudFail
    cd /opt/tools/CloudFail || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases cloudfail
    add-history cloudfail
    add-test-command "cloudfail.py --help"
    add-to-list "cloudfail,https://github.com/m0rtem/CloudFail,a reconnaissance tool for identifying misconfigured CloudFront domains."
}

function install_corscanner() {
    colorecho "Installing CORScanner"
    git -C /opt/tools/ clone --depth 1 https://github.com/chenjj/CORScanner.git
    cd /opt/tools/CORScanner || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases corscanner
    add-history corscanner
    add-test-command "cors_scan.py --help"
    add-to-list "corscanner,https://github.com/chenjj/CORScanner,a Python script for finding CORS misconfigurations."
}

function install_droopescan() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing droopescan"
    uv tool install --python 3.11 git+https://github.com/droope/droopescan.git
    add-history droopescan
    add-test-command "droopescan --help"
    add-to-list "droopescan,https://github.com/droope/droopescan,Scan Drupal websites for vulnerabilities."
}

function install_eyewitness() {
    colorecho "Installing EyeWitness"
    git -C /opt/tools/ clone --depth 1 https://github.com/FortyNorthSecurity/EyeWitness
    cd /opt/tools/EyeWitness || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    ./setup/setup.sh
    # setup.sh creates its own eyewitness-venv; install the python deps in ./venv used by the alias
    uv pip install -r setup/requirements.txt
    deactivate
    add-aliases eyewitness
    add-history eyewitness
    add-test-command "EyeWitness.py --help"
    add-to-list "eyewitness,https://github.com/FortyNorthSecurity/EyeWitness,a tool to take screenshots of websites / provide some server header info / and identify default credentials if possible."
}

function install_feroxbuster() {
    colorecho "Installing feroxbuster"
    mkdir /opt/tools/feroxbuster
    cd /opt/tools/feroxbuster || exit
    # splitting curl | bash to avoid having additional logs put in curl output being executed because of catch_and_retry
    curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/master/install-nix.sh -o /tmp/install-feroxbuster.sh
    bash /tmp/install-feroxbuster.sh
    # Adding a symbolic link in order for autorecon to be able to find the Feroxbuster binary
    ln -v -s /opt/tools/feroxbuster/feroxbuster /opt/tools/bin/feroxbuster
    add-aliases feroxbuster
    add-history feroxbuster
    add-test-command "feroxbuster --help"
    add-to-list "feroxbuster,https://github.com/epi052/feroxbuster,Simple / fast and recursive content discovery tool"
}

function install_ffuf() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing ffuf"
    if [[ $(uname -m) = 'x86_64' ]]
    then
        local arch="amd64"

    elif [[ $(uname -m) = 'aarch64' ]]
    then
        local arch="arm64"
    else
        criticalecho-noexit "This installation function doesn't support architecture $(uname -m)" && return
    fi
    local ffuf_url
    ffuf_url=$(gh_api "https://api.github.com/repos/ffuf/ffuf/releases/latest" | grep 'browser_download_url.*ffuf.*linux_'"$arch"'.tar.gz"' | grep -o 'https://[^"]*')
    curl --location -o /tmp/ffuf.tar.gz "$ffuf_url"
    tar -xf /tmp/ffuf.tar.gz --directory /opt/tools/bin/
    add-history ffuf
    add-test-command "ffuf --help"
    add-to-list "ffuf,https://github.com/ffuf/ffuf,Fast web fuzzer written in Go."
}

function install_fuxploider() {
    colorecho "Installing fuxploider"
    git -C /opt/tools/ clone --depth 1 https://github.com/almandin/fuxploider.git
    cd /opt/tools/fuxploider || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases fuxploider
    add-history fuxploider
    add-test-command "fuxploider.py --help"
    add-to-list "fuxploider,https://github.com/almandin/fuxploider,a Python tool for finding and exploiting file upload forms/directories."
}

function install_gau() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing gau"
    go install github.com/lc/gau/v2/cmd/gau@latest
    asdf reshim golang
    add-history gau
    add-test-command "gau --help"
    add-to-list "gau,https://github.com/lc/gau,Fast tool for fetching URLs"
}

function install_git-dumper() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing git-dumper"
    uv tool install git-dumper
    add-history git-dumper
    add-test-command "git-dumper --help"
    add-to-list "git-dumper,https://github.com/arthaud/git-dumper,Small script to dump a Git repository from a website."
}

function install_gittools() {
    colorecho "Installing GitTools"
    git -C /opt/tools/ clone --depth 1 https://github.com/internetwache/GitTools.git
    cd /opt/tools/GitTools/Finder || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases gittools
    add-history gittools
    add-test-command "extractor.sh --help|& grep 'USAGE: extractor.sh GIT-DIR DEST-DIR'"
    add-test-command "gitdumper.sh --help|& grep 'USAGE: http://target.tld/.git/'"
    add-test-command "gitfinder.py -h"
    add-to-list "gittools,https://github.com/internetwache/GitTools,A collection of Git tools including a powerful Dumper for dumping Git repositories."
}

function install_gobuster() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing gobuster"
    go install -v github.com/OJ/gobuster/v3@latest
    asdf reshim golang
    add-history gobuster
    add-test-command "gobuster --help"
    add-to-list "gobuster,https://github.com/OJ/gobuster,Tool to discover hidden files and directories."
}

function install_gopherus() {
    colorecho "Installing gopherus"
    git -C /opt/tools/ clone --depth 1 https://github.com/tarunkant/Gopherus
    cd /opt/tools/Gopherus || exit
    python2 -m virtualenv --python python2 ./venv
    source ./venv/bin/activate
    pip2 install argparse requests
    deactivate
    add-aliases gopherus
    add-history gopherus
    add-test-command "gopherus.py --help"
    add-to-list "gopherus,https://github.com/tarunkant/Gopherus,Gopherus is a simple command line tool for exploiting vulnerable Gopher servers."
}

function install_gowitness() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing gowitness"
    go install -v github.com/sensepost/gowitness@latest
    asdf reshim golang
    add-history gowitness
    add-test-command "gowitness --help"
    add-test-command "gowitness scan single --url https://mandalore.readthedocs.io" # check the chromium dependency
    add-to-list "gowitness,https://github.com/sensepost/gowitness,A website screenshot utility written in Golang."
}

function install_h2csmuggler() {
    colorecho "Installing h2csmuggler"
    git -C /opt/tools/ clone --depth 1 https://github.com/BishopFox/h2csmuggler
    cd /opt/tools/h2csmuggler || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install h2
    deactivate
    add-aliases h2csmuggler
    add-history h2csmuggler
    add-test-command "h2csmuggler.py --help"
    add-to-list "h2csmuggler,https://github.com/BishopFox/h2csmuggler,HTTP Request Smuggling tool using H2C upgrade"
}

function install_hakrevdns() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Hakrevdns"
    go install -v github.com/hakluke/hakrevdns@latest
    asdf reshim golang
    add-history hakrevdns
    add-test-command "hakrevdns --help|& grep 'Protocol to use for lookups'"
    add-to-list "hakrevdns,https://github.com/hakluke/hakrevdns,Reverse DNS lookup utility that can help with discovering subdomains and other information."
}

function install_httpmethods() {
    colorecho "Installing httpmethods"
    git -C /opt/tools/ clone --depth 1 https://github.com/ShutdownRepo/httpmethods
    cd /opt/tools/httpmethods || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    # Upstream migrated from requirements.txt to pyproject.toml.
    uv pip install .
    deactivate
    add-aliases httpmethods
    add-history httpmethods
    add-test-command "httpmethods.py --help"
    add-to-list "httpmethods,https://github.com/ShutdownRepo/httpmethods,Tool for exploiting HTTP methods (e.g. PUT / DELETE / etc.)"
}

function install_httprobe() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing httprobe"
    go install -v github.com/tomnomnom/httprobe@latest
    asdf reshim golang
    add-history httprobe
    add-test-command "httprobe --help"
    add-to-list "httprobe,https://github.com/tomnomnom/httprobe,A simple utility for enumerating HTTP and HTTPS servers."
}

function install_httpx() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing httpx"
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    asdf reshim golang
    add-history httpx
    add-test-command "httpx --help"
    add-to-list "httpx,https://github.com/projectdiscovery/httpx,A tool for identifying web technologies and vulnerabilities / including outdated software versions and weak encryption protocols."
}

function install_joomscan() {
    colorecho "Installing joomscan"
    git -C /opt/tools/ clone --depth 1 https://github.com/rezasp/joomscan
    add-aliases joomscan
    add-history joomscan
    add-test-command "joomscan --version"
    add-to-list "joomscan,https://github.com/rezasp/joomscan,A tool to enumerate Joomla-based websites"
}

function install_jsluice() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing jsluice"
    go install -v github.com/BishopFox/jsluice/cmd/jsluice@latest
    asdf reshim golang
    add-history jsluice
    add-test-command "jsluice --help"
    add-to-list "jsluice,https://github.com/BishopFox/jsluice,Extract URLs / paths / secrets and other interesting data from JavaScript source code."
}

function install_jwt_tool() {
    colorecho "Installing JWT tool"
    git -C /opt/tools/ clone --depth 1 https://github.com/ticarpi/jwt_tool
    cd /opt/tools/jwt_tool || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    # Running the tool to create the initial configuration and force it to returns 0
    python3 jwt_tool.py || :
    deactivate
    
    # Configuration
    sed -i 's/^proxy = 127.0.0.1:8080/#proxy = 127.0.0.1:8080/' /root/.jwt_tool/jwtconf.ini
    sed -i 's|^wordlist = jwt-common.txt|wordlist = /opt/tools/jwt_tool/jwt-common.txt|' /root/.jwt_tool/jwtconf.ini
    sed -i 's|^commonHeaders = common-headers.txt|commonHeaders = /opt/tools/jwt_tool/common-headers.txt|' /root/.jwt_tool/jwtconf.ini
    sed -i 's|^commonPayloads = common-payloads.txt|commonPayloads = /opt/tools/jwt_tool/common-payloads.txt|' /root/.jwt_tool/jwtconf.ini

    add-aliases jwt_tool
    add-history jwt_tool
    add-test-command "jwt_tool.py --help"
    add-to-list "jwt,https://github.com/ticarpi/jwt_tool,a command-line tool for working with JSON Web Tokens (JWTs)"
}


function install_katana() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing katana"
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest
    asdf reshim golang
    add-history katana
    add-test-command "katana --help"
    add-to-list "katana,https://github.com/projectdiscovery/katana,A next-generation crawling and spidering framework."
}

function install_kiterunner() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing kiterunner (kr)"
    git -C /opt/tools/ clone --depth 1 https://github.com/assetnote/kiterunner.git
    cd /opt/tools/kiterunner || exit
    wget https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz
    wget https://wordlists-cdn.assetnote.io/data/kiterunner/routes-small.kite.tar.gz
    make build
    ln -v -s "$(pwd)/dist/kr" /opt/tools/bin/kr
    add-history kiterunner
    add-test-command "kr --help"
    add-to-list "kiterunner,https://github.com/assetnote/kiterunner,Tool for operating Active Directory environments."
}

function install_kraken() {
    colorecho "Installing Kraken"
    git -C /opt/tools clone --depth 1 --recursive --shallow-submodules https://github.com/kraken-ng/Kraken.git
    cd /opt/tools/Kraken || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases kraken
    add-history kraken
    add-test-command "kraken.py -h"
    add-to-list "Kraken,https://github.com/kraken-ng/Kraken,Kraken is a modular multi-language webshell focused on web post-exploitation and defense evasion. It supports three technologies (PHP / JSP and ASPX) and is core is developed in Python."
}

function install_linkfinder() {
    colorecho "Installing LinkFinder"
    git -C /opt/tools/ clone --depth 1 https://github.com/GerbenJavado/LinkFinder.git
    cd /opt/tools/LinkFinder || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases linkfinder
    add-history linkfinder
    add-test-command "linkfinder.py --help"
    add-to-list "linkfinder,https://github.com/GerbenJavado/LinkFinder,a Python script that finds endpoints and their parameters in JavaScript files."
}

function install_massdns() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing massdns"
    git -C /opt/tools clone --depth 1 https://github.com/blechschmidt/massdns.git
    cd /opt/tools/massdns || exit
    make
    ln -s /opt/tools/massdns/bin/massdns /opt/tools/bin/massdns
    add-history massdns
    add-test-command "massdns --help"
    add-to-list "massdns,https://github.com/blechschmidt/massdns,A high-performance DNS stub resolver for bulk lookups and reconnaissance (subdomain enumeration). Needed for shuffledns"
}

function install_moodlescan() {
    colorecho "Installing moodlescan"
    git -C /opt/tools/ clone --depth 1 https://github.com/inc0d3/moodlescan.git
    cd /opt/tools/moodlescan || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    cd /opt/tools/moodlescan || exit
    # updating moodlescan database
    catch_and_retry ./venv/bin/python3 moodlescan.py -a
    add-aliases moodlescan
    add-history moodlescan
    add-test-command "moodlescan.py --help"
    add-to-list "moodlescan,https://github.com/inc0d3/moodlescan,Scan Moodle sites for information and vulnerabilities."
}

function install_naabu() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing naabu"
    fapt libpcap-dev
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    asdf reshim golang
    add-history naabu
    add-test-command "naabu --help"
    add-to-list "naabu,https://github.com/projectdiscovery/naabu,A fast and reliable port scanner that can detect open ports and services."
}

function install_nosqlmap() {
    # CODE-CHECK-WHITELIST=add-history
    colorecho "Installing NoSQLMap"
    git -C /opt/tools clone --depth 1 https://github.com/codingo/NoSQLMap.git
    cd /opt/tools/NoSQLMap || exit
    python2 -m virtualenv --python python2 ./venv
    catch_and_retry ./venv/bin/python2 setup.py install
    # https://github.com/codingo/NoSQLMap/issues/126
    rm -rf venv/lib/python2.7/site-packages/certifi-2023.5.7-py2.7.egg
    source ./venv/bin/activate
    pip2 install certifi==2018.10.15
    deactivate
    add-aliases nosqlmap
    add-test-command "nosqlmap.py --help"
    add-to-list "nosqlmap,https://github.com/codingo/NoSQLMap,a Python tool for testing NoSQL databases for security vulnerabilities."
}

function install_nuclei() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Nuclei"
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    asdf reshim golang
    nuclei -update-templates
    add-history nuclei
    add-test-command "nuclei --version"
    add-to-list "nuclei,https://github.com/projectdiscovery/nuclei,A fast and customizable vulnerability scanner that can detect a wide range of issues / including XSS / SQL injection / and misconfigured servers."
}

function install_oneforall() {
    colorecho "Installing OneForAll"
    git -C /opt/tools/ clone --depth 1 https://github.com/shmilylty/OneForAll.git
    cd /opt/tools/OneForAll || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases oneforall
    add-history oneforall
    add-test-command "oneforall.py check"
    add-to-list "oneforall,https://github.com/shmilylty/OneForAll,a powerful subdomain collection tool."
}

function install_patator() {
    colorecho "Installing patator"
    fapt libmariadb-dev libcurl4-openssl-dev libssl-dev ldap-utils libpq-dev ike-scan unzip default-jdk libsqlite3-dev libsqlcipher-dev
    git -C /opt/tools clone --depth 1 https://github.com/lanjelot/patator.git
    cd /opt/tools/patator || exit
    # Patator upstream's pyproject.toml requires Python >= 3.13 (telnetlib-313-and-up dep),
    # so 3.11 is out. On 3.13, cx_Oracle 8.3 (pinned in requirements.txt) needs the
    # legacy `pkg_resources` API which was removed from setuptools 81. Pin setuptools<81
    # in the venv and use --no-build-isolation so cx_Oracle's setup.py finds it.
    uv venv --python 3.13 --seed ./venv
    source ./venv/bin/activate
    uv pip install 'setuptools<81' wheel
    uv pip install --no-build-isolation -r requirements.txt
    deactivate
    add-aliases patator
    add-history patator
    add-test-command "patator.py ftp_login --help"
    add-to-list "patator,https://github.com/lanjelot/patator,Login scanner."
}

function install_php_filter_chain_generator() {
    colorecho "Installing PHP_Filter_Chain_Generator"
    git -C /opt/tools/ clone --depth 1 https://github.com/synacktiv/php_filter_chain_generator.git
    add-aliases php_filter_chain_generator
    add-history php_filter_chain_generator
    add-test-command "php_filter_chain_generator.py --help"
    add-to-list "PHP filter chain generator,https://github.com/synacktiv/php_filter_chain_generator,A CLI to generate PHP filters chain / get your RCE without uploading a file if you control entirely the parameter passed to a require or an include in PHP!"
}

function install_phpggc() {
    colorecho "Installing phpggc"
    git -C /opt/tools clone --depth 1 https://github.com/ambionics/phpggc.git
    add-aliases phpggc
    add-history phpggc
    add-test-command "phpggc --help"
    add-to-list "phpggc,https://github.com/ambionics/phpggc,Exploit generation tool for the PHP platform."
}

function install_symfony-exploits(){
    colorecho "Installing symfony-exploits"
    git -C /opt/tools clone --depth 1 https://github.com/ambionics/symfony-exploits
    add-aliases symfony-exploits
    add-history symfony-exploits
    add-test-command "secret_fragment_exploit.py --help"
    add-to-list "symfony-exploits,https://github.com/ambionics/symfony-exploits,Collection of Symfony exploits and PoCs."
}

function install_jdwp_shellifier(){
    colorecho "Installing jdwp_shellifier"
    git -C /opt/tools/ clone --depth 1 https://github.com/IOActive/jdwp-shellifier
    add-aliases jdwp-shellifier
    add-history jdwp-shellifier
    add-test-command "jdwp-shellifier.py --help"
    add-to-list "jdwp,https://github.com/IOActive/jdwp-shellifier,This exploitation script is meant to be used by pentesters against active JDWP service / in order to gain Remote Code Execution."
}

function install_robotstester() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing Robotstester"
    uv tool install git+https://github.com/p0dalirius/robotstester
    add-history robotstester
    add-test-command "robotstester --help"
    add-to-list "robotstester,https://github.com/p0dalirius/robotstester,Utility for testing whether a website's robots.txt file is correctly configured."
}

function install_soapui() {
    colorecho "Installing SoapUI"
    mkdir -p /opt/tools/SoapUI/
    wget https://dl.eviware.com/soapuios/5.7.0/SoapUI-5.7.0-linux-bin.tar.gz -O /tmp/SoapUI.tar.gz
    tar xvf /tmp/SoapUI.tar.gz -C /opt/tools/SoapUI/ --strip=1

    # Fix for ARM64: Replace bundled x86_64 JavaFX libs with AArch64 ones
    if [[ $(uname -m) = 'aarch64' ]]; then
        colorecho "Fixing SoapUI for ARM64..."
        # Gluon OpenJFX 17 ARM64 builds are restricted/unavailable directly.
        # Using BellSoft Liberica JDK 17 Full which bundles JavaFX for ARM64.
        wget https://download.bell- sw.com/java/17.0.10+13/bellsoft-jdk17.0.10+13-linux-aarch64-full.tar.gz -O /tmp/liberica.tar.gz
        tar xvf /tmp/liberica.tar.gz -C /tmp/
        # Copy JavaFX jars from Liberica to SoapUI
        # Liberica structure: jdk-17.0.10-full/lib/
        yes | cp -rf /tmp/jdk-17.0.10-full/lib/javafx*.jar /opt/tools/SoapUI/lib/
        rm -rf /tmp/liberica.tar.gz /tmp/jdk-17.0.10-full
    fi
    add-aliases soapui
    add-history soapui
    add-test-command "/opt/tools/SoapUI/bin/testrunner.sh"
    add-to-list "SoapUI,https://github.com/SmartBear/soapui,SoapUI is the world's leading testing tool for API testing."
}

function install_sqlmap() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing sqlmap"
    git -C /opt/tools/ clone --depth 1 https://github.com/sqlmapproject/sqlmap.git
    ln -s "/opt/tools/sqlmap/sqlmap.py" /opt/tools/bin/sqlmap
    add-history sqlmap
    add-test-command "sqlmap --version"
    add-to-list "sqlmap,https://github.com/sqlmapproject/sqlmap,Sqlmap is an open-source penetration testing tool that automates the process of detecting and exploiting SQL injection flaws"
}

function install_sslscan() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing sslscan"
    git -C /tmp clone --depth 1 https://github.com/rbsec/sslscan.git
    cd /tmp/sslscan || exit
    make static
    mv /tmp/sslscan/sslscan /opt/tools/bin/sslscan
    add-history sslscan
    add-test-command "sslscan --version"
    add-to-list "sslscan,https://github.com/rbsec/sslscan,a tool for testing SSL/TLS encryption on servers"
}

function install_ssrfmap() {
    colorecho "Installing SSRFmap"
    git -C /opt/tools/ clone --depth 1 https://github.com/swisskyrepo/SSRFmap
    cd /opt/tools/SSRFmap || exit
    uv venv --python 3.13 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r pyproject.toml
    deactivate
    add-aliases ssrfmap
    add-history ssrfmap
    add-test-command "ssrfmap.py --help"
    add-to-list "ssrfmap,https://github.com/swisskyrepo/SSRFmap,a tool for testing SSRF vulnerabilities."
}

function install_testssl() {
    colorecho "Installing testssl"
    # TODO : Check if deps are already installed
    fapt bsdmainutils
    git -C /opt/tools/ clone --depth 1 https://github.com/testssl/testssl.sh.git
    add-aliases testssl
    add-history testssl
    add-test-command "testssl.sh --help"
    add-to-list "testssl,https://github.com/testssl/testssl.sh,a tool for testing SSL/TLS encryption on servers"
}

function install_timing_attack() {
    colorecho "Installing timing_attack"
    rvm use 3.2.2@timing_attack --create
    gem install timing_attack
    rvm use 3.2.2@default
    add-aliases timing_attack
    add-history timing_attack
    add-test-command "timing_attack --help"
    add-to-list "timing,https://github.com/ffleming/timing_attack,Tool to generate a timing profile for a given command."
}

function install_token_exploiter() {
    # CODE-CHECK-WHITELIST=add-aliases,add-history
    colorecho "Installing Token Exploiter"
    uv tool install git+https://github.com/psyray/token-exploiter
    add-test-command "token-exploiter --help"
    add-to-list "token-exploiter,https://github.com/psyray/token-exploiter,Token Exploiter is a tool designed to analyze GitHub Personal Access Tokens."
}

function install_tomcatwardeployer() {
    colorecho "Installing tomcatWarDeployer"
    git -C /opt/tools/ clone --depth 1 https://github.com/mgeeky/tomcatWarDeployer.git
    cd /opt/tools/tomcatWarDeployer || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases tomcatwardeployer
    add-history tomcatwardeployer
    add-test-command "tomcatWarDeployer.py --help"
    add-to-list "tomcatwardeployer,https://github.com/mgeeky/tomcatwardeployer,Script to deploy war file in Tomcat."
}

function install_updog() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing updog"
    uv tool install updog
    add-history updog
    add-test-command "updog --help"
    add-to-list "updog,https://github.com/sc0tfree/updog,Simple replacement for Python's SimpleHTTPServer."
}

function install_wafw00f() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing wafw00f"
    uv tool install wafw00F
    add-history wafw00f
    add-test-command "wafw00f --help"
    add-to-list "wafw00f,https://github.com/EnableSecurity/wafw00f,a Python tool that helps to identify and fingerprint web application firewall (WAF) products."
}

function install_weevely() {
    colorecho "Installing weevely"
    uv tool install https://github.com/epinna/weevely3.git
    add-aliases weevely
    add-history weevely
    add-test-command "weevely.py --help"
    add-to-list "weevely,https://github.com/epinna/weevely3,a webshell designed for post-exploitation purposes that can be extended over the network at runtime."
}

function install_whatweb() {
    colorecho "Installing whatweb"
    git -C /opt/tools clone --depth 1 https://github.com/urbanadventurer/WhatWeb.git
    rvm use 3.2.2@whatweb --create
    gem install addressable
    bundle install --gemfile /opt/tools/WhatWeb/Gemfile
    rvm use 3.2.2@default
    add-aliases whatweb
    add-history whatweb
    add-test-command "whatweb --version"
    add-to-list "whatweb,https://github.com/urbanadventurer/WhatWeb,Next generation web scanner that identifies what websites are running."

}

function install_wpprobe() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing wpprobe"
    go install -v github.com/Chocapikk/wpprobe@latest
    asdf reshim golang
    add-history wpprobe
    add-test-command "wpprobe --help"
    add-to-list "wpprobe,https://github.com/Chocapikk/wpprobe,A fast WordPress plugin enumeration tool."
}

function install_wpscan() {
    colorecho "Installing wpscan"
    rvm use 3.2.2@wpscan --create
    gem install wpscan
    rvm use 3.2.2@default
    add-aliases wpscan
    add-history wpscan
    add-test-command "wpscan --help"
    add-to-list "wpscan,https://github.com/wpscanteam/wpscan,A tool to enumerate WordPress-based websites"
}

function install_xspear() {
    colorecho "Installing XSpear"
    rvm use 3.2.2@xspear --create
    gem install XSpear
    rvm use 3.2.2@default
    add-aliases Xspear
    add-history XSpear
    add-test-command "XSpear --help"
    add-to-list "XSpear,https://github.com/hahwul/XSpear,a powerful XSS scanning and exploitation tool."
}

function install_xsrfprobe() {
    # CODE-CHECK-WHITELIST=add-aliases
    colorecho "Installing XSRFProbe"
    uv tool install git+https://github.com/0xInfection/XSRFProbe
    add-history xsrfprobe
    add-test-command "xsrfprobe --help"
    add-to-list "xsrfprobe,https://github.com/0xInfection/XSRFProbe,a tool for detecting and exploiting Cross-Site Request Forgery (CSRF) vulnerabilities"
}

function install_xsser() {
    colorecho "Installing xsser"
    git -C /opt/tools clone --depth 1 https://github.com/epsylon/xsser.git
    cd /opt/tools/xsser || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install pycurl bs4 pygeoip gobject cairocffi selenium
    deactivate
    add-aliases xsser
    add-history xsser
    add-test-command "xsser --help"
    add-to-list "xsser,https://github.com/epsylon/xsser,XSS scanner."
}

function install_xsstrike() {
    colorecho "Installing XSStrike"
    git -C /opt/tools/ clone --depth 1 https://github.com/s0md3v/XSStrike.git
    cd /opt/tools/XSStrike || exit
    uv venv --python 3.11 --seed ./venv
    source ./venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
    add-aliases xsstrike
    add-history xsstrike
    add-test-command "xsstrike.py --help"
    add-to-list "xsstrike,https://github.com/s0md3v/XSStrike,a Python tool for detecting and exploiting XSS vulnerabilities."
}

function install_ysoserial() {
    colorecho "Installing ysoserial"
    mkdir /opt/tools/ysoserial/
    wget -O /opt/tools/ysoserial/ysoserial.jar "https://github.com/frohoff/ysoserial/releases/latest/download/ysoserial-all.jar"
    add-aliases ysoserial
    add-history ysoserial
    add-test-command "ysoserial --help|& grep 'spring-core:4.1.4.RELEASE'"
    add-test-command "ysoserial CommonsCollections4 'whoami'"
    add-to-list "ysoserial,https://github.com/frohoff/ysoserial,A proof-of-concept tool for generating payloads that exploit unsafe Java object deserialization."
}

# Package dedicated to applicative and active web pentest tools
function package_web() {
    set_env
    init_failure_tracking
    local start_time
    local end_time
    start_time=$(date +%s)
    safe_install web install_web_apt_tools
    safe_install web install_amass                   # Web fuzzer
    safe_install web install_anew                    # A tool for adding new lines to files, skipping duplicates
    safe_install web install_arjun                   # HTTP Parameter Discovery
    safe_install web install_bbot                    # Recursive Scanner
    safe_install web install_bolt                    # CSRF scanner
    safe_install web install_caido
    safe_install web install_cloudfail               # Cloudflare misconfiguration detector
    safe_install web install_corscanner              # CORS misconfiguration detector
    safe_install web install_droopescan              # Drupal scanner
    safe_install web install_eyewitness              # Website screenshoter
    safe_install web install_feroxbuster             # ffuf but with multithreaded recursion
    safe_install web install_ffuf                    # Web fuzzer (little favorites)
    safe_install web install_fuxploider              # File upload scanner
    safe_install web install_gau                     # fetches known URLs from AlienVault's Open Threat Exchange, the Wayback Machine, Common Crawl, and URLScan
    safe_install web install_git-dumper              # Dump a git repository from a website
    safe_install web install_gittools                # Dump a git repository from a website
    safe_install web install_gobuster                # Web fuzzer (pretty good for several extensions)
    safe_install web install_gopherus                # SSRF helper
    safe_install web install_gowitness               # Web screenshot utility
    safe_install web install_h2csmuggler             # Tool for HTTP2 smuggling
    safe_install web install_hakrevdns               # Reverse DNS lookups
    safe_install web install_httpmethods             # Tool for HTTP methods enum & verb tampering
    safe_install web install_httprobe                # Probe http
    safe_install web install_httpx                   # Probe http
    safe_install web install_jdwp_shellifier         # exploit java debug
    safe_install web install_joomscan                # Joomla scanner
    safe_install web install_jsluice                 # Extract URLs, paths, secrets, and other interesting data from JavaScript source code
    safe_install web install_jwt_tool                # Toolkit for validating, forging, scanning and tampering JWTs
    safe_install web install_katana                  # A next-generation crawling and spidering framework
    safe_install web install_kiterunner              # Web fuzzer (fast and pretty good for api bruteforce)
    safe_install web install_kraken                  # Kraken is a modular multi-language webshell.
    safe_install web install_linkfinder              # Discovers endpoint JS files
    safe_install web install_massdns                 # DNS resolver (Needed for shuffledns)
    safe_install web install_moodlescan              # Moodle scanner
    safe_install web install_naabu                   # Fast port scanner
    safe_install web install_nosqlmap                # NoSQL scanner
    safe_install web install_nuclei                  # Vulnerability scanner - Needed for gau install
    safe_install web install_oneforall               # OneForAll is a powerful subdomain integration tool
    safe_install web install_patator                 # Login scanner
    safe_install web install_php_filter_chain_generator # A CLI to generate PHP filters chain and get your RCE
    safe_install web install_phpggc                  # php deserialization payloads
    safe_install web install_robotstester            # Robots.txt scanner
    safe_install web install_soapui                  # SoapUI is an open-source web service testing application for SOAP and REST
    safe_install web install_sqlmap                  # SQL injection scanner
    safe_install web install_sslscan                 # SSL/TLS scanner
    safe_install web install_ssrfmap                 # SSRF scanner
    safe_install web install_symfony-exploits        # symfony secret fragments exploit
    safe_install web install_testssl                 # SSL/TLS scanner
    safe_install web install_timing_attack           # Cryptocraphic timing attack
    safe_install web install_token_exploiter         # Github personal token Analyzer
    safe_install web install_tomcatwardeployer       # Apache Tomcat auto WAR deployment & pwning tool
    safe_install web install_updog                   # New HTTPServer
    safe_install web install_wafw00f                 # Waf detector
    safe_install web install_weevely                 # Weaponized web shell
    safe_install web install_whatweb                 # Recognises web technologies including content management
    safe_install web install_wpprobe                 # WordPress plugin scanner
    safe_install web install_wpscan                  # Wordpress scanner
    safe_install web install_xspear                  # XSS scanner
    safe_install web install_xsrfprobe               # CSRF scanner
    safe_install web install_xsser                   # XSS scanner
    safe_install web install_xsstrike                # XSS scanner
    safe_install web install_ysoserial               # Deserialization payloads
    print_failure_summary
    post_install
    end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    colorecho "Package web completed in $elapsed_time seconds."
}
