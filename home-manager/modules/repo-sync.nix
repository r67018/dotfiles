# Keeps ~/dotfiles and ~/my-skills up to date automatically: clones them if
# missing (e.g. this flake was fetched straight from GitHub rather than from
# a local checkout) and fast-forwards them on every `switch` otherwise.
#
# ~/my-skills is the private counterpart to this repo (see skill-manager) and
# has no flake of its own, so nothing else keeps it in sync — this activation
# script is the only thing that does.

{ config, lib, pkgs, ... }:

let
  git = lib.getExe pkgs.git;

  repos = [
    {
      name = "dotfiles";
      url = "git@github.com:r67018/dotfiles.git";
    }
    {
      name = "my-skills";
      url = "git@github.com:r67018/my-skills.git";
    }
  ];

  syncRepoCalls = lib.concatMapStringsSep "\n" (
    { name, url }: "sync_repo ${lib.escapeShellArg name} ${lib.escapeShellArg url}"
  ) repos;
in
{
  home.activation.syncPersonalRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    sync_repo() {
      local name="$1" url="$2"
      local dir="${config.home.homeDirectory}/$name"

      if [ -e "$dir" ] && [ ! -d "$dir/.git" ]; then
        echo "repo-sync: $dir exists and is not a git checkout, leaving it alone" >&2
        return
      fi

      if [ -d "$dir/.git" ]; then
        # --no-rebase --ff-only: this user's global git config defaults
        # `pull.rebase = true`, which would otherwise try to rebase over
        # local commits during an unattended `switch`. Force a plain
        # fast-forward instead — if history has diverged, skip and say so
        # rather than rewriting the user's work.
        if ! run ${git} -C "$dir" pull --no-rebase --ff-only --quiet; then
          echo "repo-sync: git pull failed for $dir (offline, or history diverged?) — leaving it as-is" >&2
        fi
      else
        if ! run ${git} clone --quiet "$url" "$dir"; then
          echo "repo-sync: git clone failed for $name — leaving $dir absent" >&2
        fi
      fi
    }

    ${syncRepoCalls}
  '';
}
