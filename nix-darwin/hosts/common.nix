{ config, lib, pkgs, ... }:
let
  primaryUser = config.system.primaryUser;

  # yaskkserv2 supplies Google Japanese Input API candidates only when the
  # local SKK dictionary has no match.
  yaskkserv2 = pkgs.rustPlatform.buildRustPackage {
    pname = "yaskkserv2";
    version = "0.1.7";
    src = pkgs.fetchFromGitHub {
      owner = "wachikun";
      repo = "yaskkserv2";
      rev = "0.1.7";
      hash = "sha256-bF8OHP6nvGhxXNvvnVCuOVFarK/n7WhGRktRN4X5ZjE=";
    };
    cargoHash = "sha256-cycs8Zism228rjMaBpNYa4K1Ll760UhLKkoTX6VJRU0=";
    doCheck = false;
  };

  # SKK-JISYO.L covers common vocabulary locally. yaskkserv2 only queries
  # Google for terms that this dictionary does not contain.
  yaskkserv2Dictionary = pkgs.runCommand "yaskkserv2-dictionary" { } ''
    ${pkgs.coreutils}/bin/mkdir -p "$out"
    ${yaskkserv2}/bin/yaskkserv2_make_dictionary \
      --dictionary-filename="$out/dictionary.yaskkserv2" \
      ${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L
  '';

  yaskkserv2Cache = "/Users/${primaryUser}/Library/Caches/yaskkserv2.cache";

  # Exactly two input sources in the menu: macSKK's ABC for the alphabet and
  # macSKK's ひらがな for Japanese. Keeping both modes in macSKK avoids mixing
  # macOS/other IME state when switching with Ctrl-Space.
  #
  # The palette entries at the end aren't user-visible input sources; macOS
  # keeps them enabled by itself. They are listed so this stays byte-for-byte
  # the list the system actually stores, which is what lets the login agent
  # below compare against it.
  enabledInputSources = [
    {
      "Bundle ID" = "net.mtgto.inputmethod.macSKK";
      "Input Mode" = "net.mtgto.inputmethod.macSKK.ascii";
      InputSourceKind = "Input Mode";
    }
    {
      "Bundle ID" = "net.mtgto.inputmethod.macSKK";
      "Input Mode" = "net.mtgto.inputmethod.macSKK.hiragana";
      InputSourceKind = "Input Mode";
    }
    {
      "Bundle ID" = "com.apple.CharacterPaletteIM";
      InputSourceKind = "Non Keyboard Input Method";
    }
    {
      "Bundle ID" = "com.apple.50onPaletteIM";
      InputSourceKind = "Non Keyboard Input Method";
    }
    {
      "Bundle ID" = "com.apple.PressAndHold";
      InputSourceKind = "Non Keyboard Input Method";
    }
  ];

  selectedInputSources = [
    {
      "Bundle ID" = "net.mtgto.inputmethod.macSKK";
      "Input Mode" = "net.mtgto.inputmethod.macSKK.hiragana";
      InputSourceKind = "Input Mode";
    }
  ];

  inputSourceHistory = selectedInputSources ++ [
    {
      "Bundle ID" = "net.mtgto.inputmethod.macSKK";
      "Input Mode" = "net.mtgto.inputmethod.macSKK.ascii";
      InputSourceKind = "Input Mode";
    }
  ];

  # macOS and input methods can modify these preferences outside nix-darwin, so
  # re-assert the declarative list and selected source at every login too. The
  # Homebrew cask is installed after activation; opening the input-method app
  # once and watching its install path makes its first registration automatic.
  enforceInputSources = pkgs.writeShellScript "enforce-input-sources" ''
    inputMethod="/Library/Input Methods/macSKK.app"
    if [ ! -d "$inputMethod" ]; then
      exit 0
    fi

    # Make Text Input Services discover macSKK before referring to its input
    # modes below. `-g` prevents an app switch and `-j` hides it from Recents.
    /usr/bin/open -gj "$inputMethod" 2>/dev/null || true
    /bin/sleep 2

    want=$(${pkgs.jq}/bin/jq -cnS \
      --slurpfile enabled ${pkgs.writeText "enabled-input-sources.json" (builtins.toJSON enabledInputSources)} \
      --slurpfile selected ${pkgs.writeText "selected-input-sources.json" (builtins.toJSON selectedInputSources)} \
      --slurpfile history ${pkgs.writeText "input-source-history.json" (builtins.toJSON inputSourceHistory)} \
      '{ enabled: $enabled[0], selected: $selected[0], history: $history[0] }')

    have=$(/usr/bin/defaults export com.apple.HIToolbox - \
      | /usr/bin/plutil -convert json -o - - 2>/dev/null \
      | ${pkgs.jq}/bin -cS '{ enabled: .AppleEnabledInputSources, selected: .AppleSelectedInputSources, history: .AppleInputSourceHistory }' 2>/dev/null) || have=

    if [ "$want" != "$have" ]; then
      /usr/bin/defaults write com.apple.HIToolbox AppleEnabledInputSources "$(< ${
        pkgs.writeText "enabled-input-sources.plist"
          (lib.generators.toPlist { escape = true; } enabledInputSources)
      })"
      /usr/bin/defaults write com.apple.HIToolbox AppleSelectedInputSources "$(< ${
        pkgs.writeText "selected-input-sources.plist"
          (lib.generators.toPlist { escape = true; } selectedInputSources)
      })"
      /usr/bin/defaults write com.apple.HIToolbox AppleInputSourceHistory "$(< ${
        pkgs.writeText "input-source-history.plist"
          (lib.generators.toPlist { escape = true; } inputSourceHistory)
      })"
    fi

    # Writing the preference directly skips the notification the Text Input
    # Services API would have posted, so anything already running keeps serving
    # the list it read at startup. Post it by hand, and restart the menu bar
    # item too in case it read the list before this agent got to run.
    # (`launchctl kickstart` is not an option here: SIP refuses it for Apple's
    # own agents.)
    /usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); $.NSDistributedNotificationCenter.defaultCenter.postNotificationNameObjectUserInfoDeliverImmediately("AppleEnabledInputSourcesChangedNotification", $(), $(), true)' > /dev/null
    /usr/bin/killall TextInputMenuAgent 2>/dev/null || true
  '';
