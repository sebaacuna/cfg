# cfg - bare git repo dotfile manager
# Usage: cfg <recipe> [args]
# Alias: cfg=just --justfile ~/.cfg/.justfile --working-directory .

git := "git --git-dir=" + env_var("HOME") + "/.cfg/.git --work-tree=" + env_var("HOME")

# Pass any command through to the bare repo (e.g. cfg git status, cfg git log)
[no-exit-message]
git *args:
    {{ git }} {{ args }}

# Add a file to the bare repo and push
add file:
    {{ git }} add {{ file }}
    {{ git }} commit -m "cfg: track {{ file }}"
    {{ git }} push

# Remove a file from the bare repo and push (does not delete from filesystem)
rm file:
    {{ git }} rm --cached {{ file }}
    {{ git }} commit -m "cfg: untrack {{ file }}"
    {{ git }} push

# Commit all changes to tracked files, pull and push
sync:
    -{{ git }} add -u
    -{{ git }} commit -m "cfg: sync"
    {{ git }} pull --rebase
    {{ git }} push

# List all tracked files
ls:
    {{ git }} ls-tree --name-only -r HEAD
