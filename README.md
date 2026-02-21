# cfg

A lightweight dotfile manager built on a bare Git repository and [just](https://just.systems).

Your dotfiles live in a regular Git repo, but instead of symlinking or copying,
the bare repo's work tree is set to `$HOME` — tracked files are managed in place.

## Prerequisites

- **Git**
- **SSH key** added to your Git host (e.g. [GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh))
- **[just](https://just.systems)** — the setup script can install it for you

## Setting up a new machine

Create a private repo on your Git host (e.g. `github.com:<user>/cfg`), then run:

```sh
sh ~/.cfg/setup.sh git@github.com:<user>/cfg
```

Or pipe it directly (useful before the repo is cloned locally):

```sh
curl -fsSL https://raw.githubusercontent.com/<user>/cfg/main/setup.sh | sh -s -- git@github.com:<user>/cfg
```

You can also pass the URL via an environment variable or let the script prompt
you interactively:

```sh
REMOTE_URL=git@github.com:<user>/cfg sh setup.sh
```

The setup script will:

1. Install `just` if it isn't already present
2. Verify SSH connectivity to the Git host
3. Clone the bare repo into `~/.cfg/.git`
4. Configure the repo (untracked file hiding, branch tracking, auto upstream)
5. Check out your dotfiles into `$HOME` (backing up any conflicts to `~/.cfg-backup/`)

If anything fails, `~/.cfg` is removed automatically so you can safely re-run.

### Shell alias

After setup, add this alias to your shell startup file (`~/.zshrc`, `~/.bashrc`, etc.):

```sh
alias cfg="just --justfile ~/.cfg/.justfile --working-directory ."
```

Then reload your shell:

```sh
source ~/.zshrc
```

## Usage

### Track a new file

```sh
cfg add ~/.zshrc
```

Stages the file, commits it, and pushes — all in one step.

### Untrack a file

```sh
cfg rm ~/.zshrc
```

Removes the file from the repo but **keeps it on disk**.

### Sync

```sh
cfg sync
```

Commits all changes to tracked files, pulls with rebase, and pushes.
Shows a summary of outgoing and incoming file changes:

```
==> Synchronizing ...
==> Committing local changes
  .zshrc
  .gitconfig
==> Pulling w/rebase
    already up to date
==> Pushing
==> Synchronization done!
```

### List tracked files

```sh
cfg ls
```

### Run any git command

```sh
cfg git status
cfg git log --oneline
cfg git diff
```

The `git` recipe passes any arguments straight through to the bare repo,
so every git command is available.

## How it works

The repo is a [bare clone](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---bare)
stored at `~/.cfg/.git` with the work tree set to `$HOME`:

```sh
git --git-dir=$HOME/.cfg/.git --work-tree=$HOME <command>
```

The `just` recipes in `~/.cfg/.justfile` wrap this into short, memorable
commands. `status.showUntrackedFiles` is set to `no` so that `git status`
only shows files you've explicitly added — not every file in your home
directory.

## Re-running setup

If you need to start over, remove the existing state first:

```sh
rm -rf ~/.cfg
```

Then run the setup script again.
