SKIPUNZIP=0

SKP_DIR="/data/adb/SideKeyPlus"
CONFIG_PATH="$SKP_DIR/config.ini"
MODDIR="/data/adb/modules/SideKeyPlus"

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

detect_root_type() {
  case "$(su -v 2>/dev/null | awk -F : '{print $2}')" in
    MAGISKSU) echo MagiskSU ;;
    KernelSU) echo KernelSU ;;
    *) echo APatch ;;
  esac
}

BUSYBOX_PATH="$(detect_busybox)"
ROOT_TYPE="$(detect_root_type)"

ui_print "- 安装 SideKey+"
ui_print "- Root: $ROOT_TYPE"
ui_print "- BusyBox: $BUSYBOX_PATH"

bb() {
  "$BUSYBOX_PATH" "$@"
}

is_alive() {
  pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

kill_pid_file() {
  f="$1"

  if [ -f "$f" ]; then
    pid="$(cat "$f" 2>/dev/null)"

    if is_alive "$pid"; then
      ui_print "- 停止旧进程: $f PID=$pid"
      kill "$pid" 2>/dev/null
      bb sleep 0.3
      kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$f"
  fi
}

stop_old_service() {
  ui_print "- 检查并停止旧服务"

  if [ -f "$SKP_DIR/stop.sh" ]; then
    /system/bin/sh "$SKP_DIR/stop.sh" >/dev/null 2>&1
    bb sleep 0.3
  fi

  kill_pid_file "$SKP_DIR/pid/backend.pid"
  kill_pid_file "$SKP_DIR/pid/httpd.pid"
  kill_pid_file "$SKP_DIR/pid/keyd.pid"

  rm -f "$SKP_DIR/pid/service.lock"

  OLD_PORT="$(bb grep -E '^WEB_PORT=' "$CONFIG_PATH" 2>/dev/null | bb tail -n 1 | bb sed 's/^[^=]*=//')"
  [ -z "$OLD_PORT" ] && OLD_PORT=8777

  for p in $(bb pidof httpd 2>/dev/null); do
    cmdline="$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null)"
    case "$cmdline" in
      *"127.0.0.1:$OLD_PORT"*|*":$OLD_PORT"*)
        ui_print "- 兜底停止旧 httpd PID=$p PORT=$OLD_PORT"
        kill "$p" 2>/dev/null
        bb sleep 0.2
        kill -9 "$p" 2>/dev/null
        ;;
    esac
  done
}

validate_package_files() {
  miss=0

  for f in \
    "$MODPATH/common.sh" \
    "$MODPATH/cgi.sh" \
    "$MODPATH/service.sh" \
    "$MODPATH/action.sh" \
    "$MODPATH/run_action.sh" \
    "$MODPATH/stop.sh" \
    "$MODPATH/uninstall.sh"
  do
    if [ ! -f "$f" ]; then
      ui_print "! 缺少文件: ${f#$MODPATH/}"
      miss=1
    fi
  done

  if [ ! -f "$MODPATH/bin/skp-keyd" ]; then
    ui_print "! 缺少文件: bin/skp-keyd"
    ui_print "! 音量键功能将不可用"
  fi

  if [ ! -f "$MODPATH/bin/torchctl.dex.jar" ]; then
    ui_print "! 缺少文件: bin/torchctl.dex.jar"
    ui_print "! 手电筒功能将不可用"
  fi

  if [ ! -f "$MODPATH/webroot/webui/index.html.tpl" ] && [ ! -f "$MODPATH/webroot/webui/index.html" ]; then
    ui_print "! 缺少 WebUI 模板: webroot/webui/index.html.tpl"
    ui_print "! 安装后将使用降级占位页面"
  fi

  [ "$miss" = "0" ]
}

old_config_get() {
  KEY="$1"
  [ -f "$CONFIG_PATH" ] || return
  bb grep -E "^$KEY=" "$CONFIG_PATH" 2>/dev/null | bb tail -n 1 | bb sed 's/^[^=]*=//'
}

