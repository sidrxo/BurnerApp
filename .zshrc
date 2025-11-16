alias gfetch='git fetch origin && git reset --hard origin/main'
alias gpush='git add . && read -p "Commit message: " msg && git commit -m "$msg" && git push origin main'
alias cloccy='cloc . --include-lang=Swift --by-file'