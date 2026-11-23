#!/usr/bin/env bash
# Helper for Scrcpy.app. Invoked as a child of the Mach-O Scrcpy executable.
# This file must live at Contents/Resources/launch.sh so $0-relative paths
# resolve to the bundled adb/scrcpy helpers.

set -euo pipefail

: "${HOME:=/Users/$(/usr/bin/id -un)}"
LOG="$HOME/Library/Logs/Scrcpy-launcher.log"
/bin/mkdir -p "$HOME/Library/Logs"

if [ -f "$LOG" ]; then
  sz=$(/usr/bin/wc -c < "$LOG" | /usr/bin/tr -d ' ')
  if [ "$sz" -gt 204800 ]; then
    /bin/mv -f "$LOG" "$LOG.1"
  fi
fi

# Direct append is more reliable than process substitution, which can be
# killed before it flushes if the script exits quickly.
exec 2>>"$LOG"
log() { printf '%s %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG"; }

ALREADY_DIALOG=0
SCRIPT_OK=0
OWNED_ADB_PID=""
LAST_ERROR=""
SCRCPY_OUT=""

show_dialog() {
  local msg="$1" tmp
  ALREADY_DIALOG=1
  tmp=$(/usr/bin/mktemp)
  printf '%s' "$msg" > "$tmp"
  /usr/bin/osascript -e 'on run argv
    set p to item 1 of argv
    set f to open for access POSIX file p
    set t to read f as «class utf8»
    close access f
    display dialog t with title "Scrcpy" buttons {"OK"} default button "OK" with icon caution
  end run' "$tmp" || true
  /bin/rm -f "$tmp"
}

on_err() {
  LAST_ERROR="line $1 (exit $2): $3"
  log "ERR $LAST_ERROR"
}

trap 'on_err "$LINENO" "$?" "$BASH_COMMAND"' ERR

cleanup_adb() {
  if [ -n "${OWNED_ADB_PID:-}" ]; then
    log "stopping owned adb server pid=$OWNED_ADB_PID"
    kill "$OWNED_ADB_PID" 2>/dev/null || true
    wait "$OWNED_ADB_PID" 2>/dev/null || true
    OWNED_ADB_PID=""
  fi
}

on_exit() {
  local status=$?
  cleanup_adb
  [ -n "${SCRCPY_OUT:-}" ] && /bin/rm -f "$SCRCPY_OUT"
  if [ "$SCRIPT_OK" -eq 1 ]; then
    log "exit ok (status=$status)"
    return 0
  fi
  if [ "$status" -ne 0 ] && [ "$ALREADY_DIALOG" -eq 0 ]; then
    log "exit failure status=$status; showing dialog"
    show_dialog "Scrcpy の起動に失敗しました。${LAST_ERROR:+
$LAST_ERROR}

詳しくはログを見てください：
$LOG"
  else
    log "exit status=$status"
  fi
}

trap on_exit EXIT

# Resolve bundled binaries from this script's location
# ($0 must be Contents/Resources/launch.sh inside the app).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
if [ ! -d "$SCRIPT_DIR/../MacOS/helpers" ]; then
  log "cannot find MacOS/helpers relative to \$0=$0 (SCRIPT_DIR=$SCRIPT_DIR)"
  LAST_ERROR="アプリバンドルの中に adb / scrcpy が見つかりません"
  exit 1
fi
MACOS=$(cd "$SCRIPT_DIR/../MacOS" && pwd)
# helpers/ avoids APFS case-collision with the Scrcpy Mach-O executable
ADB="$MACOS/helpers/adb"
SCRCPY="$MACOS/helpers/scrcpy"
AWK=/usr/bin/awk
DNS_SD=/usr/bin/dns-sd
DSCACHE=/usr/bin/dscacheutil
export PATH="$MACOS/helpers:$MACOS:/usr/bin:/bin:/usr/sbin:/sbin"
export ADB_MDNS_OPENSCREEN=1
PREFERRED="${PREFERRED:-}"

log "==== start pid=$$ ppid=$PPID ===="
log "HOME=$HOME MACOS=$MACOS ADB=$ADB SCRCPY=$SCRCPY"
log "argv0=$0 test_fail=${SCRCPY_LAUNCHER_TEST_FAIL:-}"

