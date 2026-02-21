#!/bin/sh
# cfg setup — bootstraps a bare-git dotfile manager on a new machine.
# Usage: curl -fsSL https://raw.githubusercontent.com/.../setup.sh | sh -s -- git@github.com:user/cfg
#    or: sh setup.sh git@github.com:user/cfg
#    or: REMOTE_URL=git@github.com:user/cfg sh setup.sh
set -e

# ── Helpers ───────────────────────────────────────────────────────────────────

fail() { printf '\033[31merror:\033[0m %b\n' "$*" >&2; exit 1; }
info() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarning:\033[0m %s\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

cfg_git() { git --git-dir="$HOME/.cfg/.git" --work-tree="$HOME" "$@"; }

# ── Preflight ─────────────────────────────────────────────────────────────────

[ -d "$HOME/.cfg" ] && fail "~/.cfg already exists. Remove it before running setup."

# ── Cleanup trap ──────────────────────────────────────────────────────────────

# Remove ~/.cfg if the script exits before completing successfully.
# The trap is cleared at the very end once setup is confirmed complete.
_cleanup() { rm -rf "$HOME/.cfg"; }
trap _cleanup EXIT

# ── Remote URL ────────────────────────────────────────────────────────────────

# Accept URL as first positional arg (e.g. `sh setup.sh <url>` or piped as
# `curl ... | sh -s -- <url>`), falling back to the REMOTE_URL env var, then
# prompting interactively.
REMOTE_URL="${REMOTE_URL:-${1:-}}"

while [ -z "$REMOTE_URL" ]; do
    printf 'Remote git URL (required): ' > /dev/tty
    read -r REMOTE_URL < /dev/tty
    [ -z "$REMOTE_URL" ] && warn "A remote URL is required."
done

# ── just ──────────────────────────────────────────────────────────────────────
dim "Checking for just..."
if ! command -v just >/dev/null 2>&1; then
    printf '\033[33mjust\033[0m is not installed. Install it now via the official installer? [y/N] ' > /dev/tty
    read -r yn < /dev/tty
    case "$yn" in
        [yY])
            info "Installing just to ~/.local/bin ..."
            mkdir -p "$HOME/.local/bin"
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
                | sh -s -- --to "$HOME/.local/bin" \
                || fail "Failed to install just. See https://just.systems for manual install options."
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            fail "just is required. Install it from https://just.systems and re-run setup."
            ;;
    esac
else
    info "just is already installed."
fi

# ── SSH connectivity check (SSH-style URLs only) ───────────────────────────────

if printf '%s' "$REMOTE_URL" | grep -qE '^(git@|ssh://)'; then
    # Extract the hostname from either:
    #   git@github.com:user/repo.git
    #   ssh://git@github.com/user/repo.git
    if printf '%s' "$REMOTE_URL" | grep -qE '^git@'; then
        SSH_HOST=$(printf '%s' "$REMOTE_URL" | sed 's/^git@\([^:]*\):.*/\1/')
    else
        SSH_HOST=$(printf '%s' "$REMOTE_URL" | sed 's|^ssh://[^@]*@\([^/:]*\).*|\1|')
    fi

    info "Testing SSH connection to $SSH_HOST ..."

    # BatchMode=yes prevents interactive password prompts.
    # GitHub exits 1 even on success, so we capture output rather than relying on exit code.
    # Redirect stdin from /dev/null so ssh doesn't consume the script content
    # when this script is being piped into sh (e.g. curl ... | sh).
    SSH_OUT=$(ssh -T \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=accept-new \
        "git@$SSH_HOST" < /dev/null 2>&1) || true

    if printf '%s' "$SSH_OUT" | grep -qiE 'permission denied|authentication failed|could not resolve hostname|no route to host'; then
        fail "Cannot SSH into $SSH_HOST.\n       Output: $SSH_OUT\n       Ensure your SSH key is authorized on the remote."
    fi

    info "Git server connection OK — $(printf '%s' "$SSH_OUT" | head -1)"
fi

# ── Clone bare repo ───────────────────────────────────────────────────────────

info "Cloning bare repository from $REMOTE_URL ..."
git clone --bare "$REMOTE_URL" "$HOME/.cfg/.git" \
    || fail "Failed to clone from $REMOTE_URL."

# Hide untracked files so that `cfg git status` isn't flooded with every file in $HOME.
cfg_git config --local status.showUntrackedFiles no

# Automatically set upstream when pushing new branches (avoids the
# "no upstream branch" error on first push to an empty repo).
cfg_git config --local push.autoSetupRemote true

# Exclude repo-only files (README, .gitignore) from the $HOME work tree.
cfg_git sparse-checkout init --no-cone
cfg_git sparse-checkout set '/*' '!README.md' '!.gitignore'

if cfg_git rev-parse --verify HEAD >/dev/null 2>&1; then
    # ── Push access check (non-empty repo only) ──────────────────────────────

    info "Testing push access ..."
    PUSH_OUT=$(cfg_git push --dry-run 2>&1) \
        || fail "Cannot push to $REMOTE_URL.\n       Output: $PUSH_OUT\n       Check your repository permissions."

    # ── Check out tracked files ───────────────────────────────────────────────

    info "Checking out dotfiles to $HOME ..."

    CHECKOUT_OUT=$(cfg_git checkout 2>&1) && CHECKOUT_OK=0 || CHECKOUT_OK=$?

    if [ "$CHECKOUT_OK" -ne 0 ]; then
        # Collect conflicting files reported by git (indented list in git's output)
        CONFLICTS=$(printf '%s' "$CHECKOUT_OUT" | grep -E '^\s+\S' | awk '{print $1}')

        if [ -n "$CONFLICTS" ]; then
            warn "Existing files conflict with the checkout. Backing them up to ~/.cfg-backup/ ..."
            printf '%s\n' "$CONFLICTS" | while IFS= read -r f; do
                target="$HOME/.cfg-backup/$(dirname "$f")"
                mkdir -p "$target"
                mv "$HOME/$f" "$HOME/.cfg-backup/$f"
                dim "  backed up: ~/$f"
            done
            cfg_git checkout \
                || fail "Checkout failed even after backing up conflicts. Check the output above."
        else
            # Something other than file conflicts went wrong
            fail "Checkout failed:\n$CHECKOUT_OUT"
        fi
    fi
else
    info "Repository is empty — ready for you to start tracking dotfiles."
fi

# ── Done ─────────────────────────────────────────────────────────────────────

trap - EXIT  # disarm cleanup — setup succeeded
printf '\n\033[1;32mSetup complete!\033[0m\n'
cat <<'EOF'

Add the following alias to your shell startup file (~/.zshrc, ~/.bashrc, etc.):

  alias cfg="just --justfile ~/.cfg/.justfile --working-directory ."

Then reload your shell:

  source ~/.zshrc

You can then manage your dotfiles with:

  cfg add <file>   — track a file and push
  cfg rm <file>    — untrack a file (keeps it on disk) and push
  cfg sync         — commit all changes to tracked files, pull and push
  cfg ls           — list all tracked files
  cfg git <cmd>    — run any git command against the bare repo

EOF
