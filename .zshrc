#export LDFLAGS="-L$(brew --prefix openssl@1.1)/lib" 
#export CFLAGS="-I$(brew --prefix openssl@1.1)/include"
# fpath+=("$(brew --prefix)/share/zsh/site-functions")
# autoload -U promptinit; promptinit
# prompt pure
bindkey -e

eval "$(/opt/homebrew/bin/brew shellenv)"
PATH=:$PATH:/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/

export PIP_REQUIRE_VIRTUALENV=true
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="/Users/sebastian/.local/bin:$PATH"

# source <(kubectl completion bash)
export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#
alias t="todo.sh"
alias cfg="just --justfile ~/.cfg/.justfile --working-directory ."