port_open() {
  /usr/bin/nc -z 127.0.0.1 5037 >/dev/null 2>&1
}

ready_serials() {
  "$ADB" devices 2>/dev/null | "$AWK" 'NR>1 && $2 == "device" { print $1 }' || true
}

first_ready() {
  "$ADB" devices 2>/dev/null | "$AWK" 'NR>1 && $2 == "device" { print $1; exit }' || true
}

ready_count() {
  ready_serials | "$AWK" 'BEGIN { n = 0 } NF { n++ } END { print n }'
}

disconnect_stale() {
  local serial state
  log "disconnect_stale"
  while read -r serial state; do
    [ -n "${serial:-}" ] || continue
    case "$state" in
      offline|unknown)
        log "disconnect stale $serial ($state)"
        "$ADB" disconnect "$serial" >/dev/null 2>&1 || true
        ;;
    esac
  done < <("$ADB" devices 2>/dev/null | "$AWK" 'NR>1 && $1 != "" { print $1, $2 }' || true)
}

pick_serial() {
  local preferred="$1"
  if [ -z "$preferred" ]; then
    first_ready
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
  done < <("$ADB" devices -l 2>/dev/null | "$AWK" 'NR>1 && $2 == "device" { print }' || true)
  first_ready
}

run_timed() {
  local secs="$1" out="$2" pid
  shift 2
  "$@" >"$out" 2>&1 &
  pid=$!
  sleep "$secs"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

kill_existing_adb_servers() {
  log "killing existing adb server (orphans included)"
  "$ADB" kill-server >/dev/null 2>&1 || true
  local i pids p
  i=0
  while [ "$i" -lt 20 ]; do
    if ! port_open; then
      log "port 5037 is free"
      return 0
    fi
    pids=$(/usr/sbin/lsof -nP -iTCP:5037 -sTCP:LISTEN -t 2>/dev/null || true)
    for p in $pids; do
      log "killing listener pid=$p"
      kill "$p" 2>/dev/null || true
    done
    sleep 0.2
    i=$((i + 1))
  done
  pids=$(/usr/sbin/lsof -nP -iTCP:5037 -sTCP:LISTEN -t 2>/dev/null || true)
  for p in $pids; do
    log "kill -9 leftover pid=$p"
    kill -9 "$p" 2>/dev/null || true
  done
  sleep 0.2
  if port_open; then
    log "WARNING: port 5037 still in use after kills"
    return 1
  fi
}

start_owned_nodaemon() {
  log "starting owned adb server nodaemon (child of this helper / Scrcpy.app)"
  if ! kill_existing_adb_servers; then
    LAST_ERROR="既存の adb サーバーを停止できませんでした"
    return 1
  fi
  "$ADB" server nodaemon >/dev/null 2>&1 &
  OWNED_ADB_PID=$!
  log "nodaemon pid=$OWNED_ADB_PID"
  local i=0
  while [ "$i" -lt 50 ]; do
    if ! kill -0 "$OWNED_ADB_PID" 2>/dev/null; then
      wait "$OWNED_ADB_PID" 2>/dev/null || true
      OWNED_ADB_PID=""
      LAST_ERROR="adb server nodaemon がすぐ終了しました"
      log "$LAST_ERROR"
      return 1
    fi
    if port_open && "$ADB" devices >/dev/null 2>&1; then
      log "owned adb server is ready"
      return 0
    fi
    sleep 0.1
    i=$((i + 1))
  done
  LAST_ERROR="adb サーバーの起動がタイムアウトしました"
  log "$LAST_ERROR"
  return 1
}

discover_targets() {
  local tmp host port ip
  tmp=$(/usr/bin/mktemp -d)
  if "$ADB" mdns check >/dev/null 2>&1; then
    log "adb mdns is available"
    "$ADB" mdns services 2>/dev/null | "$AWK" '
      $0 ~ /_adb-tls-connect(\._tcp)?/ {
        for (i = 1; i <= NF; i++) {
          if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$/) print $i
        }
      }
    ' || true
  else
    log "adb mdns not supported; using dns-sd"
  fi

  log "dns-sd browse _adb-tls-connect._tcp"
  run_timed 3 "$tmp/zone" "$DNS_SD" -Z _adb-tls-connect._tcp local.
  while read -r port host; do
    [ -n "$port" ] && [ -n "$host" ] || continue
    log "resolved SRV $host:$port"
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
      log "target $ip:$port"
      printf '%s:%s\n' "$ip" "$port"
    else
      log "no IPv4 for $host"
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
    log "adb connect $target"
    "$ADB" connect "$target" >>"$LOG" 2>&1 || true
  done < <(discover_targets | /usr/bin/sort -u)
}