in
{
  # Determine Installer collision
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";

  # System packages
  environment.systemPackages = [ pkgs.vim pkgs.git pkgs.docker pkgs.docker-compose pkgs.colima ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    newcomputermodern
  ];

  # Authenticate sudo with Touch ID (reattach makes it work inside tmux too)
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  # System defaults
  system.defaults = {
    finder._FXShowPosixPathInTitle = true;
    finder.AppleShowAllExtensions = true;
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.autohide-time-modifier = 0.6;
    dock.show-recents = false;
    trackpad.Clicking = true;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain."com.apple.keyboard.fnState" = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    dock.persistent-apps = lib.mkDefault [
      "/Applications/kitty.app"
      "/Applications/1Password.app"
    ];
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    # Aerospace tiles windows edge to edge, which Mission Control otherwise
    # renders as an unreadable pile of overlapping thumbnails.
    dock.expose-group-apps = true;
    CustomUserPreferences."com.apple.HIToolbox" = {
      AppleCurrentKeyboardLayoutInputSourceID = "net.mtgto.inputmethod.macSKK.ascii";
      AppleEnabledInputSources = enabledInputSources;
      AppleInputSourceHistory = inputSourceHistory;
      AppleSelectedInputSources = selectedInputSources;
    };
    CustomUserPreferences."net.mtgto.inputmethod.macSKK" = {
      # Keep Japanese sentence punctuation full-width in every Japanese input
      # mode while retaining the default kana conversion rules.
      kanaRule = ''
        #!use-default
        ?,？,？,？
        !,！,！,！
      '';
      skkserv = {
        enabled = true;
        address = "127.0.0.1";
        port = 1178;
        requestEncoding = 3;
        responseEncoding = 3;
        encoding = 3;
        saveToUserDict = true;
        enableCompletion = false;
      };
    };
  };

  # wait4path because /nix is a separate volume that isn't mounted yet this
  # early in login.
  launchd.user.agents.input-sources = {
    serviceConfig = {
      ProgramArguments = [ "/bin/sh" "-c" "/bin/wait4path /nix/store && exec ${enforceInputSources}" ];
      RunAtLoad = true;
      WatchPaths = [ "/Library/Input Methods/macSKK.app" ];
    };
  };

  launchd.user.agents.yaskkserv2 = {
    serviceConfig = {
      ProgramArguments = [
        "${yaskkserv2}/bin/yaskkserv2"
        "--no-daemonize"
        "--google-japanese-input=notfound"
        "--google-suggest"
        "--google-cache-filename=${yaskkserv2Cache}"
        "${yaskkserv2Dictionary}/dictionary.yaskkserv2"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${primaryUser}/Library/Logs/yaskkserv2.log";
      StandardErrorPath = "/Users/${primaryUser}/Library/Logs/yaskkserv2.error.log";
    };
  };

  system.activationScripts.postActivation.text = ''
    # "Previous input source" follows macOS' history, which includes macSKK's
    # internal katakana state after pressing q. Use "next input source" instead:
    # it cycles only the enabled sources, macSKK ABC and ひらがな.
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{ enabled = 0; value = { parameters = (32, 49, 262144); type = standard; }; }'
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{ enabled = 1; value = { parameters = (32, 49, 262144); type = standard; }; }'

    # Stop the annoying "Application is damaged" or "can't be opened" for downloaded apps
    echo "Removing quarantine attribute from applications..."
    apps=(
      "/Applications/kitty.app"
      "/Applications/Zen Browser.app"
      "/Applications/Discord.app"
      "/Applications/Slack.app"
      "/Applications/Microsoft Teams.app"
      "/Applications/1Password.app"
      "/Applications/ChatGPT.app"
    )
    
    for app in "''${apps[@]}"; do
      if [ -e "$app" ]; then
        xattr -d com.apple.quarantine "$app" 2>/dev/null || true
      fi
    done
  '';

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = 5; 

  # Homebrew
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "kitty"
      "claude"
      "chatgpt"
      "macskk"
      "jetbrains-toolbox"
      # Ice: menu bar manager
      "jordanbaird-ice"
    ];
    brews = [
      "mas"
    ];
  };

  # Aerospace
  services.aerospace = {
    enable = true;
    settings = {
      gaps = {
        inner = { horizontal = 0; vertical = 0; };
        outer = { left = 0; bottom = 0; top = 0; right = 0; };
      };
      on-window-detected = [
        { "if".app-id = "com.microsoft.teams"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "com.hnc.Discord"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "com.tinyspeck.slackmacgap"; run = "move-node-to-workspace 1"; }
        { "if".app-id = "org.mozilla.thunderbird"; run = "move-node-to-workspace 8"; }
        { "if".app-id = "com.1password.1password"; run = "layout floating"; }
      ];
      mode.main.binding = {
        # `open -n` alone spawns a fully separate kitty app per window, so every
        # window ends up as its own entry in the cmd-tab app switcher.
        # --single-instance makes the new invocation hand off to the running
        # kitty, which opens a new OS window inside it instead.
        #
        # Two launchers because neither one does both jobs. `open` goes through
        # launch services, which drops --directory once kitty is already running
        # and leaves the new window in /; exec'ing the binary keeps --directory,
        # and that process exits as soon as it has handed off. But a cold start
        # has to go through `open`, or the long-lived kitty inherits Aerospace's
        # launchd process group and every terminal dies whenever the Aerospace
        # agent restarts (e.g. on darwin-rebuild switch).
        "alt-enter" = "exec-and-forget /bin/bash -c 'if /usr/bin/pgrep -qx kitty; then /Applications/kitty.app/Contents/MacOS/kitty --single-instance --directory ~; else open -na kitty --args --single-instance --directory ~; fi'";
        "alt-d" = "exec-and-forget /bin/bash -c 'sleep 0.1 && osascript -e \"tell application \\\"System Events\\\" to keystroke space using command down\"'" ;
        "alt-q" = "close";
        "alt-h" = "focus left";
        "alt-j" = "focus down";
        "alt-k" = "focus up";
        "alt-l" = "focus right";
        "alt-shift-h" = "move left";
        "alt-shift-j" = "move down";
        "alt-shift-k" = "move up";
        "alt-shift-l" = "move right";
        "alt-1" = "workspace 1";
        "alt-2" = "workspace 2";
        "alt-3" = "workspace 3";
        "alt-4" = "workspace 4";
        "alt-5" = "workspace 5";
        "alt-6" = "workspace 6";
        "alt-7" = "workspace 7";
        "alt-8" = "workspace 8";
        "alt-9" = "workspace 9";
        "alt-shift-1" = "move-node-to-workspace 1";
        "alt-shift-2" = "move-node-to-workspace 2";
        "alt-shift-3" = "move-node-to-workspace 3";
        "alt-shift-4" = "move-node-to-workspace 4";
        "alt-shift-5" = "move-node-to-workspace 5";
        "alt-shift-6" = "move-node-to-workspace 6";
        "alt-shift-7" = "move-node-to-workspace 7";
        "alt-shift-8" = "move-node-to-workspace 8";
        "alt-shift-9" = "move-node-to-workspace 9";
        
        # Multi-monitor and workspace management
        "alt-tab" = "workspace-back-and-forth";
        "alt-comma" = "focus-monitor prev --wrap-around";
        "alt-period" = "focus-monitor next --wrap-around";
        "alt-shift-comma" = "move-node-to-monitor prev --wrap-around";
        "alt-shift-period" = "move-node-to-monitor next --wrap-around";
        "alt-ctrl-comma" = "move-workspace-to-monitor prev --wrap-around";
        "alt-ctrl-period" = "move-workspace-to-monitor next --wrap-around";

        "alt-f" = "fullscreen";
        "alt-s" = "layout v_accordion";
        "alt-w" = "layout h_accordion";
        "alt-e" = "layout tiles horizontal vertical";
        "alt-b" = "layout tiles horizontal";
        "alt-v" = "layout tiles vertical";
        "alt-shift-space" = "layout floating tiling";
        "alt-r" = "mode resize";
      };
      mode.resize.binding = {
        "h" = "resize width -50";
        "j" = "resize height +50";
        "k" = "resize height -50";
        "l" = "resize width +50";
        "enter" = "mode main";
        "esc" = "mode main";
      };
    };
  };
}
