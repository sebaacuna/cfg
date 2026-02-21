# cfg - bare git repo dotfile manager
# Usage: cfg <recipe> [args]
# Alias: cfg=just --justfile ~/.cfg/.justfile --working-directory .

git := "git --git-dir=" + env_var("HOME") + "/.cfg/.git --work-tree=" + env_var("HOME")

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

# Pull latest changes from remote
pull:
    {{ git }} pull
