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
      # store so it can be diffed against the copy vendored in .claude/skills.
      mkdir -p "$out/share/thunderbird-cli"
      cp -R skills "$out/share/thunderbird-cli/"

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
in

{
  home.packages = [ thunderbird-cli ];

  # tb-bridge is the *server* side of the pair: it listens on 127.0.0.1:7700
  # (HTTP, for tb/tb-mcp) and 127.0.0.1:7701 (WebSocket, for the Thunderbird
  # WebExtension). It does not need Thunderbird to be running to start — it
  # just waits, and the extension connects within a few seconds of Thunderbird
  # launching. So starting at login is fine; KeepAlive is only for crashes.
  launchd.agents.tb-bridge = {
    enable = true;
    config = {
      ProgramArguments = [ "${thunderbird-cli}/bin/tb-bridge" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/tb-bridge.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/tb-bridge.log";
    };
  };

  # claude_desktop_config.json is not ours to own: Claude Desktop keeps its own
  # live UI state in the same file and rewrites it at runtime. Writing it from
  # the store (home.file / symlink) would throw that state away and then be
  # clobbered anyway. Merge just our one key in instead, idempotently.
  home.activation.thunderbirdMcpForClaudeDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      jq=${lib.getExe pkgs.jq}
      config_file=${lib.escapeShellArg claudeDesktopConfig}
      mcp_command=${lib.escapeShellArg "${thunderbird-cli}/bin/tb-mcp"}

      run mkdir -p "$(dirname "$config_file")"

      existing='{}'
      [ -s "$config_file" ] && existing=$(cat "$config_file")

      if ! current=$(printf '%s' "$existing" \
           | "$jq" -r '.mcpServers.thunderbird.command // ""' 2>/dev/null); then
        echo "thunderbird-cli: $config_file is not valid JSON — leaving it untouched." >&2
        echo "thunderbird-cli: add {\"mcpServers\":{\"thunderbird\":{\"command\":\"$mcp_command\"}}} by hand." >&2
      elif [ "$current" != "$mcp_command" ]; then
        merged=$(printf '%s' "$existing" \
          | "$jq" --arg cmd "$mcp_command" '.mcpServers.thunderbird = { command: $cmd }')
        tmp=$(mktemp)
        chmod 600 "$tmp"
        printf '%s\n' "$merged" > "$tmp"
        run mv "$tmp" "$config_file"
      fi
    '';
}
