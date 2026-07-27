# thunderbird-cli — drive Thunderbird's mail from Claude Desktop.
#
# Thunderbird stays the only thing holding IMAP/SMTP credentials; everything
# here is localhost-only. The chain is:
#
#   Claude Desktop -> tb-mcp -> :7700 tb-bridge :7701 <- Thunderbird extension
#
# This module builds and installs all three binaries, runs tb-bridge as a login
# agent, and registers tb-mcp with Claude Desktop.
#
# ONE MANUAL STEP REMAINS — installing the WebExtension into Thunderbird:
#
#   Thunderbird -> Add-ons -> gear -> Install Add-on From File, then pick
#   (Cmd+Shift+G in the macOS file dialog pastes a path)
#
#     ~/Library/Application Support/thunderbird-cli/thunderbird-ai-bridge.xpi
#
#   That symlink is created by home.file below, not by the package profile —
#   see the comment there for why the profile cannot be used for this.
#
# Thunderbird 128+ required. Nix deliberately does not do this: writing a signed
# XPI straight into the profile directory is not a supported install path.

{ pkgs, lib, config, ... }:

let
  # vitalio-sh/thunderbird-cli is an npm workspace monorepo: `cli/` (the `tb`
  # command), `bridge/` (the `tb-bridge` daemon) and `mcp/` (the `tb-mcp` server
  # Claude Desktop talks to). One root package-lock.json covers all three and
  # they are released in lockstep, so they are one derivation here rather than
  # three — three would re-fetch and re-verify the same lockfile for no gain.
  thunderbird-cli = pkgs.buildNpmPackage {
    pname = "thunderbird-cli";

    # Pinned past the v1.0.2 tag: the commit that adds the companion Claude
    # Skill we install below.
    version = "1.0.2-unstable-2026-04-19";

    src = pkgs.fetchFromGitHub {
      owner = "vitalio-sh";
      repo = "thunderbird-cli";
      rev = "807f837060b3e611168f749bf47181566c6f99b8";
      hash = "sha256-2rXJUIRs6/KwxPX7I+6O7dihldLnmJNPQL/tQ1hSH1U=";
    };

    npmDepsHash = "sha256-ixzfebmKITD1lnPNQq765S1f+i7xBTTWWdZoJOqY7qg=";

    # Plain ESM in every workspace; there is no build script to run.
    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # The workspace root is `private: true` and declares no bin of its own, so
    # npm's default install step has nothing to install. Lay the tree out by
    # hand instead and wrap each workspace's entry point with node on PATH.
    # node_modules is copied alongside cli/bridge/mcp so npm's hoisted layout
    # (and the workspace symlinks inside it) keeps resolving.
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/thunderbird-cli" "$out/bin"
      cp -R bridge cli mcp node_modules package.json "$out/lib/thunderbird-cli/"

      for entry in tb:cli/src/cli.js tb-bridge:bridge/bridge.js tb-mcp:mcp/src/server.js; do
        makeWrapper ${lib.getExe pkgs.nodejs} "$out/bin/''${entry%%:*}" \
          --add-flags "$out/lib/thunderbird-cli/''${entry#*:}"
      done

      # The companion Claude Skill ships in-tree; keep it addressable from the
      # store so it can be diffed against the copy vendored in the private
      # my-skills repo (~/my-skills/skills/thunderbird-cli).
      mkdir -p "$out/share/thunderbird-cli"
      cp -R skills "$out/share/thunderbird-cli/"

      # Ship the signed WebExtension too. Installing it has to happen by hand
      # through Thunderbird's add-on GUI — dropping a signed XPI into the
      # profile directory is not something nix should be doing — but keeping
      # the file in the store pins the extension to the same rev as the CLI,
      # so the two halves of the protocol can never drift apart. Rename it to a
      # fixed filename so the symlink below survives extension version bumps;
      # if upstream ever ships more than one XPI this fails loudly at build time.
      install -Dm444 dist/releases/*.xpi "$out/share/thunderbird-cli/thunderbird-ai-bridge.xpi"

      runHook postInstall
    '';

    meta = {
      description = "CLI + MCP server that drives Mozilla Thunderbird for AI agents";
      homepage = "https://github.com/vitalio-sh/thunderbird-cli";
      license = lib.licenses.mit;
      mainProgram = "tb";
      platforms = lib.platforms.unix;
    };
  };

  claudeDesktopConfig =
    "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";

  bridgeLog = "${config.home.homeDirectory}/Library/Logs/tb-bridge.log";

  # bridge.js installs no 'error' handler on either listener, so binding a busy
  # port kills the process outright — and under KeepAlive that turns into a
  # permanent restart loop. A second bridge is easy to end up with: the bundled
  # skill tells the user to run `tb-bridge` by hand whenever it reports
  # BRIDGE_UNREACHABLE. Stand by for the port instead of fighting over it, so
  # the agent takes over by itself once the manual one goes away.
  tb-bridge-agent = pkgs.writeShellApplication {
    name = "tb-bridge-agent";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      log=${lib.escapeShellArg bridgeLog}

      # launchd never rotates StandardOutPath and the bridge logs every
      # extension connect/disconnect, so trim on each start. Truncating is safe
      # while launchd holds the fd — it opens the file in append mode.
      if [ -f "$log" ] && [ "$(wc -c < "$log")" -gt 1048576 ]; then
        : > "$log"
      fi

      announced=0
      while curl -sf -m 2 -o /dev/null http://127.0.0.1:7700/bridge/status; do
        if [ "$announced" -eq 0 ]; then
          echo "[agent] 127.0.0.1:7700 is already served by another bridge — standing by"
          announced=1
        fi
        sleep 30
      done

      exec ${thunderbird-cli}/bin/tb-bridge
    '';
  };
in

{
  home.packages = [ thunderbird-cli ];

  # The XPI has to be reachable from a GUI file picker, and the package's own
  # share/ dir is not: nix-darwin's environment.pathsToLink links only /bin and
  # a fixed handful of /share/* subdirs into /etc/profiles/per-user/<name>, so
  # share/thunderbird-cli never appears there. home.file bypasses that.
  home.file."Library/Application Support/thunderbird-cli/thunderbird-ai-bridge.xpi".source =
    "${thunderbird-cli}/share/thunderbird-cli/thunderbird-ai-bridge.xpi";

  # tb-bridge is the *server* side of the pair: it listens on 127.0.0.1:7700
  # (HTTP, for tb/tb-mcp) and 127.0.0.1:7701 (WebSocket, for the Thunderbird
  # WebExtension). It does not need Thunderbird to be running to start — it
  # just waits, and the extension connects within a few seconds of Thunderbird
  # launching. So starting at login is fine; KeepAlive is only for crashes.
  launchd.agents.tb-bridge = {
    enable = true;
    config = {
      ProgramArguments = [ "${tb-bridge-agent}/bin/tb-bridge-agent" ];
      RunAtLoad = true;
      KeepAlive = true;
      # The standby loop absorbs the likely conflict (a hand-started bridge);
      # this bounds the damage from any crash cause it cannot see, since
      # launchd's 10s default would otherwise spin hard against it.
      ThrottleInterval = 60;
      ProcessType = "Background";
      StandardOutPath = bridgeLog;
      StandardErrorPath = bridgeLog;
    };
  };

  # claude_desktop_config.json is not ours to own: Claude Desktop keeps its own
  # live UI state in the same file and rewrites it at runtime. Writing it from
  # the store (home.file / symlink) would throw that state away and then be
  # clobbered anyway. Merge just our one key in instead, idempotently.
  #
  # Observed behaviour, the hard way: the app reads this file only at startup
  # and rewrites it on quit from whatever it loaded then. So an entry added
  # while it is running is discarded at the next quit — it never saw it. That
  # makes activation-with-the-app-open a no-op in practice, hence the warning
  # at the end of this script. Once the app has started with the entry present
  # it holds on to it, so this only bites on first install.
  home.activation.thunderbirdMcpForClaudeDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      jq=${lib.getExe pkgs.jq}
      config_file=${lib.escapeShellArg claudeDesktopConfig}
      mcp_command=${lib.escapeShellArg "${thunderbird-cli}/bin/tb-mcp"}

      run mkdir -p "$(dirname "$config_file")"

      raw='{}'
      if [ -e "$config_file" ]; then
        raw=$(cat "$config_file")
      fi

      # jq exits 0 and prints nothing when its input holds no JSON value at all,
      # so a blank or whitespace-only file sails past the parse check below and
      # then merges to the empty string — which would truncate the config
      # instead of leaving it alone. Normalise that case up front.
      if [ -z "''${raw//[[:space:]]/}" ]; then
        raw='{}'
      fi

      if ! current=$(printf '%s' "$raw" \
           | "$jq" -r '.mcpServers.thunderbird.command // ""' 2>/dev/null); then
        echo "thunderbird-cli: $config_file is not valid JSON — leaving it untouched." >&2
        echo "thunderbird-cli: set .mcpServers.thunderbird.command to $mcp_command by hand." >&2
      elif [ "$current" != "$mcp_command" ]; then
        # Assign the one field rather than the whole object: replacing the
        # entry would silently drop any args/env the user added to it. `args`
        # is defaulted rather than set, for the same reason — every documented
        # example carries it, and the app skips entries it considers malformed.
        if ! merged=$(printf '%s' "$raw" \
             | "$jq" --arg cmd "$mcp_command" \
                 '.mcpServers.thunderbird.command = $cmd
                  | .mcpServers.thunderbird.args //= []') \
           || [ -z "$merged" ]; then
          echo "thunderbird-cli: could not merge into $config_file — leaving it untouched." >&2
        else
          tmp=$(mktemp)
          chmod 600 "$tmp"
          printf '%s\n' "$merged" > "$tmp"
          run mv "$tmp" "$config_file"

          # Claude Desktop keeps this file in memory and rewrites it wholesale
          # on its next preference change, which would drop what we just wrote.
          # Say so rather than letting it fail silently — the merge is
          # idempotent, so re-running the switch is a valid remedy.
          # No `grep -q`: it exits on the first match and SIGPIPEs ps, which
          # under the activation script's `set -o pipefail` fails the test.
          if /bin/ps -Ao comm= 2>/dev/null | grep "/Claude\.app/Contents/MacOS/" >/dev/null; then
            echo "thunderbird-cli: Claude Desktop is running and may overwrite this change." >&2
            echo "thunderbird-cli: quit and reopen it; if the thunderbird server is missing, re-run the switch with it closed." >&2
          fi
        fi
      fi
    '';
}
