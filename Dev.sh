
#!/bin/bash
set -e

# ======================================================
# CONFIGURAÇÕES INICIAIS
# ======================================================

# Usuário e diretórios
LOCK_UPDATE=true
USER_NAME=dev
HOME_DIR=/home/$USER_NAME
HOMEBREW_PREFIX=$HOME_DIR/.linuxbrew
NPM_GLOBAL_DIR=$HOME_DIR/.npm-global

# URLs dos instaladores
UV_INSTALL_URL="https://astral.sh/uv/install.sh"
NODE_SETUP_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
RUST_INSTALL_URL="https://sh.rustup.rs"
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
REPO="https://raw.githubusercontent.com/NeatlySimplify/setup/main"

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
  basedpyright
  ruff
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

mkdir -p "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.config/helix" "$NPM_GLOBAL_DIR"


# ======================================================
# ATUALIZAR APT E INSTALAR DEPENDÊNCIAS BASE
# ======================================================
sudo apt-get update
sudo apt-get install -y \
  curl git sudo wget nano vim build-essential pkg-config gcc g++ software-properties-common \
  libssl-dev zlib1g-dev libncurses5-dev libreadline-dev libsqlite3-dev \
  libffi-dev liblzma-dev \
  python3 python3-venv python3-pip python3-wheel \
  lua5.4


# ======================================================
# HELIX
# ======================================================
sudo add-apt-repository ppa:maveonair/helix-editor
sudo apt-get update
sudo apt-get install -y helix


# ======================================================
# UV PACKAGE MANAGER
# ======================================================
curl --retry 5 --retry-delay 3 -LsSf $UV_INSTALL_URL | sh

for pkg in "${UV_PACKAGES[@]}"; do
  uv tool install "$pkg"
done

# ======================================================
# NODE.JS + NPM
# ======================================================
curl --retry 5 --retry-delay 3 -o- "$NODE_SETUP_URL" | bash

# Carrega o NVM no shell atual
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Instala e define a versão LTS como padrão
nvm install --lts
nvm use --lts
NODE_VERSION=$(node -v)  # Exemplo: v18.19.1
nvm alias default "$NODE_VERSION"

# Garante que o npm use o prefixo do nvm (caso tenha sobras de .npmrc antigo)
rm -f "$HOME/.npmrc"

# Atualiza o npm e instala os pacotes globais
npm install -g npm@latest
npm install -g "${NPM_PACKAGES[@]}"

# ======================================================
# RUST
# ======================================================
curl --retry 5 --retry-delay 3 --proto '=https' --tlsv1.2 -sSf $RUST_INSTALL_URL | sh -s -- -y
rustup component add clippy rust-src rustfmt rust-analyzer
cargo install taplo-cli --locked --features lsp

# ======================================================
# HOMEBREW
# ======================================================
/bin/bash -c "$(curl --retry 5 --retry-delay 3 -fsSL $BREW_INSTALL_URL)"
echo >> /home/dev/.bashrc
    echo 'eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"' >> /home/dev/.bashrc
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
brew install "${BREW_PACKAGES[@]}"
brew cleanup -s
rm -rf "$(brew --cache)"


# ======================================================
# HELIX LANGUAGE CONFIG
# ======================================================
mkdir -p "$HOME/.config/helix/"
curl --retry 5 --retry-delay 3 -fsSL "$REPO/helix-lsp.toml" -o "$HOME/.config/helix/languages.toml"

update_system() {
  echo "🧩 Atualizando sistema..."
  sudo apt-get update && sudo apt-get upgrade -y
}

update_npm() {
  echo "📦 Atualizando npm..."
  npm install -g @npm/latest
  npm install
}

update_uv() {
  echo "⚙️ Atualizando uv..."
  uv self update || echo "uv não encontrado, pulando..."
}

update_rust() {
  echo "🦀 Atualizando Rust..."
  rustup update
}

update_brew() {
  echo "🍺 Atualizando Homebrew..."
  brew tap domt4/autoupdate
  brew autoupdate start
}

# ======================================================
# EXECUÇÃO CONDICIONAL DO BLOCO DE ATUALIZAÇÃO
# ======================================================

if [ "$LOCK_UPDATE" = false ]; then
  update_system
  update_npm
  update_uv
  update_rust
  update_brew
else
  echo "🔒 Atualizações travadas (LOCK_UPDATE=true). Pulando updates."
fi


