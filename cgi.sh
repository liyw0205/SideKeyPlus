#!/system/bin/sh

MODDIR="${MODDIR:-/data/adb/modules/SideKeyPlus}"
COMMON_SH="${COMMON_SH:-$MODDIR/common.sh}"

[ -f "$COMMON_SH" ] || exit 1
. "$COMMON_SH"

urldecode() {
  local data="${1//+/ }"
  printf '%b' "$(echo "$data" | bb sed 's/%/\\x/g')"
}

json_escape() {
  bb sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\r/\\r/g;s/\n/\\n/g'
}

read_body() {
  if [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null; then
    dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null
  fi
}

print_json_header() {
  echo "Content-Type: application/json"
  echo "Access-Control-Allow-Origin: *"
  echo
}

parse_post_to_config() {
  BODY="$(read_body)"
  TMP_UPDATES="$PID_DIR/config_post.$$"

  mkdir -p "$PID_DIR" 2>/dev/null
  : > "$TMP_UPDATES"

  OLD_IFS="$IFS"
  IFS='&'

  for pair in $BODY; do
    KEY="${pair%%=*}"
    VAL="${pair#*=}"

    KEY="$(urldecode "$KEY")"
    VAL="$(urldecode "$VAL")"

    case "$KEY" in
      ACTION_UP_SHELL|ACTION_UP_RESET_SHELL|ACTION_DOWN_SHELL|ACTION_DOWN_RESET_SHELL|ACTION_VOLUME_UP_CLICK_SHELL|ACTION_VOLUME_UP_DOUBLE_SHELL|ACTION_VOLUME_UP_LONG_SHELL|ACTION_VOLUME_DOWN_CLICK_SHELL|ACTION_VOLUME_DOWN_DOUBLE_SHELL|ACTION_VOLUME_DOWN_LONG_SHELL|ACTION_VOLUME_BOTH_CLICK_SHELL)
        sf="$(shell_file_by_key "$KEY")"
        if [ -n "$sf" ]; then
          printf '%s\n' "$VAL" > "$sf"
          chmod 0755 "$sf"
        fi
        ;;
      BUSYBOX_PATH|ROOT_TYPE)
        ;;
      WEB_PORT|BACKEND_ENABLE|SLIDER_SETTINGS_NS|SLIDER_SETTINGS_KEY|VALUE_UP|VALUE_MID|VALUE_DOWN|POLL_INTERVAL|DEFAULT_PACKAGE|DEFAULT_URL|AUTHOR|COOLAPK|QQ_GROUP|QQ_GROUP_LINK|BLOCK_VOLUME_KEY|VOLUME_KEY_ENABLE|WECHAT_SCAN_COMPONENT|WECHAT_PAY_COMPONENT|ALIPAY_SCAN_COMPONENT|ALIPAY_PAY_COMPONENT|ALIPAY_SCAN_URI|ALIPAY_PAY_URI|ACTION_UP_TYPE|ACTION_UP_ARG|ACTION_UP_RESET_TYPE|ACTION_UP_RESET_ARG|ACTION_DOWN_TYPE|ACTION_DOWN_ARG|ACTION_DOWN_RESET_TYPE|ACTION_DOWN_RESET_ARG|ACTION_VOLUME_UP_CLICK_TYPE|ACTION_VOLUME_UP_CLICK_ARG|ACTION_VOLUME_UP_DOUBLE_TYPE|ACTION_VOLUME_UP_DOUBLE_ARG|ACTION_VOLUME_UP_LONG_TYPE|ACTION_VOLUME_UP_LONG_ARG|ACTION_VOLUME_DOWN_CLICK_TYPE|ACTION_VOLUME_DOWN_CLICK_ARG|ACTION_VOLUME_DOWN_DOUBLE_TYPE|ACTION_VOLUME_DOWN_DOUBLE_ARG|ACTION_VOLUME_DOWN_LONG_TYPE|ACTION_VOLUME_DOWN_LONG_ARG|ACTION_VOLUME_BOTH_CLICK_TYPE|ACTION_VOLUME_BOTH_CLICK_ARG)
        printf '%s=%s\n' "$KEY" "$VAL" >> "$TMP_UPDATES"
        ;;
    esac
  done

  IFS="$OLD_IFS"

  config_apply_updates "$TMP_UPDATES"
  RET=$?
  rm -f "$TMP_UPDATES"
  return $RET
}