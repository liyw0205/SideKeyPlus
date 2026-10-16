#!/system/bin/sh

MODDIR="/data/adb/modules/SideKeyPlus"
COMMON_SH="$MODDIR/common.sh"

[ -f "$COMMON_SH" ] || exit 1
. "$COMMON_SH"

mkdir -p "$SKP_DIR" "$WWW_DIR" "$CGI_DIR" "$API_DIR" "$ACTION_DIR" "$LOG_DIR" "$PID_DIR" "$WEBROOT_WEB_DIR"
ensure_path_env

WEB_PORT="$(config_get WEB_PORT)"
[ -z "$WEB_PORT" ] && WEB_PORT=8777

case "$WEB_PORT" in
  ''|*[!0-9]*)
    logw "WEB_PORT 非数字：$WEB_PORT，已回退到 8777"
    WEB_PORT=8777
    ;;
esac

cmdline_of_pid() {
  pid="$1"
  tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null
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
          logw "按命令行停止进程 PID=$p CMD=$cmd"
          kill "$p" 2>/dev/null
          bb sleep 0.2
          kill -9 "$p" 2>/dev/null
        fi
        ;;
    esac
  done
}

ensure_default_shell_files() {
  for e in \
    UP UP_RESET DOWN DOWN_RESET \
    VOLUME_UP_CLICK VOLUME_UP_DOUBLE VOLUME_UP_LONG \
    VOLUME_DOWN_CLICK VOLUME_DOWN_DOUBLE VOLUME_DOWN_LONG \
    VOLUME_BOTH_CLICK
  do
    f="$ACTION_DIR/${e}.custom.sh"
    if [ ! -f "$f" ]; then
      cat > "$f" <<'EOF'
#!/system/bin/sh
# 在这里写自定义 shell
EOF
      chmod 0755 "$f"
    fi
  done
}

ensure_run_action_file() {
  f="$MODDIR/run_action.sh"

  if [ ! -f "$f" ]; then
    cat > "$f" <<'EOF'
#!/system/bin/sh

COMMON="/data/adb/modules/SideKeyPlus/common.sh"
EVENT="$1"

[ -z "$EVENT" ] && exit 1
[ -f "$COMMON" ] || exit 1

. "$COMMON"

case "$EVENT" in
  UP|UP_RESET|DOWN|DOWN_RESET|VOLUME_UP_CLICK|VOLUME_UP_DOUBLE|VOLUME_UP_LONG|VOLUME_DOWN_CLICK|VOLUME_DOWN_DOUBLE|VOLUME_DOWN_LONG|VOLUME_BOTH_CLICK)
    run_action_event "$EVENT"
    ;;
  *)
    exit 1
    ;;
esac

exit 0
EOF
  fi

  chmod 0755 "$f" 2>/dev/null
}

