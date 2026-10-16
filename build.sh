#!/data/data/com.termux/files/usr/bin/sh

set -e

cd "$(dirname "$0")"

echo "[1/3] check clang"
if ! command -v clang >/dev/null 2>&1; then
  echo "clang not found, please run:"
  echo "pkg install clang"
  exit 1
fi

echo "clang path: $(command -v clang)"
clang --version | head -n 1

echo "[2/3] fix includes"
grep -q '#include <stdarg.h>' skp-keyd.c || sed -i '/#include <signal.h>/a #include <stdarg.h>' skp-keyd.c
grep -q '#include <sys/time.h>' skp-keyd.c || sed -i '/#include <sys\/wait.h>/a #include <sys/time.h>' skp-keyd.c

echo "[3/3] build"
clang \
  -O2 \
  -Wall \
  -Wextra \
  -DANDROID \
  -o skp-keyd \
  skp-keyd.c

chmod 0755 skp-keyd

echo "build ok:"
ls -l skp-keyd

file skp-keyd 2>/dev/null || true
