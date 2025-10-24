
#!/bin/bash
set -e

# ======================================================
# CONFIGURAÇÕES INICIAIS
# ======================================================

# Usuário e diretórios
USER_NAME=dev
HOME_DIR=/home/$USER_NAME
HOMEBREW_PREFIX=$HOME_DIR/.linuxbrew
NPM_GLOBAL_DIR=$HOME_DIR/.npm-global

# URLs dos instaladores
UV_INSTALL_URL="https://astral.sh/uv/install.sh"
NODE_SETUP_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
RUST_INSTALL_URL="https://sh.rustup.rs"
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
HELIX_KEY_URL="https://packages.helix-editor.com/apt/key.asc"
HELIX_REPO_URL="https://packages.helix-editor.com/apt/"

# Pacotes npm globais
NPM_PACKAGES=(
  typescript
  typescript-language-server
  vscode-langservers-extracted
  vue-tsc
  @vue/language-server
  @vue/typescript-plugin
  @tailwindcss/language-server
)

# Pacotes uv
UV_PACKAGES=(
  basedpyright==1.18.2
  ruff==0.7.2
)

# Brew packages
BREW_PACKAGES=(
  lua-language-server
  marksman
)

# ======================================================
# CONFIGURAR AMBIENTE
# ======================================================
export HOME=$HOME_DIR
export USER=$USER_NAME
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$NPM_GLOBAL_DIR/bin:$PATH"

mkdir -p $HOME_DIR
mkdir -p $HOMEBREW_PREFIX
mkdir -p $NPM_GLOBAL_DIR

# ======================================================
# ATUALIZAR APT E INSTALAR DEPENDÊNCIAS BASE
# ======================================================
sudo apt-get update
sudo apt-get install -y \
  curl git sudo wget nano vim build-essential pkg-config gcc g++ \
  libssl-dev zlib1g-dev libncurses5-dev libreadline-dev libsqlite3-dev \
  libffi-dev liblzma-dev \
  python3 python3-venv python3-pip python3-wheel \
  lua5.4

# ======================================================
# UV PACKAGE MANAGER
# ======================================================
curl -LsSf $UV_INSTALL_URL | sh

for pkg in "${UV_PACKAGES[@]}"; do
  uv tool install "$pkg"
done

# ======================================================
# NODE.JS + NPM
# ======================================================
curl -o- $NODE_SETUP_URL | PROFILE="/dev/null" bash
export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install --lts
nvm use --lts
NODE_VERSION=$(node -v)          # Ex.: v18.19.1
nvm alias default "$NODE_VERSION"

npm config set prefix "$NPM_GLOBAL_DIR"
export PATH="$NPM_GLOBAL_DIR/bin:$PATH"

npm install -g "${NPM_PACKAGES[@]}"

# ======================================================
# RUST
# ======================================================
curl --proto '=https' --tlsv1.2 -sSf $RUST_INSTALL_URL | sh -s -- -y
rustup component add clippy rust-src rustfmt rust-analyzer
cargo install taplo-cli --locked --features lsp

# ======================================================
# HOMEBREW
# ======================================================
/bin/bash -c "$(curl -fsSL $BREW_INSTALL_URL)"
brew install "${BREW_PACKAGES[@]}"
brew cleanup -s
rm -rf "$(brew --cache)"

# ======================================================
# HELIX
# ======================================================
curl -fsSL $HELIX_KEY_URL | sudo tee /etc/apt/trusted.gpg.d/helix.asc > /dev/null
echo "deb [arch=$(dpkg --print-architecture)] $HELIX_REPO_URL stable main" | sudo tee /etc/apt/sources.list.d/helix.list
sudo apt-get update
sudo apt-get install -y helix
