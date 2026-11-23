{ pkgs, lib, ... }:
let
  # Extra scrcpy flags. Leave empty to launch with defaults (plain `scrcpy`).
  # Example: scrcpyArgs = [ "--stay-awake" "--turn-screen-off" ];
  scrcpyArgs = [ ];

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
      <string>dev.r67018.scrcpy-launcher</string>
      <key>CFBundleVersion</key>
      <string>1.0</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleExecutable</key>
      <string>Scrcpy</string>
      <key>LSMinimumSystemVersion</key>
      <string>11.0</string>
      <key>NSHighResolutionCapable</key>
      <true/>
    </dict>
    </plist>
  '';

  launcher = pkgs.writeShellScript "Scrcpy" ''
    set -euo pipefail
    export PATH="${pkgs.android-tools}/bin:$PATH"

    if ! "${pkgs.android-tools}/bin/adb" devices | /usr/bin/awk 'NR>1 && $2 == "device" { found=1 } END { exit !found }'; then
      /usr/bin/osascript -e 'display dialog "Android 端末が見つかりません。USB デバッグを有効にして接続してください。" with title "Scrcpy" buttons {"OK"} default button "OK" with icon caution'
      exit 1
    fi

    exec "${pkgs.scrcpy}/bin/scrcpy" ${lib.escapeShellArgs scrcpyArgs}
  '';

  scrcpyApp = pkgs.runCommand "scrcpy-app" { } ''
    mkdir -p $out/Applications/Scrcpy.app/Contents/MacOS
    cp ${infoPlist} $out/Applications/Scrcpy.app/Contents/Info.plist
    cp ${launcher} $out/Applications/Scrcpy.app/Contents/MacOS/Scrcpy
    chmod +x $out/Applications/Scrcpy.app/Contents/MacOS/Scrcpy
  '';
in
{
  environment.systemPackages = [ scrcpyApp ];
}
