export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="fishy"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 5

HIST_STAMPS="dd/mm/yyyy"

plugins=(
  aliases
  cabal
  colored-man-pages
  docker
  fzf
  gh
  git
  gitignore
  rust
  ssh
  zoxide
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

export LANG=en_US.UTF-8
export TERMINAL=kitty
export BROWSER=brave

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias zshrc="nvim ~/.zshrc"
alias i3rc="nvim ~/.config/i3/config"

cf() {
  "$EDITOR" "$HOME/.config/$1"
}
_cf() {
  local config_dir="$HOME/.config"
  _arguments "1: :($(ls -1d $config_dir/*(/) 2>/dev/null | xargs -n1 basename))"
}
compdef _cf cf

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export CHROME_EXECUTABLE=/usr/bin/chromium
export PATH="$HOME/fvm/default/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="/opt/cuda/bin:$PATH"
export CUDA_PATH="/opt/cuda"
export NVCC_CCBIN="/usr/bin/g++"
export XDG_DATA_DIRS="$XDG_DATA_DIRS:$HOME/Desktop"
export MAKEFLAGS="-j$(nproc)"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/smule/.dart-cli-completion/zsh-config.zsh ]] && . /home/smule/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]



[ -f "/home/smule/.ghcup/env" ] && . "/home/smule/.ghcup/env" # ghcup-env

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
export PATH="/home/smule/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/smule/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