write_webui() {
  ensure_default_shell_files

  mkdir -p "$WEBROOT_WEB_DIR"

  if [ -f "$WEBROOT_TEMPLATE" ]; then
    bb sed "s/__WEB_PORT__/$WEB_PORT/g" "$WEBROOT_TEMPLATE" > "$WEBROOT_INDEX"
    chmod 0644 "$WEBROOT_INDEX" 2>/dev/null
    logi "WebUI 已按端口生成：$WEBROOT_INDEX PORT=$WEB_PORT"
  elif [ -f "$WEBROOT_INDEX" ]; then
    if bb grep -q "__WEB_PORT__" "$WEBROOT_INDEX" 2>/dev/null; then
      bb sed -i "s/__WEB_PORT__/$WEB_PORT/g" "$WEBROOT_INDEX" 2>/dev/null
    else
      bb sed -i "s/const WEB_PORT='[0-9][0-9]*';/const WEB_PORT='$WEB_PORT';/g" "$WEBROOT_INDEX" 2>/dev/null
      bb sed -i "s/const WEB_PORT=\"[0-9][0-9]*\";/const WEB_PORT=\"$WEB_PORT\";/g" "$WEBROOT_INDEX" 2>/dev/null
    fi
    chmod 0644 "$WEBROOT_INDEX" 2>/dev/null
    logw "未找到模板，已直接修正 index.html 端口：$WEBROOT_INDEX PORT=$WEB_PORT"
  else
    loge "WebUI 模板不存在：$WEBROOT_TEMPLATE"

    cat > "$WEBROOT_INDEX" <<EOF
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SideKey+</title>
<style>
body{font-family:sans-serif;background:#080d19;color:#eef4ff;padding:24px}
.card{max-width:720px;margin:auto;background:#121a2b;border:1px solid rgba(255,255,255,.12);border-radius:18px;padding:20px}
code{color:#93c5fd}
</style>
</head>
<body>
<div class="card">
<h2>SideKey+ WebUI 文件缺失</h2>
<p>请检查模块内模板是否存在：</p>
<p><code>$WEBROOT_TEMPLATE</code></p>
<p>当前端口：<code>$WEB_PORT</code></p>
</div>
</body>
</html>
EOF

    chmod 0644 "$WEBROOT_INDEX" 2>/dev/null
  fi

  cat > "$WEBROOT_WEB/index.html" <<EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SideKey+</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: none;
      display: block;
    }
  </style>
</head>
<body>
  <iframe src="http://127.0.0.1:$WEB_PORT/webui"></iframe>
</body>
</html>
EOF

  rm -rf "$WEB_DIR" 2>/dev/null
  ln -s "$WEBROOT_WEB_DIR" "$WEB_DIR" 2>/dev/null

  if [ -L "$WEB_DIR" ] || [ -d "$WEB_DIR" ]; then
    logi "WebUI 已链接：$WEB_DIR -> $WEBROOT_WEB_DIR"
  else
    loge "WebUI 链接失败：$WEB_DIR -> $WEBROOT_WEB_DIR"
  fi
}

write_api_common() {
  cat > "$API_DIR/common.sh" <<'EOF'
#!/system/bin/sh
MODDIR="/data/adb/modules/SideKeyPlus"

[ -f "$MODDIR/common.sh" ] || exit 1
[ -f "$MODDIR/cgi.sh" ] || exit 1

. "$MODDIR/common.sh"
. "$MODDIR/cgi.sh"
EOF

  chmod 0755 "$API_DIR/common.sh"
}

write_api_scripts() {
  write_api_common

  cat > "$API_DIR/status" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

print_json_header

BACKEND_PID="$(cat "$PID_DIR/backend.pid" 2>/dev/null)"
HTTPD_PID="$(cat "$PID_DIR/httpd.pid" 2>/dev/null)"
KEYD_PID="$(cat "$PID_DIR/keyd.pid" 2>/dev/null)"

echo "{"
echo "\"backend_running\":$(is_pid_alive "$BACKEND_PID" && echo true || echo false),"
echo "\"keyd_running\":$(is_pid_alive "$KEYD_PID" && echo true || echo false),"
echo "\"keyd_pid\":\"$(printf '%s' "$KEYD_PID" | json_escape)\","
echo "\"httpd_running\":$(is_pid_alive "$HTTPD_PID" && echo true || echo false),"
echo "\"slider_value\":\"$(slider_value)\","
echo "\"config\":{"

first=1

print_pair() {
  k="$1"
  v="$2"
  esc="$(printf '%s' "$v" | json_escape)"
  [ "$first" = "1" ] || echo ","
  first=0
  printf '"%s":"%s"' "$k" "$esc"
}

if [ -f "$CONFIG_PATH" ]; then
  while IFS= read -r line; do
    case "$line" in
      ""|\#*) continue ;;
    esac
    key="${line%%=*}"
    val="${line#*=}"
    print_pair "$key" "$val"
  done < "$CONFIG_PATH"
fi

for item in \
  "ACTION_UP_SHELL:$ACTION_DIR/UP.custom.sh" \
  "ACTION_UP_RESET_SHELL:$ACTION_DIR/UP_RESET.custom.sh" \
  "ACTION_DOWN_SHELL:$ACTION_DIR/DOWN.custom.sh" \
  "ACTION_DOWN_RESET_SHELL:$ACTION_DIR/DOWN_RESET.custom.sh" \
  "ACTION_VOLUME_UP_CLICK_SHELL:$ACTION_DIR/VOLUME_UP_CLICK.custom.sh" \
  "ACTION_VOLUME_UP_DOUBLE_SHELL:$ACTION_DIR/VOLUME_UP_DOUBLE.custom.sh" \
  "ACTION_VOLUME_UP_LONG_SHELL:$ACTION_DIR/VOLUME_UP_LONG.custom.sh" \
  "ACTION_VOLUME_DOWN_CLICK_SHELL:$ACTION_DIR/VOLUME_DOWN_CLICK.custom.sh" \
  "ACTION_VOLUME_DOWN_DOUBLE_SHELL:$ACTION_DIR/VOLUME_DOWN_DOUBLE.custom.sh" \
  "ACTION_VOLUME_DOWN_LONG_SHELL:$ACTION_DIR/VOLUME_DOWN_LONG.custom.sh" \
  "ACTION_VOLUME_BOTH_CLICK_SHELL:$ACTION_DIR/VOLUME_BOTH_CLICK.custom.sh"
do
  k="${item%%:*}"
  f="${item#*:}"
  v=""
  [ -f "$f" ] && v="$(cat "$f")"
  print_pair "$k" "$v"
done

echo
echo "}"
echo "}"
EOF

  cat > "$API_DIR/slider" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

print_json_header
echo "{\"ok\":true,\"slider_value\":\"$(slider_value)\"}"
EOF

  cat > "$API_DIR/save_config" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

if parse_post_to_config; then
  print_json_header
  echo '{"ok":true,"message":"配置已保存"}'
else
  print_json_header
  echo '{"ok":false,"message":"配置保存失败"}'
fi
EOF

  cat > "$API_DIR/calibrate" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

BODY="$(read_body)"
KEY=""

OLD_IFS="$IFS"
IFS='&'
for pair in $BODY; do
  k="${pair%%=*}"
  v="${pair#*=}"
  k="$(urldecode "$k")"
  v="$(urldecode "$v")"
  [ "$k" = "key" ] && KEY="$v"
done
IFS="$OLD_IFS"

VAL="$(slider_value)"

case "$KEY" in
  VALUE_UP|VALUE_MID|VALUE_DOWN)
    if [ -n "$VAL" ]; then
      if config_set_multi "$KEY" "$VAL"; then
        MSG="已把当前值 $VAL 保存到 $KEY"
        OK=true
      else
        MSG="写入配置失败"
        OK=false
      fi
    else
      MSG="读取当前键值失败"
      OK=false
    fi
    ;;
  *)
    MSG="无效 key"
    OK=false
    ;;
esac

print_json_header
echo "{\"ok\":$OK,\"message\":\"$MSG\"}"
EOF

  cat > "$API_DIR/start_backend" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

/system/bin/sh /data/adb/modules/SideKeyPlus/service.sh start_backend_only >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"后端启动命令已发送"}'
EOF

  cat > "$API_DIR/stop_backend" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

