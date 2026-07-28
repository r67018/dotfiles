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
  ssh = lib.getExe pkgs.openssh;

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
  # SSH's configuration is materialized by `fixSshConfigPermissions`.  Run as
  # soon as that has completed, rather than merely after `writeBoundary`: a
  # later activation step (notably sops-nix) can fail and would otherwise
  # prevent a missing private repository from ever being cloned.
  home.activation.syncPersonalRepos = lib.hm.dag.entryBetween
    [ "sops-nix" ]
    [ "fixSshConfigPermissions" ]
    ''
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
        if ! run ${git} -c core.sshCommand=${lib.escapeShellArg ssh} -C "$dir" pull --no-rebase --ff-only --quiet; then
          echo "repo-sync: git pull failed for $dir (offline, or history diverged?) — leaving it as-is" >&2
        fi
      else
        if ! run ${git} -c core.sshCommand=${lib.escapeShellArg ssh} clone --quiet "$url" "$dir"; then
          echo "repo-sync: git clone failed for $name — leaving $dir absent" >&2
        fi
      fi
    }

    sync_skills() {
      local source_dir="${config.home.homeDirectory}/my-skills/skills"
      local target_dir skill_path skill_name target current

      if [ ! -d "$source_dir" ]; then
        echo "repo-sync: $source_dir is absent; skipping skill links" >&2
        return
      fi

      # Keep each agent's own built-in skills intact. Only links owned by
      # my-skills are created or refreshed here; regular files/directories are
      # left untouched. Broken links from the former in-tree skill location
      # are links too, so replacing them is safe.
      for target_dir in \
        "${config.home.homeDirectory}/.claude/skills" \
        "${config.home.homeDirectory}/.codex/skills"; do
        run mkdir -p "$target_dir"

        for skill_path in "$source_dir"/*/; do
          [ -d "$skill_path" ] || continue
          skill_name="$(basename "$skill_path")"
          target="$target_dir/$skill_name"

          if [ -L "$target" ]; then
            current="$(readlink "$target")"
            if [ "$current" = "''${skill_path%/}" ]; then
              continue
            fi

            run rm "$target"
          elif [ -e "$target" ]; then
            echo "repo-sync: $target exists and is not a symlink, leaving it alone" >&2
            continue
          fi

          run ln -s "''${skill_path%/}" "$target"
        done
      done
    }

    ${syncRepoCalls}
    sync_skills
    '';
}