# --- main ---

if [ ! -x "$ADB" ] || [ ! -x "$SCRCPY" ]; then
  LAST_ERROR="アプリ内の adb または scrcpy が見つかりません"
  log "$LAST_ERROR ADB=$ADB SCRCPY=$SCRCPY"
  exit 1
fi

if [ "${SCRCPY_LAUNCHER_TEST_FAIL:-}" = "nodevice" ]; then
  log "TEST_FAIL=nodevice"
  show_dialog "Pixel が見つかりません。Pixelで「ワイヤレス デバッグ」をオンにして同じWi-Fiにつなぐか、USBでつないでください。初めて使う場合は、先にワイヤレス デバッグのペアリングをしてください。"
  exit 1
fi

disconnect_stale || true
if [ -n "$(ready_serials)" ]; then
  log "reusing existing adb server; device already ready: $(ready_serials | /usr/bin/tr '\n' ' ')"
else
  log "no ready device; restarting adb under Scrcpy.app"
  start_owned_nodaemon
  attempt=0
  while [ "$attempt" -lt 3 ] && [ -z "$(ready_serials)" ]; do
    disconnect_stale || true
    connect_discovered
    if [ -n "$(ready_serials)" ]; then
      break
    fi
    attempt=$((attempt + 1))
    log "connect attempt $attempt finished with no ready device"
    sleep 1
  done
  disconnect_stale || true
fi

if [ "${SCRCPY_LAUNCHER_TEST_FAIL:-}" = "crash" ]; then
  log "TEST_FAIL=crash; running failing dummy instead of scrcpy"
  SCRCPY_OUT=$(/usr/bin/mktemp)
  start=$(/bin/date +%s)
  set +e
  /bin/sh -c 'echo "fake-scrcpy: simulated immediate failure"; exit 1' >"$SCRCPY_OUT" 2>&1
  scrcpy_status=$?
  set -e
else
  SERIAL=$(pick_serial "$PREFERRED")
  log "devices: $("$ADB" devices -l 2>/dev/null || true)"
  log "picked SERIAL=${SERIAL:-}"
  if [ -z "$SERIAL" ]; then
    show_dialog "Pixel が見つかりません。Pixelで「ワイヤレス デバッグ」をオンにして同じWi-Fiにつなぐか、USBでつないでください。初めて使う場合は、先にワイヤレス デバッグのペアリングをしてください。"
    exit 1
  fi

  COUNT=$(ready_count)
  log "ready_count=$COUNT; launching scrcpy (not exec)"
  SCRCPY_OUT=$(/usr/bin/mktemp)
  start=$(/bin/date +%s)
  set +e
  if [ "$COUNT" -gt 1 ]; then
    "$SCRCPY" -s "$SERIAL" "$@" >"$SCRCPY_OUT" 2>&1
    scrcpy_status=$?
  else
    "$SCRCPY" "$@" >"$SCRCPY_OUT" 2>&1
    scrcpy_status=$?
  fi
  set -e
fi

end=$(/bin/date +%s)
elapsed=$((end - start))
log "scrcpy output:"
/bin/cat "$SCRCPY_OUT" || true
log "scrcpy exit=$scrcpy_status after ${elapsed}s"

if [ "$scrcpy_status" -ne 0 ] && [ "$elapsed" -lt 5 ]; then
  tail=$(/usr/bin/tail -n 20 "$SCRCPY_OUT" 2>/dev/null || true)
  show_dialog "scrcpy がすぐ終了しました。

${tail}

詳しくはログを見てください：
$LOG"
  exit "$scrcpy_status"
fi

SCRIPT_OK=1
exit "$scrcpy_status"
