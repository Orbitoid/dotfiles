# Linked into ~/.config/fish/conf.d/ by install.sh.

if not command -q brew
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
        if test -x $b
            $b shellenv fish | source
            break
        end
    end
end

fish_add_path -g ~/.local/bin