(
  bb sleep 0.2
  /system/bin/sh /data/adb/SideKeyPlus/stop.sh >/dev/null 2>&1
  bb sleep 0.3
  /system/bin/sh /data/adb/modules/SideKeyPlus/service.sh start_httpd_only >/dev/null 2>&1
) >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"全部后端与音量键服务已停止，面板服务正在自动恢复"}'
EOF

  cat > "$API_DIR/start_slider_backend" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

/system/bin/sh /data/adb/modules/SideKeyPlus/service.sh start_backend_only >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"三段键后端启动命令已发送"}'
EOF

  cat > "$API_DIR/stop_slider_backend" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

/system/bin/sh /data/adb/modules/SideKeyPlus/service.sh stop_backend_only >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"三段键后端停止命令已发送"}'
EOF

  cat > "$API_DIR/start_keyd" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

/system/bin/sh /data/adb/modules/SideKeyPlus/service.sh start_keyd_only >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"音量键服务启动命令已发送"}'
EOF

  cat > "$API_DIR/stop_keyd" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

/system/bin/sh /data/adb/modules/SideKeyPlus/service.sh stop_keyd_only >/dev/null 2>&1 &

print_json_header
echo '{"ok":true,"message":"音量键服务停止命令已发送"}'
EOF

  cat > "$API_DIR/test_action" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

BODY="$(read_body)"
EVENT=""

OLD_IFS="$IFS"
IFS='&'
for pair in $BODY; do
  k="${pair%%=*}"
  v="${pair#*=}"
  k="$(urldecode "$k")"
  v="$(urldecode "$v")"
  [ "$k" = "event" ] && EVENT="$v"
done
IFS="$OLD_IFS"

