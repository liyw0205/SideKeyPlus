#!/system/bin/sh

SKP_DIR="${SKP_DIR:-/data/adb/SideKeyPlus}"
MODDIR="${MODDIR:-/data/adb/modules/SideKeyPlus}"
CONFIG_PATH="${CONFIG_PATH:-$SKP_DIR/config.ini}"

WWW_DIR="${WWW_DIR:-$SKP_DIR/www}"
WEB_DIR="${WEB_DIR:-$WWW_DIR/webui}"
CGI_DIR="${CGI_DIR:-$WWW_DIR/cgi-bin}"
API_DIR="${API_DIR:-$CGI_DIR/api}"

WEBROOT_WEB="${WEBROOT_WEB:-$MODDIR/webroot}"
WEBROOT_WEB_DIR="${WEBROOT_WEB_DIR:-$WEBROOT_WEB/webui}"
WEBROOT_TEMPLATE="${WEBROOT_TEMPLATE:-$WEBROOT_WEB_DIR/index.html.tpl}"
WEBROOT_INDEX="${WEBROOT_INDEX:-$WEBROOT_WEB_DIR/index.html}"

ACTION_DIR="${ACTION_DIR:-$SKP_DIR/actions}"
LOG_DIR="${LOG_DIR:-$SKP_DIR/log}"
PID_DIR="${PID_DIR:-$SKP_DIR/pid}"

SERVICE_LOG="${SERVICE_LOG:-$LOG_DIR/service.log}"
BACKEND_LOG="${BACKEND_LOG:-$LOG_DIR/backend.log}"
HTTPD_LOG="${HTTPD_LOG:-$LOG_DIR/httpd.log}"
KEYD_LOG="${KEYD_LOG:-$LOG_DIR/keyd.log}"

LOCK_FILE="${LOCK_FILE:-$PID_DIR/service.lock}"

detect_busybox() {
  if [ -f "$CONFIG_PATH" ]; then
    p="$(/system/bin/toybox grep -E '^BUSYBOX_PATH=' "$CONFIG_PATH" 2>/dev/null | /system/bin/toybox tail -n 1 2>/dev/null | /system/bin/toybox sed 's/^[^=]*=//' 2>/dev/null)"
    [ -n "$p" ] && [ -x "$p" ] && echo "$p" && return
  fi

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

BB="${BB:-$(detect_busybox)}"

bb() {
  "$BB" "$@"
}

ensure_path_env() {
  export PATH="$(bb dirname "$BB" 2>/dev/null):/data/adb/ksu/bin:/data/adb/magisk:/data/adb/ap/bin:/system/bin:/system/xbin:/vendor/bin:/odm/bin:$PATH"
}

now() {
  bb date '+%F %T'
}

logi() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  echo "[$(now)] [service] $*" | tee -a "$SERVICE_LOG"
}

logw() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  echo "[$(now)] [service] 警告: $*" | tee -a "$SERVICE_LOG"
}

loge() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  echo "[$(now)] [service] 错误: $*" | tee -a "$SERVICE_LOG"
}

config_get() {
  KEY="$1"
  [ -f "$CONFIG_PATH" ] || return
  bb grep -E "^$KEY=" "$CONFIG_PATH" 2>/dev/null | bb tail -n 1 | bb sed 's/^[^=]*=//'
}

config_apply_updates() {
  UPDATES_FILE="$1"
  [ -n "$UPDATES_FILE" ] || return 1
  [ -f "$UPDATES_FILE" ] || return 0

  TMP_CFG="$CONFIG_PATH.tmp.$$"
  TMP_UPD="$PID_DIR/config_updates.norm.$$"

  mkdir -p "$PID_DIR" 2>/dev/null
  [ -f "$CONFIG_PATH" ] || : > "$CONFIG_PATH"

  bb awk -F= '
    {
      key=$1
      sub(/^[^=]*=/,"",$0)
      val=$0

      if (!(key in seen)) {
        order[++n]=key
        seen[key]=1
      }
      upd[key]=val
    }
    END {
      for (i=1;i<=n;i++) {
        k=order[i]
        print k "=" upd[k]
      }
    }
  ' "$UPDATES_FILE" > "$TMP_UPD" || return 1

  bb awk -F= '
    NR==FNR {
      key=$1
      sub(/^[^=]*=/,"",$0)
      upd[key]=$0
      order[++n]=key
      next
    }

    /^[[:space:]]*#/ || /^[[:space:]]*$/ {
      print
      next
    }

    {
      key=$1
      if (key in upd) {
        print key "=" upd[key]
        used[key]=1
      } else {
        print
      }
    }

    END {
      for (i=1;i<=n;i++) {
        k=order[i]
        if (!(k in used)) {
          print k "=" upd[k]
          used[k]=1
        }
      }
    }
  ' "$TMP_UPD" "$CONFIG_PATH" > "$TMP_CFG" || {
    rm -f "$TMP_CFG" "$TMP_UPD"
    return 1
  }

  mv -f "$TMP_CFG" "$CONFIG_PATH" || {
    rm -f "$TMP_CFG" "$TMP_UPD"
    return 1
  }

  rm -f "$TMP_UPD"
  return 0
}

