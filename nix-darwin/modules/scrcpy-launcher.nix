{ pkgs, lib, ... }:
let
  # Extra scrcpy flags. Leave empty to launch with defaults (plain `scrcpy`).
  # Example: scrcpyArgs = [ "--stay-awake" "--turn-screen-off" ];
  scrcpyArgs = [ ];

  # Preferred device serial or name when more than one is ready. Empty = first ready device.
  # Example: preferredDevice = "59131FDCR0084K";  # or "Pixel 10"
  preferredDevice = "";

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
      <string>1.1</string>
      <key>CFBundleShortVersionString</key>
      <string>1.1</string>
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
    export PATH="${pkgs.android-tools}/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    # Openscreen is the mdns backend official adb uses on macOS; this
    # android-tools build still reports "mdns is not supported", so we
    # also discover via dns-sd. Set the env in case a later adb starts supporting it.
    export ADB_MDNS_OPENSCREEN=1

    ADB="${pkgs.android-tools}/bin/adb"
    SCRCPY="${pkgs.scrcpy}/bin/scrcpy"
    PREFERRED=${lib.escapeShellArg preferredDevice}
    AWK=/usr/bin/awk
    DNS_SD=/usr/bin/dns-sd
    DSCACHE=/usr/bin/dscacheutil

    "$ADB" start-server >/dev/null

    ready_serials() {
      "$ADB" devices | "$AWK" 'NR>1 && $2 == "device" { print $1 }'
    }

    disconnect_stale() {
      local serial state
      while read -r serial state; do
        [ -n "''${serial:-}" ] || continue
        case "$state" in
          offline|unknown)
            "$ADB" disconnect "$serial" >/dev/null 2>&1 || true
            ;;
        esac
      done < <("$ADB" devices | "$AWK" 'NR>1 && $1 != "" { print $1, $2 }')
    }

    pick_serial() {
      local preferred="$1"
      if [ -z "$preferred" ]; then
        ready_serials | /usr/bin/head -n 1
        return 0
      fi
      local pref_lc line serial rest
      pref_lc=$(printf '%s' "$preferred" | /usr/bin/tr '[:upper:]' '[:lower:]' | /usr/bin/tr ' ' '_')
      while read -r line; do
        serial=$(printf '%s' "$line" | "$AWK" '{ print $1 }')
        rest=$(printf '%s' "$line" | /usr/bin/tr '[:upper:]' '[:lower:]')
        case "$rest" in
          *"$pref_lc"*)
            printf '%s\n' "$serial"
            return 0
            ;;
        esac
      done < <("$ADB" devices -l | "$AWK" 'NR>1 && $2 == "device" { print }')
      ready_serials | /usr/bin/head -n 1
    }

    run_timed() {
      local secs="$1" out="$2"
      shift 2
      "$@" >"$out" 2>&1 &
      local pid=$!
      sleep "$secs"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    }

    # Print unique ip:port targets for already-paired wireless debugging
    # (_adb-tls-connect._tcp). Pairing services are ignored.
    discover_targets() {
      local tmp host port ip
      tmp=$(/usr/bin/mktemp -d)

      if "$ADB" mdns check >/dev/null 2>&1; then
        "$ADB" mdns services 2>/dev/null | "$AWK" '
          $0 ~ /_adb-tls-connect(\._tcp)?/ {
            for (i = 1; i <= NF; i++) {
              if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$/) print $i
            }
          }
        '
      fi

      run_timed 3 "$tmp/zone" "$DNS_SD" -Z _adb-tls-connect._tcp local.
      while read -r port host; do
        [ -n "$port" ] && [ -n "$host" ] || continue
        ip=$("$DSCACHE" -q host -a name "$host" | "$AWK" '/^ip_address:/ { print $2; exit }')
        if [ -z "$ip" ]; then
          run_timed 2 "$tmp/a" "$DNS_SD" -G v4 "$host."
          ip=$("$AWK" '{
            for (i = 1; i <= NF; i++) {
              if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) { print $i; exit }
            }
          }' "$tmp/a")
        fi
        if [ -n "$ip" ]; then
          printf '%s:%s\n' "$ip" "$port"
        fi
      done < <("$AWK" '
        $2 == "SRV" {
          port = $5
          host = $6
          sub(/\.$/, "", host)
          print port, host
        }
      ' "$tmp/zone")

      /bin/rm -rf "$tmp"
    }

    connect_discovered() {
      local target
      while read -r target; do
        [ -n "$target" ] || continue
        "$ADB" connect "$target" >/dev/null 2>&1 || true
      done < <(discover_targets | /usr/bin/sort -u)
    }

    disconnect_stale
    if [ -z "$(ready_serials)" ]; then
      # mDNS records can take a moment to appear after joining Wi-Fi.
      attempt=0
      while [ "$attempt" -lt 3 ] && [ -z "$(ready_serials)" ]; do
        disconnect_stale
        connect_discovered
        if [ -n "$(ready_serials)" ]; then
          break
        fi
        attempt=$((attempt + 1))
        sleep 1
      done
    fi
    disconnect_stale

    SERIAL=$(pick_serial "$PREFERRED")
    if [ -z "$SERIAL" ]; then
      /usr/bin/osascript -e 'display dialog "Pixel が見つかりません。Pixelで「ワイヤレス デバッグ」をオンにして同じWi-Fiにつなぐか、USBでつないでください。初めて使う場合は、先にワイヤレス デバッグのペアリングをしてください。" with title "Scrcpy" buttons {"OK"} default button "OK" with icon caution'
      exit 1
    fi

    COUNT=$(ready_serials | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    if [ "$COUNT" -gt 1 ]; then
      exec "$SCRCPY" -s "$SERIAL" ${lib.escapeShellArgs scrcpyArgs}
    else
      exec "$SCRCPY" ${lib.escapeShellArgs scrcpyArgs}
    fi
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