case "$EVENT" in
  UP|UP_RESET|DOWN|DOWN_RESET|VOLUME_UP_CLICK|VOLUME_UP_DOUBLE|VOLUME_UP_LONG|VOLUME_DOWN_CLICK|VOLUME_DOWN_DOUBLE|VOLUME_DOWN_LONG|VOLUME_BOTH_CLICK)
    run_action_event "$EVENT"
    MSG="已执行 $EVENT"
    ;;
  *)
    MSG="无效事件"
    ;;
esac

print_json_header
echo "{\"ok\":true,\"message\":\"$MSG\"}"
EOF

  cat > "$API_DIR/test_action_draft" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

BODY="$(read_body)"
EVENT=""
TYPE=""
ARG=""
SHELL_CONTENT=""

OLD_IFS="$IFS"
IFS='&'
for pair in $BODY; do
  k="${pair%%=*}"
  v="${pair#*=}"
  k="$(urldecode "$k")"
  v="$(urldecode "$v")"

  case "$k" in
    event) EVENT="$v" ;;
    type) TYPE="$v" ;;
    arg) ARG="$v" ;;
    shell) SHELL_CONTENT="$v" ;;
  esac
done
IFS="$OLD_IFS"

case "$EVENT" in
  UP|UP_RESET|DOWN|DOWN_RESET|VOLUME_UP_CLICK|VOLUME_UP_DOUBLE|VOLUME_UP_LONG|VOLUME_DOWN_CLICK|VOLUME_DOWN_DOUBLE|VOLUME_DOWN_LONG|VOLUME_BOTH_CLICK)
    run_action_draft "$EVENT" "$TYPE" "$ARG" "$SHELL_CONTENT"
    MSG="已测试 $EVENT（未保存）"
    ;;
  *)
    MSG="无效事件"
    ;;
esac

print_json_header
echo "{\"ok\":true,\"message\":\"$MSG\"}"
EOF

  cat > "$API_DIR/apps" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

print_json_header

TMP="$PID_DIR/apps.json.tmp"
: > "$TMP"

first=1

pm list packages 2>/dev/null | bb sed 's/^package://' | while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue

  epkg="$(printf '%s' "$pkg" | json_escape)"

  if [ "$first" = "1" ]; then
    first=0
  else
    printf ',' >> "$TMP"
  fi

  printf '{"name":"%s","package":"%s"}' "$epkg" "$epkg" >> "$TMP"
done

printf '{"ok":true,"apps":[%s]}\n' "$(cat "$TMP" 2>/dev/null)"
rm -f "$TMP"
EOF

  cat > "$API_DIR/module_info" <<'EOF'
#!/system/bin/sh
. /data/adb/SideKeyPlus/www/cgi-bin/api/common.sh

MODDIR="/data/adb/modules/SideKeyPlus"
PROP="$MODDIR/module.prop"

print_json_header

id=""
name=""
version=""
versionCode=""
author=""
description=""

if [ -f "$PROP" ]; then
  id="$(bb grep -E '^id=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
  name="$(bb grep -E '^name=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
  version="$(bb grep -E '^version=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
  versionCode="$(bb grep -E '^versionCode=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
  author="$(bb grep -E '^author=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
  description="$(bb grep -E '^description=' "$PROP" 2>/dev/null | bb head -n 1 | bb sed 's/^[^=]*=//' | bb sed 's/\r$//')"
fi

cfg_coolapk="$(config_get COOLAPK)"
cfg_qq_group="$(config_get QQ_GROUP)"
cfg_qq_group_link="$(config_get QQ_GROUP_LINK)"

esc() {
  printf '%s' "$1" | json_escape
}

