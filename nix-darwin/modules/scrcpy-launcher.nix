{ pkgs, lib, ... }:
let
  # Extra scrcpy flags. Leave empty to launch with defaults (plain `scrcpy`).
  # Example: scrcpyArgs = [ "--stay-awake" "--turn-screen-off" ];
  # These are passed through the helper if we ever thread them; the helper
  # currently launches scrcpy with no extra flags (same as an empty list).
  scrcpyArgs = [ ];

  # Preferred device serial or name when more than one is ready. Empty = first ready device.
  # Example: preferredDevice = "59131FDCR0084K";  # or "Pixel 10"
  # Export as PREFERRED in the helper if set.
  preferredDevice = "";

  bundleId = "dev.r67018.scrcpy-launcher";

  infoPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleName</key>
      <string>Scrcpy</string>
      <key>CFBundleDisplayName</key>
      <string>Scrcpy</string>
      <key>CFBundleIdentifier</key>
      <string>${bundleId}</string>
      <key>CFBundleVersion</key>
      <string>1.3</string>
      <key>CFBundleShortVersionString</key>
      <string>1.3</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleExecutable</key>
      <string>Scrcpy</string>
      <key>LSMinimumSystemVersion</key>
      <string>11.0</string>
      <key>NSHighResolutionCapable</key>
      <true/>
      <key>NSLocalNetworkUsageDescription</key>
      <string>Scrcpy が同じ Wi-Fi 上の Pixel に接続して、画面ミラーリングを行います。</string>
      <key>NSBonjourServices</key>
      <array>
        <string>_adb-tls-connect._tcp</string>
      </array>
    </dict>
    </plist>
  '';

  # Optional preferredDevice is exported for the helper; extra scrcpy flags
  # are appended when the helper launches scrcpy.
  preferredExport = lib.escapeShellArg preferredDevice;
  scrcpyArgsShell = lib.escapeShellArgs scrcpyArgs;

  scrcpyApp = pkgs.stdenv.mkDerivation {
    pname = "scrcpy-app";
    version = "1.3";
    dontUnpack = true;
    # stdenv darwin fixup re-applies linker ad-hoc signatures and would
    # overwrite the bundle-id we set in installPhase.
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      app=$out/Applications/Scrcpy.app
      mkdir -p $app/Contents/MacOS $app/Contents/Resources

      $CC -Os -Wl,-no_adhoc_codesign \
        -DLAUNCH_BASH='"${pkgs.bash}/bin/bash"' \
        -o $app/Contents/MacOS/Scrcpy \
        ${./scrcpy-launcher-main.c}

      # Copy the helper into the bundle so $0-relative paths find helpers/.
      # A short preamble sets PREFERRED / extra flags from the nix module.
      {
        echo '#!/usr/bin/env bash'
        echo "export PREFERRED=${preferredExport}"
        echo "set -- ${scrcpyArgsShell} \"\$@\""
        echo 'source "$0.helper"'
      } > $app/Contents/Resources/launch.sh
      cp ${./scrcpy-launcher-launch.sh} $app/Contents/Resources/launch.sh.helper
      chmod +x $app/Contents/Resources/launch.sh $app/Contents/Resources/launch.sh.helper
      # Prepending with `source` would re-run set/traps from the helper under
      # $0=launch.sh (good). Strip the helper shebang; it's sourced.
      /usr/bin/sed -i.bak '1{/^#!/d;}' $app/Contents/Resources/launch.sh.helper && rm -f $app/Contents/Resources/launch.sh.helper.bak
      cp ${infoPlist} $app/Contents/Info.plist
      printf 'APPL????' > $app/Contents/PkgInfo

      # helpers/ is required: APFS is case-insensitive, so MacOS/scrcpy
      # would overwrite the Scrcpy Mach-O. Re-sign copies with the app
      # identifier so TCC groups Local Network use under "Scrcpy".
      mkdir -p $app/Contents/MacOS/helpers
      cp ${pkgs.android-tools}/bin/adb $app/Contents/MacOS/helpers/adb
      cp ${pkgs.scrcpy}/bin/.scrcpy-wrapped $app/Contents/MacOS/helpers/scrcpy
      chmod u+w $app/Contents/MacOS/Scrcpy \
                $app/Contents/MacOS/helpers/adb \
                $app/Contents/MacOS/helpers/scrcpy

      sign() {
        local bin="$1"
        /usr/bin/codesign --remove-signature "$bin" 2>/dev/null || true
        /usr/bin/codesign --sign - --force --identifier ${bundleId} "$bin"
        ident=$(/usr/bin/codesign -dv "$bin" 2>&1 | /usr/bin/awk -F= '/^Identifier=/{print $2; exit}')
        if [ "$ident" != "${bundleId}" ]; then
          echo "codesign identifier mismatch for $bin: got '$ident'" >&2
          /usr/bin/codesign -dv --verbose=4 "$bin" >&2 || true
          exit 1
        fi
      }
      sign $app/Contents/MacOS/Scrcpy
      sign $app/Contents/MacOS/helpers/adb
      sign $app/Contents/MacOS/helpers/scrcpy
      sign $app
      runHook postInstall
    '';
  };
in
{
  environment.systemPackages = [ scrcpyApp ];
}