default_or_old() {
  KEY="$1"
  DEF="$2"
  OLD="$(old_config_get "$KEY")"

  if [ -n "$OLD" ]; then
    printf '%s' "$OLD"
  else
    printf '%s' "$DEF"
  fi
}

rewrite_config_keep_old() {
  TMP="$SKP_DIR/config.new"

  cat > "$TMP" <<EOF
# SideKey+ 配置文件
# 数据目录：/data/adb/SideKeyPlus

BUSYBOX_PATH=$BUSYBOX_PATH
ROOT_TYPE=$ROOT_TYPE

WEB_PORT=$(default_or_old WEB_PORT 8777)

BACKEND_ENABLE=$(default_or_old BACKEND_ENABLE true)

SLIDER_SETTINGS_NS=$(default_or_old SLIDER_SETTINGS_NS global)
SLIDER_SETTINGS_KEY=$(default_or_old SLIDER_SETTINGS_KEY alert_slider_mode)

VALUE_UP=$(default_or_old VALUE_UP 1)
VALUE_MID=$(default_or_old VALUE_MID 2)
VALUE_DOWN=$(default_or_old VALUE_DOWN 3)

POLL_INTERVAL=$(default_or_old POLL_INTERVAL 0.25)

VOLUME_KEY_ENABLE=$(default_or_old VOLUME_KEY_ENABLE false)
BLOCK_VOLUME_KEY=$(default_or_old BLOCK_VOLUME_KEY false)

ACTION_UP_TYPE=$(default_or_old ACTION_UP_TYPE 0)
ACTION_UP_ARG=$(default_or_old ACTION_UP_ARG "")

ACTION_UP_RESET_TYPE=$(default_or_old ACTION_UP_RESET_TYPE 0)
ACTION_UP_RESET_ARG=$(default_or_old ACTION_UP_RESET_ARG "")

ACTION_DOWN_TYPE=$(default_or_old ACTION_DOWN_TYPE 0)
ACTION_DOWN_ARG=$(default_or_old ACTION_DOWN_ARG "")

ACTION_DOWN_RESET_TYPE=$(default_or_old ACTION_DOWN_RESET_TYPE 0)
ACTION_DOWN_RESET_ARG=$(default_or_old ACTION_DOWN_RESET_ARG "")

ACTION_VOLUME_UP_CLICK_TYPE=$(default_or_old ACTION_VOLUME_UP_CLICK_TYPE 0)
ACTION_VOLUME_UP_CLICK_ARG=$(default_or_old ACTION_VOLUME_UP_CLICK_ARG "")

ACTION_VOLUME_UP_DOUBLE_TYPE=$(default_or_old ACTION_VOLUME_UP_DOUBLE_TYPE 0)
ACTION_VOLUME_UP_DOUBLE_ARG=$(default_or_old ACTION_VOLUME_UP_DOUBLE_ARG "")

ACTION_VOLUME_UP_LONG_TYPE=$(default_or_old ACTION_VOLUME_UP_LONG_TYPE 0)
ACTION_VOLUME_UP_LONG_ARG=$(default_or_old ACTION_VOLUME_UP_LONG_ARG "")

ACTION_VOLUME_DOWN_CLICK_TYPE=$(default_or_old ACTION_VOLUME_DOWN_CLICK_TYPE 0)
ACTION_VOLUME_DOWN_CLICK_ARG=$(default_or_old ACTION_VOLUME_DOWN_CLICK_ARG "")

ACTION_VOLUME_DOWN_DOUBLE_TYPE=$(default_or_old ACTION_VOLUME_DOWN_DOUBLE_TYPE 0)
ACTION_VOLUME_DOWN_DOUBLE_ARG=$(default_or_old ACTION_VOLUME_DOWN_DOUBLE_ARG "")

ACTION_VOLUME_DOWN_LONG_TYPE=$(default_or_old ACTION_VOLUME_DOWN_LONG_TYPE 0)
ACTION_VOLUME_DOWN_LONG_ARG=$(default_or_old ACTION_VOLUME_DOWN_LONG_ARG "")

ACTION_VOLUME_BOTH_CLICK_TYPE=$(default_or_old ACTION_VOLUME_BOTH_CLICK_TYPE 0)
ACTION_VOLUME_BOTH_CLICK_ARG=$(default_or_old ACTION_VOLUME_BOTH_CLICK_ARG "")

DEFAULT_PACKAGE=$(default_or_old DEFAULT_PACKAGE com.tencent.mm)
DEFAULT_URL=$(default_or_old DEFAULT_URL https://www.coolapk.com/u/31750950)

WECHAT_SCAN_COMPONENT=$(default_or_old WECHAT_SCAN_COMPONENT "com.tencent.mm/.plugin.scanner.ui.BaseScanUI")
WECHAT_PAY_COMPONENT=$(default_or_old WECHAT_PAY_COMPONENT "com.tencent.mm/com.tencent.mm.plugin.offline.ui.WalletOfflineCoinPurseUI")

ALIPAY_SCAN_COMPONENT=$(default_or_old ALIPAY_SCAN_COMPONENT "")
ALIPAY_PAY_COMPONENT=$(default_or_old ALIPAY_PAY_COMPONENT "")
ALIPAY_SCAN_URI=$(default_or_old ALIPAY_SCAN_URI "alipayqr://platformapi/startapp?saId=10000007")
ALIPAY_PAY_URI=$(default_or_old ALIPAY_PAY_URI "alipays://platformapi/startapp?appId=20000056")

AUTHOR=$(default_or_old AUTHOR "余生只有凄渺")
COOLAPK=$(default_or_old COOLAPK "https://www.coolapk.com/u/31750950")
QQ_GROUP=$(default_or_old QQ_GROUP 923184177)
QQ_GROUP_LINK=$(default_or_old QQ_GROUP_LINK "")
EOF

  mv -f "$TMP" "$CONFIG_PATH"
}

ensure_default_shell_files() {
  for e in \
    UP UP_RESET DOWN DOWN_RESET \
    VOLUME_UP_CLICK VOLUME_UP_DOUBLE VOLUME_UP_LONG \
    VOLUME_DOWN_CLICK VOLUME_DOWN_DOUBLE VOLUME_DOWN_LONG \
    VOLUME_BOTH_CLICK
  do
    f="$SKP_DIR/actions/${e}.custom.sh"
    if [ ! -f "$f" ]; then
      cat > "$f" <<'EOF'
#!/system/bin/sh
# 在这里写自定义 shell
EOF
      chmod 0755 "$f"
    fi
  done
}

copy_module_files() {
  mkdir -p "$MODDIR" "$MODDIR/bin" "$MODDIR/webroot"

  cp -f "$MODPATH/common.sh" "$MODDIR/common.sh"
  cp -f "$MODPATH/cgi.sh" "$MODDIR/cgi.sh"
  cp -f "$MODPATH/service.sh" "$MODDIR/service.sh"
  cp -f "$MODPATH/action.sh" "$MODDIR/action.sh"
  cp -f "$MODPATH/run_action.sh" "$MODDIR/run_action.sh" 2>/dev/null
  cp -f "$MODPATH/uninstall.sh" "$MODDIR/uninstall.sh" 2>/dev/null

  cp -f "$MODPATH/stop.sh" "$SKP_DIR/stop.sh" 2>/dev/null

  if [ -f "$MODPATH/bin/skp-keyd" ]; then
    cp -f "$MODPATH/bin/skp-keyd" "$MODDIR/bin/skp-keyd" 2>/dev/null
  fi

  if [ -f "$MODPATH/bin/torchctl.dex.jar" ]; then
    cp -f "$MODPATH/bin/torchctl.dex.jar" "$MODDIR/bin/torchctl.dex.jar" 2>/dev/null
  fi

  if [ -d "$MODPATH/webroot" ]; then
    rm -rf "$MODDIR/webroot"
    mkdir -p "$MODDIR/webroot"
    cp -rf "$MODPATH/webroot/"* "$MODDIR/webroot/" 2>/dev/null
  fi
}

set_module_perms() {
  chmod 0755 "$MODDIR/common.sh" 2>/dev/null
  chmod 0755 "$MODDIR/cgi.sh" 2>/dev/null
  chmod 0755 "$MODDIR/service.sh" 2>/dev/null
  chmod 0755 "$MODDIR/action.sh" 2>/dev/null
  chmod 0755 "$MODDIR/run_action.sh" 2>/dev/null
  chmod 0755 "$MODDIR/uninstall.sh" 2>/dev/null
  chmod 0755 "$MODDIR/bin/skp-keyd" 2>/dev/null
  chmod 0644 "$MODDIR/bin/torchctl.dex.jar" 2>/dev/null
  chmod 0755 "$MODDIR/webroot" 2>/dev/null
  chmod 0644 "$MODDIR/webroot/webui/index.html.tpl" 2>/dev/null
  chmod 0644 "$MODDIR/webroot/webui/index.html" 2>/dev/null
  chmod 0755 "$SKP_DIR/stop.sh" 2>/dev/null
}

start_new_service() {
  ui_print "- 启动新服务"
  bb sh "$MODDIR/service.sh" >/dev/null 2>&1 &
}

print_summary() {
  PORT="$(bb grep -E '^WEB_PORT=' "$CONFIG_PATH" 2>/dev/null | bb tail -n 1 | bb sed 's/^[^=]*=//')"
  [ -z "$PORT" ] && PORT=8777

  ui_print "- 配置目录: $SKP_DIR"
  ui_print "- Web 面板: http://127.0.0.1:$PORT/webui/"

  if [ -x "$MODDIR/bin/skp-keyd" ]; then
    ui_print "- skp-keyd: 已安装"
  else
    ui_print "- skp-keyd: 未找到，音量键功能不可用"
  fi

  if [ -f "$MODDIR/bin/torchctl.dex.jar" ]; then
    ui_print "- TorchCtl: 已安装"
  else
    ui_print "- TorchCtl: 未找到，手电筒功能不可用"
  fi

  if [ -f "$MODDIR/common.sh" ] && [ -f "$MODDIR/cgi.sh" ]; then
    ui_print "- 公共库: common.sh + cgi.sh"
  fi

  ui_print "- 安装完成"
}

stop_old_service

mkdir -p "$SKP_DIR" \
         "$SKP_DIR/actions" \
         "$SKP_DIR/www" \
         "$SKP_DIR/www/cgi-bin" \
         "$SKP_DIR/www/cgi-bin/api" \
         "$SKP_DIR/log" \
         "$SKP_DIR/pid"

set_perm_recursive "$MODPATH" 0 0 0755 0644

chmod 0755 "$MODPATH/common.sh" 2>/dev/null
chmod 0755 "$MODPATH/cgi.sh" 2>/dev/null
chmod 0755 "$MODPATH/service.sh" 2>/dev/null
chmod 0755 "$MODPATH/action.sh" 2>/dev/null
chmod 0755 "$MODPATH/run_action.sh" 2>/dev/null
chmod 0755 "$MODPATH/stop.sh" 2>/dev/null
chmod 0755 "$MODPATH/uninstall.sh" 2>/dev/null
chmod 0755 "$MODPATH/bin/skp-keyd" 2>/dev/null
chmod 0644 "$MODPATH/bin/torchctl.dex.jar" 2>/dev/null

if ! validate_package_files; then
  abort "! 安装包文件不完整，已终止安装"
fi

rewrite_config_keep_old
ensure_default_shell_files

if [ -f "$SKP_DIR/stop.sh" ]; then
  bb sh "$SKP_DIR/stop.sh" 2>/dev/null
fi

copy_module_files
set_module_perms
start_new_service
print_summary