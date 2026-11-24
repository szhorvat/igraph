#!/bin/sh
# Temporary (not for merging): CMAKE_CROSSCOMPILING_EMULATOR wrapper that runs a binary on the Android emulator.
# Test binaries are pushed in bulk beforehand; anything else (e.g. f2c's arithchk) is pushed on demand.
path=$1; shift
exe=$(basename "$path")
case "$path" in
  */build-android/tests/*) ;;
  *) adb push "$path" /data/local/tmp/bin/ >/dev/null 2>&1 ;;
esac
rel=${PWD#"$GITHUB_WORKSPACE"/}
exec adb shell "cd /data/local/tmp/ws/$rel 2>/dev/null || cd /data/local/tmp/ws; OMP_NUM_THREADS=1 /data/local/tmp/bin/$exe $*"
