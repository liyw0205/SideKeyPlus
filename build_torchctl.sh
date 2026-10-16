#!/data/data/com.termux/files/usr/bin/sh

set -e

cd "$(dirname "$0")"

R8_VERSION="8.3.37"
R8_JAR="$PWD/r8-${R8_VERSION}.jar"
R8_URL="https://dl.google.com/dl/android/maven2/com/android/tools/r8/${R8_VERSION}/r8-${R8_VERSION}.jar"

OUT_DIR="$PWD/out"
FINAL_JAR="$PWD/torchctl.dex.jar"

echo "[1/5] check javac"
if ! command -v javac >/dev/null 2>&1; then
  echo "javac not found"
  echo "run:"
  echo "pkg install openjdk-17"
  exit 1
fi

javac -version

echo "[2/5] download r8/d8 if needed"
if ! command -v d8 >/dev/null 2>&1 && [ ! -f "$R8_JAR" ]; then
  echo "download: $R8_URL"
  curl -L -o "$R8_JAR" "$R8_URL"
fi

echo "[3/5] compile java"
rm -f TorchCtl*.class
javac --release 8 TorchCtl.java

echo "compiled classes:"
ls -l TorchCtl*.class

echo "[4/5] dex by d8"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

if command -v d8 >/dev/null 2>&1; then
  d8 \
    --release \
    --min-api 23 \
    --output "$OUT_DIR" \
    TorchCtl*.class
else
  java -cp "$R8_JAR" com.android.tools.r8.D8 \
    --release \
    --min-api 23 \
    --output "$OUT_DIR" \
    TorchCtl*.class
fi

echo "[5/5] pack jar"
rm -f "$FINAL_JAR"

(
  cd "$OUT_DIR"
  zip -q "$FINAL_JAR" classes.dex
)

chmod 0644 "$FINAL_JAR"

echo
echo "build ok:"
ls -l "$FINAL_JAR"
echo
echo "test commands:"
echo "su -c '/system/bin/app_process64 -Djava.class.path=$FINAL_JAR /system/bin TorchCtl info'"
echo "su -c '/system/bin/app_process64 -Djava.class.path=$FINAL_JAR /system/bin TorchCtl hold'"
echo "su -c '/system/bin/app_process64 -Djava.class.path=$FINAL_JAR /system/bin TorchCtl off'"
