# Sourced from ~/.bashrc by install.sh: PATH setup + `tm` completion.

if ! command -v brew >/dev/null 2>&1; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
    done
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac

_tm() {
    local cur=${COMP_WORDS[COMP_CWORD]} line restore
    local -a args=("$cur")
    COMPREPLY=()
    [ "$COMP_CWORD" -gt 1 ] && args+=("${COMP_WORDS[1]}")
    restore=$(shopt -p nocasematch)
    shopt -s nocasematch
    while IFS= read -r line; do
        line=${line%%$'\t'*}
        case $line in
            "$cur"*) COMPREPLY+=("$(printf '%q' "$line")") ;;
        esac
    done < <(tm --complete "${args[@]}")
    eval "$restore"
}
complete -o nosort -F _tm tm 2>/dev/null || complete -F _tm tm