config_set() {
  KEY="$1"
  VAL="$2"
  TMP_UPDATES="$PID_DIR/config_single.$$"

  mkdir -p "$PID_DIR" 2>/dev/null
  printf '%s=%s\n' "$KEY" "$VAL" > "$TMP_UPDATES"
  config_apply_updates "$TMP_UPDATES"
  RET=$?
  rm -f "$TMP_UPDATES"
  return $RET
}

config_set_multi() {
  TMP_UPDATES="$PID_DIR/config_multi.$$"

  mkdir -p "$PID_DIR" 2>/dev/null
  : > "$TMP_UPDATES"

  while [ "$#" -ge 2 ]; do
    KEY="$1"
    VAL="$2"
    printf '%s=%s\n' "$KEY" "$VAL" >> "$TMP_UPDATES"
    shift 2
  done

  config_apply_updates "$TMP_UPDATES"
  RET=$?
  rm -f "$TMP_UPDATES"
  return $RET
}

is_pid_alive() {
  pid="$1"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

service_lock() {
  mkdir -p "$PID_DIR" 2>/dev/null
  old="$(cat "$LOCK_FILE" 2>/dev/null)"
  if is_pid_alive "$old"; then
    logw "service.sh 已在运行 PID=$old，本次退出"
    exit 0
  fi
  echo "$$" > "$LOCK_FILE"
}

service_unlock() {
  rm -f "$LOCK_FILE"
}

wait_boot_completed_if_needed() {
  if [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; then
    logi "等待 boot_completed=1"
    while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
      bb sleep 2
    done
    bb sleep 30
  fi
}

read_slider_value() {
  ns="$(config_get SLIDER_SETTINGS_NS)"
  key="$(config_get SLIDER_SETTINGS_KEY)"

  [ -z "$ns" ] && ns=global
  [ -z "$key" ] && key=alert_slider_mode

  v="$(settings get "$ns" "$key" 2>/dev/null)"

  case "$v" in
    ""|null|*Failure*|*Broken*|*Exception*|*cmd:*)
      echo ""
      ;;
    *)
      echo "$v"
      ;;
  esac
}

slider_value() {
  read_slider_value
}

is_valid_slider_value() {
  v="$1"

  vu="$(config_get VALUE_UP)"
  vm="$(config_get VALUE_MID)"
  vd="$(config_get VALUE_DOWN)"

  [ -z "$vu" ] && vu=1
  [ -z "$vm" ] && vm=2
  [ -z "$vd" ] && vd=3

  [ "$v" = "$vu" ] || [ "$v" = "$vm" ] || [ "$v" = "$vd" ]
}

shell_file_by_event() {
  case "$1" in
    UP) echo "$ACTION_DIR/UP.custom.sh" ;;
    UP_RESET) echo "$ACTION_DIR/UP_RESET.custom.sh" ;;
    DOWN) echo "$ACTION_DIR/DOWN.custom.sh" ;;
    DOWN_RESET) echo "$ACTION_DIR/DOWN_RESET.custom.sh" ;;
    VOLUME_UP_CLICK) echo "$ACTION_DIR/VOLUME_UP_CLICK.custom.sh" ;;
    VOLUME_UP_DOUBLE) echo "$ACTION_DIR/VOLUME_UP_DOUBLE.custom.sh" ;;
    VOLUME_UP_LONG) echo "$ACTION_DIR/VOLUME_UP_LONG.custom.sh" ;;
    VOLUME_DOWN_CLICK) echo "$ACTION_DIR/VOLUME_DOWN_CLICK.custom.sh" ;;
    VOLUME_DOWN_DOUBLE) echo "$ACTION_DIR/VOLUME_DOWN_DOUBLE.custom.sh" ;;
    VOLUME_DOWN_LONG) echo "$ACTION_DIR/VOLUME_DOWN_LONG.custom.sh" ;;
    VOLUME_BOTH_CLICK) echo "$ACTION_DIR/VOLUME_BOTH_CLICK.custom.sh" ;;
  esac
}

