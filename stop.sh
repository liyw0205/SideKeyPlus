#!/system/bin/sh

SKP_DIR="/data/adb/SideKeyPlus"
MODDIR="/data/adb/modules/SideKeyPlus"
CONFIG_PATH="$SKP_DIR/config.ini"
PID_DIR="$SKP_DIR/pid"
WWW_DIR="$SKP_DIR/www"

detect_busybox() {
  if [ -x /data/adb/magisk/busybox ]; then
    echo /data/adb/magisk/busybox
  elif [ -x /data/adb/ksu/bin/busybox ]; then
    echo /data/adb/ksu/bin/busybox
  elif [ -x /data/adb/ap/bin/busybox ]; then
    echo /data/adb/ap/bin/busybox
  else
    echo busybox
  fi
}

BB="$(detect_busybox)"

bb() {
  "$BB" "$@"
}

is_alive() {
  pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

cmdline_of_pid() {
  pid="$1"
  tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null
}

kill_pid() {
  pid="$1"
  [ -n "$pid" ] || return 0

  if is_alive "$pid"; then
    kill "$pid" 2>/dev/null
    bb sleep 0.2
    kill -9 "$pid" 2>/dev/null
  fi
}

kill_pid_file() {
  f="$1"

  if [ -f "$f" ]; then
    pid="$(cat "$f" 2>/dev/null)"
    kill_pid "$pid"
    rm -f "$f"
  fi
}

kill_by_cmd_match() {
  k1="$1"
  k2="$2"
  k3="$3"

  for p in $(bb ps -o PID= -A 2>/dev/null); do
    [ -n "$p" ] || continue

    cmd="$(cmdline_of_pid "$p")"
    [ -n "$cmd" ] || continue

    case "$cmd" in
      *"$k1"*)
        ok=1

        if [ -n "$k2" ]; then
          case "$cmd" in
            *"$k2"*) ;;
            *) ok=0 ;;
          esac
        fi

        if [ -n "$k3" ]; then
          case "$cmd" in
            *"$k3"*) ;;
            *) ok=0 ;;
          esac
        fi

        if [ "$ok" = "1" ]; then
          kill_pid "$p"
        fi
        ;;
    esac
  done
}

WEB_PORT="$(bb grep -E '^WEB_PORT=' "$CONFIG_PATH" 2>/dev/null | bb tail -n 1 | bb sed 's/^[^=]*=//')"
[ -z "$WEB_PORT" ] && WEB_PORT=8777

kill_pid_file "$PID_DIR/backend.pid"
kill_pid_file "$PID_DIR/httpd.pid"
kill_pid_file "$PID_DIR/keyd.pid"

kill_by_cmd_match "$MODDIR/bin/skp-keyd" "" ""
kill_by_cmd_match "httpd -f -p 127.0.0.1:$WEB_PORT" "$WWW_DIR" ""
kill_by_cmd_match "$MODDIR/service.sh" "start_backend_only" ""
kill_by_cmd_match "backend_loop" "SideKeyPlus" ""

rm -f "$PID_DIR/backend.pid"
rm -f "$PID_DIR/httpd.pid"
rm -f "$PID_DIR/keyd.pid"
rm -f "$PID_DIR/service.lock"

echo "SideKey+ stopped"
exit 0