#!/system/bin/sh

MODDIR="/data/adb/modules/SideKeyPlus"
COMMON_SH="$MODDIR/common.sh"

[ -f "$COMMON_SH" ] || exit 1
. "$COMMON_SH"

ensure_path_env

PORT="$(config_get WEB_PORT)"
[ -z "$PORT" ] && PORT=8777

URL="http://127.0.0.1:$PORT/webui/"

HTTPD_PID="$(cat "$PID_DIR/httpd.pid" 2>/dev/null)"
BACKEND_PID="$(cat "$PID_DIR/backend.pid" 2>/dev/null)"
KEYD_PID="$(cat "$PID_DIR/keyd.pid" 2>/dev/null)"

if ! is_pid_alive "$HTTPD_PID"; then
  /system/bin/sh "$MODDIR/service.sh" >/dev/null 2>&1 &
  bb sleep 1
fi

if pm path io.github.a13e300.ksuwebui > /dev/null 2>&1; then
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "SideKeyPlus"
elif pm path com.dergoogler.mmrl.wx > /dev/null 2>&1; then
    am start -n "com.dergoogler.mmrl.wx/.ui.activity.webui.WebUIActivity" -e MOD_ID "SideKeyPlus"
else
  am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1
fi

exit 0