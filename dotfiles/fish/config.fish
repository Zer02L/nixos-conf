# fish config — live, sourced via interactiveShellInit

# aliases
# alias pi omp
alias vim nvim
alias vi nvim
alias ll 'eza -l --icons'
alias la 'eza -la --icons'
alias lt 'eza --tree --icons'
alias cat bat
alias grep rg
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
# `#zerg` — явно, чтобы работало когда hostname не совпадает (первая сборка на новом хосте)
function up --description 'Rebuild NixOS system (git add + nh os switch)'
    git -C ~/nixos-conf add -A
    nh os switch ~/nixos-conf#zerg $argv
end

function hm --description 'Rebuild home-manager (git add + nh home switch)'
    git -C ~/nixos-conf add -A
    nh home switch -b backup -c (whoami)@(hostname) ~/nixos-conf $argv
end

function nc --description 'Clean old NixOS generations'
    nh clean
end

function upall --description 'Update home-manager then system (git add + hm + up)'
    git -C ~/nixos-conf add -A
    nh home switch -b backup -c (whoami)@(hostname) ~/nixos-conf
    and nh os switch ~/nixos-conf#zerg $argv
end
alias g git

# abbreviations
abbr --add gco git checkout
abbr --add gcb git checkout -b
abbr --add gst git status
abbr --add gaa git add -A
abbr --add gcm git commit -m
abbr --add gca git commit --amend
abbr --add gpl git pull --rebase
abbr --add gps git push
abbr --add glg git log --oneline --graph
abbr --add gdf git diff
abbr --add gdc git diff --cached
abbr --add t tmux
abbr --add ta 'tmux attach-session -t'
abbr --add tn 'tmux new-session -s'

# env
set -gx EDITOR nvim
set -gx VISUAL zeditor
set -gx PAGER less
set -gx BROWSER brave

# fzf
set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git"'
set -gx FZF_DEFAULT_OPTS '--height 60% --layout=reverse --border --bind ctrl-k:preview-up,ctrl-j:preview-down'

# starship prompt
starship init fish | source

# zoxide
zoxide init fish | source
