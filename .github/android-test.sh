#!/bin/bash
# Temporary (not for merging): build igraph for Android and run its test suite on the emulator via adb.
set -u
W=$GITHUB_WORKSPACE; cd "$W"
adb wait-for-device
echo "Android $(adb shell getprop ro.build.version.release) ABI $(adb shell getprop ro.product.cpu.abi)"
cat "$ANDROID_NDK_LATEST_HOME/source.properties"
adb shell mkdir -p /data/local/tmp/ws /data/local/tmp/bin
tar -cf /tmp/data.tar tests examples
adb push /tmp/data.tar /data/local/tmp/ >/dev/null && adb shell "cd /data/local/tmp/ws && tar -xf ../data.tar"
# Sanity check of the emulator wrapper with the endianness probe that CMake's try_run uses.
case $ABI in x86_64) T=x86_64-linux-android;; x86) T=i686-linux-android;; esac
CC="$ANDROID_NDK_LATEST_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/${T}${API}-clang"
"$CC" -o /tmp/endcheck etc/cmake/ieee754_endianness_check.c && ( cd /tmp && "$W/.github/adb-run.sh" /tmp/endcheck; echo "wrapper probe rc=$?" ) | od -c | head -5
# arithchk is run through the emulator wrapper during the build, so the device must be up first.
cmake -S . -B build-android -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo $VENDORED -DIGRAPH_VERIFY_FINALLY_STACK=ON -DIGRAPH_ENABLE_TLS=ON \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_LATEST_HOME/build/cmake/android.toolchain.cmake" -DANDROID_ABI=$ABI -DANDROID_PLATFORM=$API -DANDROID_STL=c++_static \
  -DCMAKE_CROSSCOMPILING_EMULATOR="$W/.github/adb-run.sh" -DIGRAPH_PRINT_ARITH_HEADER=ON -DIGRAPH_GRAPHML_SUPPORT=OFF > cfg.log 2>&1
if [ $? -ne 0 ]; then
  tail -20 cfg.log
  echo "--- try_run details from CMakeConfigureLog.yaml:"
  grep -n -A40 "ieee754_endianness_check" build-android/CMakeFiles/CMakeConfigureLog.yaml | grep -E "exitCode|stdout|stderr|run:|OK|returnValue|executable" | head -30
  echo "RESULT android: CONFIGURE FAILED on endianness try_run; retrying with IEEE754_DOUBLE_ENDIANNESS_MATCHES=ON"
  cmake build-android -DIEEE754_DOUBLE_ENDIANNESS_MATCHES=ON > cfg.log 2>&1 || { tail -40 cfg.log; echo "RESULT android: CONFIGURE FAILED"; exit 1; }
fi
sed -n '/Build configuration/,/Diff tool/p' cfg.log
grep -E '^(HAVE_[A-Z_]*):' build-android/CMakeCache.txt | sort
cmake --build build-android --target build_tests -- -k 0 > build.log 2>&1; rc=$?
echo "build exit code $rc; warnings:"; grep 'warning:' build.log | sort | uniq -c | sort -rn | head -40
echo "errors:"; grep -E 'error:|FAILED:' build.log | sort | uniq -c | sort -rn | head -40
grep -A10 "arith.h" build.log | head -14
[ $rc -eq 0 ] || { echo "RESULT android: BUILD FAILED"; exit 1; }
( cd build-android/tests && find . -maxdepth 1 -type f -perm -u+x | tar -cf /tmp/bin.tar -T - )
adb push /tmp/bin.tar /data/local/tmp/ >/dev/null && adb shell "cd /data/local/tmp/bin && tar -xf ../bin.tar"
echo "--- diagnostics"
adb shell "ls -l /data/local/tmp/bin | head -5; ls /data/local/tmp/bin | wc -l; ls /data/local/tmp/ws/tests | head -3"
adb shell "/data/local/tmp/bin/test_bitset; echo rc=\$?" | head -20
( cd build-android && ctest -V -R '^test::bitset$' 2>&1 | tail -30; ctest --output-on-failure -R '^example::igraph_version$' 2>&1 | tail -30 )
echo "--- end diagnostics"
cd build-android && ctest -j 2 --timeout 600 > ctest.log 2>&1; rc=$?
grep -E "tests passed|\(Failed\)|\(SEGFAULT\)|\(Timeout\)|\(Subprocess|Exception" ctest.log | head -60
grep -B2 -A25 -E "\*\*\*Failed|Exception:" ctest.log | head -250
echo "RESULT android tests: rc=$rc"
exit $rc
