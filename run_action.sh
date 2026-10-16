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