echo "{"
printf '"ok":true,'
printf '"id":"%s",' "$(esc "$id")"
printf '"name":"%s",' "$(esc "$name")"
printf '"version":"%s",' "$(esc "$version")"
printf '"versionCode":"%s",' "$(esc "$versionCode")"
printf '"author":"%s",' "$(esc "$author")"
printf '"description":"%s",' "$(esc "$description")"
printf '"coolapk":"%s",' "$(esc "$cfg_coolapk")"
printf '"qq_group":"%s",' "$(esc "$cfg_qq_group")"
printf '"qq_group_link":"%s"' "$(esc "$cfg_qq_group_link")"
echo "}"
EOF

  chmod 0755 "$API_DIR"/*
}

backend_loop() {
  logi "后端线程启动"

  BACKEND_CONFIG_SIG=""
  BACKEND_ENABLED="false"
  BACKEND_ENABLED_OK=false
  BACKEND_NS="global"
  BACKEND_KEY="alert_slider_mode"
  BACKEND_VUP=1
  BACKEND_VMID=2
  BACKEND_VDOWN=3
  BACKEND_INTERVAL=0.5
  BACKEND_UP_TYPE=0
  BACKEND_UP_RESET_TYPE=0
  BACKEND_DOWN_TYPE=0
  BACKEND_DOWN_RESET_TYPE=0

  backend_refresh_config() {
    sig="$(bb stat -c '%Y:%s' "$CONFIG_PATH" 2>/dev/null)"
    [ -n "$sig" ] || sig=missing
    [ "$sig" = "$BACKEND_CONFIG_SIG" ] && return 0
    BACKEND_CONFIG_SIG="$sig"

    BACKEND_ENABLED="$(config_get BACKEND_ENABLE)"
    if config_bool "$BACKEND_ENABLED"; then
      BACKEND_ENABLED_OK=true
    else
      BACKEND_ENABLED_OK=false
    fi
    BACKEND_NS="$(config_get SLIDER_SETTINGS_NS)"
    BACKEND_KEY="$(config_get SLIDER_SETTINGS_KEY)"
    BACKEND_VUP="$(config_get VALUE_UP)"
    BACKEND_VMID="$(config_get VALUE_MID)"
    BACKEND_VDOWN="$(config_get VALUE_DOWN)"
    BACKEND_INTERVAL="$(config_get POLL_INTERVAL)"
    BACKEND_UP_TYPE="$(config_get ACTION_UP_TYPE)"
    BACKEND_UP_RESET_TYPE="$(config_get ACTION_UP_RESET_TYPE)"
    BACKEND_DOWN_TYPE="$(config_get ACTION_DOWN_TYPE)"
    BACKEND_DOWN_RESET_TYPE="$(config_get ACTION_DOWN_RESET_TYPE)"

    [ -n "$BACKEND_NS" ] || BACKEND_NS=global
    [ -n "$BACKEND_KEY" ] || BACKEND_KEY=alert_slider_mode
    [ -n "$BACKEND_VUP" ] || BACKEND_VUP=1
    [ -n "$BACKEND_VMID" ] || BACKEND_VMID=2
    [ -n "$BACKEND_VDOWN" ] || BACKEND_VDOWN=3
    [ -n "$BACKEND_INTERVAL" ] || BACKEND_INTERVAL=0.5

    case "$BACKEND_INTERVAL" in
      ''|*[!0-9.]*|0|0.0|0.00) BACKEND_INTERVAL=0.5 ;;
    esac
  }

  backend_has_actions() {
    [ "${BACKEND_UP_TYPE:-0}" != "0" ] ||
      [ "${BACKEND_UP_RESET_TYPE:-0}" != "0" ] ||
      [ "${BACKEND_DOWN_TYPE:-0}" != "0" ] ||
      [ "${BACKEND_DOWN_RESET_TYPE:-0}" != "0" ]
  }

  backend_read_slider_value() {
    v="$(settings get "$BACKEND_NS" "$BACKEND_KEY" 2>/dev/null)"
    case "$v" in
      ''|null|*Failure*|*Broken*|*Exception*|*cmd:*) echo '' ;;
      *) echo "$v" ;;
    esac
  }

  backend_valid_slider_value() {
    [ "$1" = "$BACKEND_VUP" ] || [ "$1" = "$BACKEND_VMID" ] || [ "$1" = "$BACKEND_VDOWN" ]
  }

  backend_refresh_config
  if [ "$BACKEND_ENABLED_OK" != "true" ]; then
    logw "BACKEND_ENABLE 未开启，后端退出"
    return
  fi
  if ! backend_has_actions; then
    logi "未配置三段键动作，后端不启动以降低耗电"
    return
  fi

  LAST=""
  i=0

  while [ "$i" -lt 20 ]; do
    LAST="$(backend_read_slider_value)"
    if backend_valid_slider_value "$LAST"; then
      break
    fi
    bb sleep 1
    i=$((i + 1))
  done

  if ! backend_valid_slider_value "$LAST"; then
    logw "初始三段键值无效：$LAST，默认按中间处理"
    LAST="$BACKEND_VMID"
  fi

  echo "[$(now)] BACKEND_INIT LAST=$LAST" >> "$BACKEND_LOG"

  while true; do
    backend_refresh_config
    if [ "$BACKEND_ENABLED_OK" != "true" ]; then
      logi "检测到 BACKEND_ENABLE=false，后端退出"
      break
    fi
    if ! backend_has_actions; then
      logi "三段键动作已全部清空，后端退出"
      break
    fi

    VUP="$BACKEND_VUP"
    VMID="$BACKEND_VMID"
    VDOWN="$BACKEND_VDOWN"
    INTERVAL="$BACKEND_INTERVAL"

    CUR="$(backend_read_slider_value)"

    if ! backend_valid_slider_value "$CUR"; then
      bb sleep "$INTERVAL"
      continue
    fi

    if [ "$CUR" != "$LAST" ]; then
      EVENT=""

      if [ "$LAST" = "$VMID" ] && [ "$CUR" = "$VUP" ]; then
        EVENT="UP"
      elif [ "$LAST" = "$VUP" ] && [ "$CUR" = "$VMID" ]; then
        EVENT="UP_RESET"
      elif [ "$LAST" = "$VMID" ] && [ "$CUR" = "$VDOWN" ]; then
        EVENT="DOWN"
      elif [ "$LAST" = "$VDOWN" ] && [ "$CUR" = "$VMID" ]; then
        EVENT="DOWN_RESET"
      fi

      echo "[$(now)] LAST=$LAST CUR=$CUR EVENT=$EVENT" >> "$BACKEND_LOG"

      if [ -n "$EVENT" ]; then
        run_action_event "$EVENT"
      fi

      LAST="$CUR"
    fi

    bb sleep "$INTERVAL"
  done
}

stop_backend_only_proc() {
  PID="$(cat "$PID_DIR/backend.pid" 2>/dev/null)"

  if is_pid_alive "$PID"; then
    kill "$PID" 2>/dev/null
    bb sleep 0.2
    kill -9 "$PID" 2>/dev/null
  fi

  kill_by_cmd_match "$MODDIR/service.sh" "start_backend_only" ""
  kill_by_cmd_match "backend_loop" "SideKeyPlus" ""

  rm -f "$PID_DIR/backend.pid"
}

stop_keyd() {
  PID="$(cat "$PID_DIR/keyd.pid" 2>/dev/null)"

  if is_pid_alive "$PID"; then
    kill "$PID" 2>/dev/null
    bb sleep 0.2
    kill -9 "$PID" 2>/dev/null
  fi

  kill_by_cmd_match "$MODDIR/bin/skp-keyd" "" ""

  rm -f "$PID_DIR/keyd.pid"
}

start_keyd() {
  if ! config_bool "$(config_get VOLUME_KEY_ENABLE)"; then
    logw "VOLUME_KEY_ENABLE 未开启，不启动 keyd"
    stop_keyd
    return
  fi

  KEYD_BIN="$MODDIR/bin/skp-keyd"

  if [ ! -x "$KEYD_BIN" ]; then
    logw "skp-keyd 不存在或不可执行：$KEYD_BIN"
    return
  fi

  ensure_run_action_file

  OLD_PID="$(cat "$PID_DIR/keyd.pid" 2>/dev/null)"

  if is_pid_alive "$OLD_PID"; then
    cmd="$(cmdline_of_pid "$OLD_PID")"
    case "$cmd" in
      *"$KEYD_BIN"*)
        logi "keyd 已运行 PID=$OLD_PID，跳过"
        return
        ;;
      *)
        logw "keyd.pid 存在但进程不匹配，准备清理后重启 PID=$OLD_PID CMD=$cmd"
        ;;
    esac
  fi

  stop_keyd
  rm -f "$PID_DIR/keyd.pid"

  "$KEYD_BIN" >> "$KEYD_LOG" 2>&1 &
  NEW_PID="$!"
  echo "$NEW_PID" > "$PID_DIR/keyd.pid"

  bb sleep 0.2

  if is_pid_alive "$NEW_PID"; then
    logi "keyd 已启动 PID=$NEW_PID"
  else
    loge "keyd 启动失败"
    rm -f "$PID_DIR/keyd.pid"
  fi
}

start_backend() {
  if ! config_bool "$(config_get BACKEND_ENABLE)"; then
    logw "BACKEND_ENABLE 未开启，不启动后端"
    stop_backend_only_proc
    return
  fi

  if [ "$(config_get ACTION_UP_TYPE)$(config_get ACTION_UP_RESET_TYPE)$(config_get ACTION_DOWN_TYPE)$(config_get ACTION_DOWN_RESET_TYPE)" = "0000" ]; then
    logi "未配置三段键动作，不启动后端"
    stop_backend_only_proc
    return
  fi

  OLD_PID="$(cat "$PID_DIR/backend.pid" 2>/dev/null)"

  if is_pid_alive "$OLD_PID"; then
    cmd="$(cmdline_of_pid "$OLD_PID")"
    case "$cmd" in
      *"service.sh"*|*"sh"*)
        logi "后端已运行 PID=$OLD_PID，跳过"
        ;;
      *)
        logw "backend.pid 存在但进程不匹配，准备清理后重启 PID=$OLD_PID CMD=$cmd"
        stop_backend_only_proc
        backend_loop >> "$BACKEND_LOG" 2>&1 &
        echo "$!" > "$PID_DIR/backend.pid"
        logi "后端已启动 PID=$!"
        ;;
    esac
  else
    stop_backend_only_proc
    backend_loop >> "$BACKEND_LOG" 2>&1 &
    echo "$!" > "$PID_DIR/backend.pid"
    logi "后端已启动 PID=$!"
  fi
}

start_httpd() {
  OLD_PID="$(cat "$PID_DIR/httpd.pid" 2>/dev/null)"

  if is_pid_alive "$OLD_PID"; then
    cmd="$(cmdline_of_pid "$OLD_PID")"
    case "$cmd" in
      *"httpd -f -p 127.0.0.1:$WEB_PORT"*|*"httpd -f -p :$WEB_PORT"*)
        logi "httpd 已运行 PID=$OLD_PID，跳过"
        return
        ;;
      *)
        logw "httpd.pid 存在但进程不匹配，准备清理后重启 PID=$OLD_PID CMD=$cmd"
        ;;
    esac
  fi

  kill_by_cmd_match "httpd -f -p 127.0.0.1:$WEB_PORT" "$WWW_DIR" ""
  rm -f "$PID_DIR/httpd.pid"

  write_webui
  write_api_scripts
  ensure_run_action_file

  (
    cd "$WWW_DIR" 2>/dev/null || cd /data/adb 2>/dev/null || cd / 2>/dev/null
    "$BB" httpd -f -p "127.0.0.1:$WEB_PORT" -h "$WWW_DIR"
  ) >> "$HTTPD_LOG" 2>&1 &
  HPID="$!"

  bb sleep 0.5

  if is_pid_alive "$HPID"; then
    echo "$HPID" > "$PID_DIR/httpd.pid"
    logi "httpd 已启动 PID=$HPID PORT=$WEB_PORT"
  else
    loge "httpd 启动失败，可能端口 $WEB_PORT 已被占用"
  fi
}

case "$1" in
  start_backend_only)
    service_lock
    start_backend
    service_unlock
    exit 0
    ;;
  stop_backend_only)
    service_lock
    stop_backend_only_proc
    service_unlock
    exit 0
    ;;
  start_keyd_only)
    service_lock
    start_keyd
    service_unlock
    exit 0
    ;;
  stop_keyd_only)
    service_lock
    stop_keyd
    service_unlock
    exit 0
    ;;
  start_httpd_only)
    service_lock
    start_httpd
    service_unlock
    exit 0
    ;;
esac

service_lock

logi "===== SideKey+ service.sh 启动 ====="
logi "SKP_DIR=$SKP_DIR"
logi "CONFIG_PATH=$CONFIG_PATH"
logi "BUSYBOX=$BB"
logi "WEB_PORT=$WEB_PORT"
logi "WEBROOT_TEMPLATE=$WEBROOT_TEMPLATE"
logi "WEBROOT_INDEX=$WEBROOT_INDEX"

wait_boot_completed_if_needed

start_httpd

if config_bool "$(config_get BACKEND_ENABLE)"; then
  start_backend
else
  stop_backend_only_proc
fi

if config_bool "$(config_get VOLUME_KEY_ENABLE)"; then
  start_keyd
else
  stop_keyd
fi

logi "===== SideKey+ 初始化完成 ====="

service_unlock

exit 0
