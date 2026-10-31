# Sourced from ~/.zshrc by install.sh: PATH setup + `tm` completion.

if (( ! $+commands[brew] )); then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [[ -x $b ]] && { eval "$($b shellenv)"; break; }
    done
fi

typeset -U path
path=("$HOME/.local/bin" $path)

_tm() {
    (( CURRENT == 2 )) || return
    local -a names
    names=("${(@f)$(tm --complete "$PREFIX" | cut -f1)}")
    names=(${names:#})
    compadd -V tm -M 'm:{a-zA-Z}={A-Za-z}' -a names
}
(( $+functions[compdef] )) || { autoload -Uz compinit && compinit }
compdef _tm tm
