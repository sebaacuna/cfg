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
    @printf '\033[32m==>\033[0m Synchronizing ...\n'
    @{{ git }} add -u 2>/dev/null || true
    @if ! {{ git }} diff --cached --quiet 2>/dev/null; then \
       printf '\033[32m==>\033[0m Committing local changes\n'; \
       {{ git }} diff --cached --name-only | while read -r f; do printf '\033[2m  %s\033[0m\n' "$f"; done; \
       {{ git }} commit --quiet -m "cfg: sync"; \
     else \
       printf '\033[2m    no local changes\033[0m\n'; \
     fi
    @printf '\033[32m==>\033[0m Pulling w/rebase\n'
    @if {{ git }} rev-parse --verify '@{u}' >/dev/null 2>&1; then \
       {{ git }} fetch --quiet; \
       incoming=$({{ git }} diff --name-only 'HEAD...@{u}' 2>/dev/null); \
       if [ -n "$incoming" ]; then \
         echo "$incoming" | while read -r f; do printf '\033[2m  %s\033[0m\n' "$f"; done; \
         {{ git }} rebase --quiet '@{u}'; \
       else \
         printf '\033[2m    already up to date\033[0m\n'; \
       fi; \
     else \
       printf '\033[2m    no upstream configured, skipping\033[0m\n'; \
     fi
    @printf '\033[32m==>\033[0m Pushing\n'
    @{{ git }} push --quiet
    @printf '\033[32m==>\033[0m Synchronization done!\n'

# List all tracked files (respects sparse-checkout exclusions)
ls:
    @{{ git }} ls-files -t | sed -n 's/^H //p'