shell_file_by_key() {
  case "$1" in
    ACTION_UP_SHELL) echo "$ACTION_DIR/UP.custom.sh" ;;
    ACTION_UP_RESET_SHELL) echo "$ACTION_DIR/UP_RESET.custom.sh" ;;
    ACTION_DOWN_SHELL) echo "$ACTION_DIR/DOWN.custom.sh" ;;
    ACTION_DOWN_RESET_SHELL) echo "$ACTION_DIR/DOWN_RESET.custom.sh" ;;
    ACTION_VOLUME_UP_CLICK_SHELL) echo "$ACTION_DIR/VOLUME_UP_CLICK.custom.sh" ;;
    ACTION_VOLUME_UP_DOUBLE_SHELL) echo "$ACTION_DIR/VOLUME_UP_DOUBLE.custom.sh" ;;
    ACTION_VOLUME_UP_LONG_SHELL) echo "$ACTION_DIR/VOLUME_UP_LONG.custom.sh" ;;
    ACTION_VOLUME_DOWN_CLICK_SHELL) echo "$ACTION_DIR/VOLUME_DOWN_CLICK.custom.sh" ;;
    ACTION_VOLUME_DOWN_DOUBLE_SHELL) echo "$ACTION_DIR/VOLUME_DOWN_DOUBLE.custom.sh" ;;
    ACTION_VOLUME_DOWN_LONG_SHELL) echo "$ACTION_DIR/VOLUME_DOWN_LONG.custom.sh" ;;
    ACTION_VOLUME_BOTH_CLICK_SHELL) echo "$ACTION_DIR/VOLUME_BOTH_CLICK.custom.sh" ;;
  esac
}

torchctl_bin() {
  if [ -f "$MODDIR/bin/torchctl.dex.jar" ]; then
    echo "$MODDIR/bin/torchctl.dex.jar"
  elif [ -f "$SKP_DIR/torchctl.dex.jar" ]; then
    echo "$SKP_DIR/torchctl.dex.jar"
  else
    echo ""
  fi
}

torchctl_app_process() {
  if [ -x /system/bin/app_process64 ]; then
    echo /system/bin/app_process64
  elif [ -x /system/bin/app_process32 ]; then
    echo /system/bin/app_process32
  elif [ -x /system/bin/app_process ]; then
    echo /system/bin/app_process
  else
    echo ""
  fi
}

torchctl_run() {
  cmd="$1"
  arg="$2"

  jar="$(torchctl_bin)"
  app_process="$(torchctl_app_process)"

  if [ -z "$jar" ] || [ ! -f "$jar" ]; then
    echo "torchctl jar not found" >> "$LOG_DIR/torchctl.log"
    return 1
  fi

  if [ -z "$app_process" ] || [ ! -x "$app_process" ]; then
    echo "app_process not found" >> "$LOG_DIR/torchctl.log"
    return 1
  fi

  mkdir -p "$LOG_DIR" "$PID_DIR" 2>/dev/null

  if [ -n "$arg" ]; then
    "$app_process" \
      -Djava.class.path="$jar" \
      /system/bin \
      TorchCtl "$cmd" "$arg" >> "$LOG_DIR/torchctl.log" 2>&1
  else
    "$app_process" \
      -Djava.class.path="$jar" \
      /system/bin \
      TorchCtl "$cmd" >> "$LOG_DIR/torchctl.log" 2>&1
  fi
}

flashlight_control() {
  mode="$1"
  [ -z "$mode" ] && mode="toggle"

  mkdir -p "$PID_DIR" "$LOG_DIR" 2>/dev/null

  case "$mode" in
    on)
      if torchctl_run on; then
        echo on > "$PID_DIR/flashlight.state"
      else
        echo "torchctl on failed" >> "$LOG_DIR/torchctl.log"
        return 1
      fi
      ;;

    off)
      if torchctl_run off; then
        echo off > "$PID_DIR/flashlight.state"
      else
        echo "torchctl off failed" >> "$LOG_DIR/torchctl.log"
        return 1
      fi
      ;;

    toggle)
      if torchctl_run toggle; then
        old="$(cat "$PID_DIR/flashlight.state" 2>/dev/null)"
        if [ "$old" = "on" ]; then
          echo off > "$PID_DIR/flashlight.state"
        else
          echo on > "$PID_DIR/flashlight.state"
        fi
      else
        echo "torchctl toggle failed" >> "$LOG_DIR/torchctl.log"
        return 1
      fi
      ;;

    level:*)
      level="${mode#level:}"
      [ -z "$level" ] && level=1

      if torchctl_run level "$level"; then
        echo on > "$PID_DIR/flashlight.state"
      else
        echo "torchctl level $level failed" >> "$LOG_DIR/torchctl.log"
        return 1
      fi
      ;;

    *)
      if torchctl_run toggle; then
        old="$(cat "$PID_DIR/flashlight.state" 2>/dev/null)"
        if [ "$old" = "on" ]; then
          echo off > "$PID_DIR/flashlight.state"
        else
          echo on > "$PID_DIR/flashlight.state"
        fi
      else
        echo "torchctl unknown mode=$mode failed" >> "$LOG_DIR/torchctl.log"
        return 1
      fi
      ;;
  esac
}

