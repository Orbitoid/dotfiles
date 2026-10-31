# dotfiles

tmux, fish, Alacritty, and a Neovim setup in the style of ThePrimeagen's, plus
`tm`, a small tmux session launcher, and `term-setup`, a setup wizard for the
terminal's look. Works on macOS and most Linux distros (Arch/CachyOS,
Mint/Ubuntu/Debian, Fedora, SteamOS, Bazzite).

## Install

```sh
git clone https://github.com/Orbitoid/dotfiles ~/dotfiles
~/dotfiles/install.sh              # packages + configs
~/dotfiles/install.sh --no-packages   # configs only
```

The installer:

- installs `tmux fish neovim ripgrep fd git gcc make unzip node` and the
  `tree-sitter` CLI with the system package manager. It uses Homebrew on macOS
  and on immutable systems (SteamOS, Bazzite).
- downloads the official Neovim build into `~/.local` when the distro's version
  is older than 0.11 (e.g. on Mint).
- symlinks the configs into place. Anything it would replace is renamed to
  `*.bak.<timestamp>`.
- fetches the tmux and Neovim plugins.

Re-run it any time; it skips anything already done. Configs are symlinks, so
`git pull` updates them straight away.

| Repo | Linked to |
|---|---|
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `nvim/` | `~/.config/nvim` |
| `bin/tm` | `~/.local/bin/tm` |
| `bin/term-setup` | `~/.local/bin/term-setup` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `fish/conf.d/prompt.fish` | `~/.config/fish/conf.d/` (written by `term-setup`) |
| `starship/starship.toml` | `~/.config/starship.toml` (written by `term-setup`) |
| `fish/conf.d/dotfiles.fish` | `~/.config/fish/conf.d/` (PATH, Homebrew) |
| `fish/completions/tm.fish` | `~/.config/fish/completions/` |
| `shell/tm.bash`, `shell/tm.zsh` | sourced from `~/.bashrc` / `~/.zshrc` |

## term-setup

Run `term-setup` to change how the terminal looks without editing config files:

- **Transparency** and **font size**: Left/Right. Alacritty updates live.
- **Font**: five popular Nerd Fonts (JetBrains Mono, Fira Code, Hack, Meslo,
  Cascadia), downloaded and installed on demand, or `/` to search every
  installed monospace font. The highlighted font is previewed live.
- **Prompt**: fish's built-in prompts and, if starship is installed, starship's
  presets. Each is previewed in a home folder, a git repo with changes, and
  after a failed command.

Esc cancels and restores everything. Saved changes land in this repo, so commit
and push them to get them on your other machines. The prompt applies to fish
only.

## Keeping secrets out

This repo is public, so git hooks in `.githooks/` (switched on by `install.sh`
via `core.hooksPath`) block any commit or push that would publish:

- keys and tokens: private keys, AWS/GitHub/Anthropic/OpenAI/Slack/Google/Stripe
  keys, JWTs, passwords in URLs, and password, token or API-key assignments
- personal info: email addresses, IP addresses, `/home/<user>` paths, and every
  string in `~/.config/dotfiles/private-strings` (your name, address, phone, ...).
  That list lives outside the repo, so it's never published itself.
- risky files: `.env`, SSH keys, `*.pem`/`*.key`, shell history,
  `fish_variables`, `.bak` files, binaries
- commits whose author email isn't a GitHub `noreply` address

It checks staged changes (pre-commit), the commit message (commit-msg), and
every commit about to be pushed (pre-push). [gitleaks](https://github.com/gitleaks/gitleaks)
also runs as a second scanner. Run `.githooks/check-private all` to scan the
whole history by hand.

For a reviewed false positive, put `allow-private` on that line. `--no-verify`
skips the commit hooks, but the pre-push hook still checks those commits
unless you skip it as well.

## tm

| Command | Does |
|---|---|
| `tm` | attach to the most recent session (or start one) |
| `tm NAME` | attach to `NAME`, creating it if needed |
| `tm <Tab>` | running sessions, most recent first |
| `tm abc<Tab>` | sessions starting with `abc`; if none, folders in `~/active_workspaces` |

New sessions start in `~/active_workspaces/NAME` if that folder exists. Set
`TM_WORKSPACES` to use a different folder.

## tmux

Prefix is **Ctrl+a**.

| Keys | Action |
|---|---|
| `C-a d` | detach |
| `C-a c` | new window |
| `C-a n` / `C-a p` | next / previous window |
| `C-a x` | kill window (asks first) |
| <code>C-a &#124;</code> | split left/right |
| `C-a _` | split top/bottom |
| `C-a r` | reload config |

Sessions are saved every 5 minutes (tmux-resurrect + tmux-continuum). The first
`tm` after a reboot restores them: windows, splits, working directories and
on-screen text. Most programs restart as a fresh shell, apart from a few like
vim and less.

## Neovim

Leader is **Space**. Plugins are managed by lazy.nvim: telescope, harpoon,
treesitter, LSP (mason + nvim-cmp), fugitive, undotree, rose-pine.

| Keys | Action |
|---|---|
| `<leader>pv` | file explorer |
| `<leader>pf` / `C-p` | find files / git files |
| `<leader>ps` | grep |
| `<leader>a` / `C-e` | harpoon add / menu |
| `C-h C-t C-n C-s` | harpoon files 1–4 |
| `<leader>u` | undotree |
| `<leader>gs` | git status (fugitive) |
| `gd`, `K`, `<leader>vca`, `<leader>vrn` | LSP definition, hover, code action, rename |
| `<leader>f` | format |
| `<leader>y` | yank to system clipboard |

Install more language servers with `:Mason`. They're enabled automatically.
