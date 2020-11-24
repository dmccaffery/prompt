#!/usr/bin/env sh

set -e

__am_prompt_ensure_rosetta() {

    # determine if we are on x86
    if [ "$(uname -m)" = "x86_64" ]; then

        # install homebrew using defaults
        __am_prompt_install_darwin

        # move on immediately
        return $?
    fi

    # install rosetta 2
    softwareupdate --install-rosetta --agree-to-license

    # create the homebrew directory
    if [ ! -d "/opt/homebrew" ]; then

        # create the homebrew path
        sudo mkdir -p /opt/homebrew

        # chown the path
        sudo chown /opt/homebrew $(whoami):staff
    fi

    # install homebrew in rosetta
    __am_prompt_install_darwin x86_64 /usr/local

    # install homebrew for apple silicon
    __am_prompt_ensure_rosetta $(uname -m) /opt/homebrew
}

__am_prompt_install_darwin() {
    local BREWS='openssl git go nvm python'
    local ARCH=${1:-"x86-64"}
    local HOMEBREW_PREFIX="${2:-/usr/local}"
    local BREW_CMD="${HOMEBREW_PREFIX}/bin/brew"

    if ! type "${BREW_CMD}" 1>/dev/null 2>&1; then
        $ECHO "${CLR_SUCCESS}installing homebrew...${CLR_CLEAR}"
        arch -${ARCH} /bin/bash -c "HOMEBREW_PREFIX=${HOMEBREW_PREFIX} CI=true $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh) && ${BREW_CMD} config"
    fi

    $ECHO "${CLR_SUCCESS}updating homebrew...${CLR_CLEAR}"
    ${BREW_CMD} update

    set +e

    for pkg in $BREWS; do
        if ${BREW_CMD} list --formula -1 | grep -q "^${pkg}\$"; then
            $ECHO "${CLR_SUCCESS}upgrading: $pkg...${CLR_CLEAR}"
            ${BREW_CMD} upgrade $pkg 2>/dev/null
            ${BREW_CMD} link --overwrite $pkg 2>/dev/null
        else
            $ECHO "${CLR_SUCCESS}installing: $pkg...${CLR_CLEAR}"
            ${BREW_CMD} install $pkg
        fi
    done

    local NVM_PATH=$(${BREW_CMD} --prefix nvm)

    if [ -f "$NVM_PATH/nvm.sh" ]; then
        $ECHO "${CLR_SUCCESS}setting up nvm...${CLR_CLEAR}"
        export NVM_DIR="${HOME}/.nvm"
        . "$NVM_PATH/nvm.sh"
        nvm install --lts 2>/dev/null
        nvm use --lts --delete-prefix --silent 2>/dev/null
    fi

    $ECHO "${CLR_SUCCESS}setting git credential helper to use the macOS keychain${CLR_CLEAR}"
    git config --system credential.helper osxkeychain
}

__am_prompt_ensure_rosetta