open_package() {
  pkg="$1"
  [ -z "$pkg" ] && return

  am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p "$pkg" >/dev/null 2>&1 || \
  monkey -p "$pkg" 1 >/dev/null 2>&1
}

run_action_type_arg() {
  TYPE="$1"
  ARG="$2"

  [ -z "$TYPE" ] && TYPE=0

  case "$TYPE" in
    0)
      return 0
      ;;
    2)
      comp="$(config_get WECHAT_SCAN_COMPONENT)"
      [ -z "$comp" ] && comp="com.tencent.mm/.plugin.scanner.ui.BaseScanUI"
      am start -n "$comp" >/dev/null 2>&1 || open_package com.tencent.mm
      ;;
    3)
      comp="$(config_get WECHAT_PAY_COMPONENT)"
      [ -z "$comp" ] && comp="com.tencent.mm/com.tencent.mm.plugin.offline.ui.WalletOfflineCoinPurseUI"
      am start -n "$comp" >/dev/null 2>&1 || open_package com.tencent.mm
      ;;
    4)
      comp="$(config_get ALIPAY_SCAN_COMPONENT)"
      uri="$(config_get ALIPAY_SCAN_URI)"
      [ -z "$uri" ] && uri="alipayqr://platformapi/startapp?saId=10000007"
      if [ -n "$comp" ]; then
        am start -n "$comp" >/dev/null 2>&1 || \
        am start -a android.intent.action.VIEW -d "$uri" >/dev/null 2>&1 || \
        open_package com.eg.android.AlipayGphone
      else
        am start -a android.intent.action.VIEW -d "$uri" >/dev/null 2>&1 || \
        open_package com.eg.android.AlipayGphone
      fi
      ;;
    5)
      comp="$(config_get ALIPAY_PAY_COMPONENT)"
      uri="$(config_get ALIPAY_PAY_URI)"
      [ -z "$uri" ] && uri="alipays://platformapi/startapp?appId=20000056"
      if [ -n "$comp" ]; then
        am start -n "$comp" >/dev/null 2>&1 || \
        am start -a android.intent.action.VIEW -d "$uri" >/dev/null 2>&1 || \
        open_package com.eg.android.AlipayGphone
      else
        am start -a android.intent.action.VIEW -d "$uri" >/dev/null 2>&1 || \
        open_package com.eg.android.AlipayGphone
      fi
      ;;
    6)
      [ -z "$ARG" ] && ARG="$(config_get DEFAULT_PACKAGE)"
      open_package "$ARG"
      ;;
    7)
      [ -z "$ARG" ] && ARG="$(config_get DEFAULT_URL)"
      [ -n "$ARG" ] && am start -a android.intent.action.VIEW -d "$ARG" >/dev/null 2>&1
      ;;
    8)
      [ -z "$ARG" ] && ARG="toggle"
      flashlight_control "$ARG"
      ;;
  esac
}

run_action_event() {
  EVENT="$1"
  BASE="ACTION_$EVENT"

  TYPE="$(config_get "${BASE}_TYPE")"
  ARG="$(config_get "${BASE}_ARG")"

  [ -z "$TYPE" ] && TYPE=0

  case "$TYPE" in
    0)
      return 0
      ;;
    1)
      SCRIPT="$(shell_file_by_event "$EVENT")"
      [ -n "$SCRIPT" ] && [ -f "$SCRIPT" ] && /system/bin/sh "$SCRIPT" >/dev/null 2>&1 &
      ;;
    *)
      run_action_type_arg "$TYPE" "$ARG"
      ;;
  esac
}

run_action_draft() {
  EVENT="$1"
  TYPE="$2"
  ARG="$3"
  SHELL_CONTENT="$4"

  case "$TYPE" in
    0)
      return 0
      ;;
    1)
      TMP="$PID_DIR/draft_${EVENT}_$$.sh"
      printf '%s\n' "$SHELL_CONTENT" > "$TMP"
      chmod 0755 "$TMP" 2>/dev/null
      (
        /system/bin/sh "$TMP" >/dev/null 2>&1
        rm -f "$TMP"
      ) &
      ;;
    *)
      run_action_type_arg "$TYPE" "$ARG"
      ;;
  esac
}