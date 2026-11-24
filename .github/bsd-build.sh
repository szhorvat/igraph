#!/bin/sh
# Temporary helper for the portability workflows (not for merging).
# usage: sh .github/bsd-build.sh NAME [extra cmake args...]
# Configures, builds (keep going on errors) and tests one configuration,
# printing a summary of warnings, errors and failed tests.
name=$1; shift
[ -d /usr/gnu/bin ] && PATH=/usr/gnu/bin:$PATH
export OMP_NUM_THREADS=1
if command -v ninja >/dev/null 2>&1; then gen="-G Ninja"; keep="-k 0"
elif command -v gmake >/dev/null 2>&1; then gen="-DCMAKE_MAKE_PROGRAM=gmake"; keep="-k"
else gen=""; keep="-k"; fi
top=$(pwd)
b="$top/build-$name"; rm -rf "$b"; mkdir "$b"; cd "$b" || exit 1
echo "##### $name: cmake $gen $*"
if ! cmake "$top" $gen -DCMAKE_BUILD_TYPE=RelWithDebInfo -DIGRAPH_VERIFY_FINALLY_STACK=ON "$@" > cfg.log 2>&1; then
  tail -40 cfg.log; echo "RESULT $name: CONFIGURE FAILED"; exit 1
fi
sed -n '/Build configuration/,/Diff tool/p' cfg.log
grep -E '^(HAVE_[A-Z_]*|SINH_FUNCTION_EXISTS):' CMakeCache.txt | sort || true
rc=0; cmake --build . --target build_tests -j 4 -- $keep > build.log 2>&1 || rc=$?
echo "--- $name: build exit code $rc; warnings (count, deduplicated):"
grep 'warning:' build.log | sed "s|$top/||g" | sort | uniq -c | sort -rn | head -60
echo "--- $name: errors:"
grep -E 'error:|Error [0-9]|FAILED:' build.log | sed "s|$top/||g" | sort | uniq -c | head -40
if [ $rc -ne 0 ]; then
  grep -B2 -A12 -m3 'error:' build.log | sed "s|$top/||g"
  echo "RESULT $name: BUILD FAILED"; exit 1
fi
ctest -j 4 --timeout 600 > test.log 2>&1; trc=$?
grep -E 'tests passed|\(Failed\)|\(Timeout\)|\(SEGFAULT\)|\(Subprocess|Exception' test.log
if [ $trc -ne 0 ]; then
  for t in $(grep -E '^ *[0-9]+ - .*\((Failed|Timeout|SEGFAULT|Subprocess.*|Exception.*)\)' test.log | sed 's/.* - \([^ ]*\) .*/\1/'); do
    echo "--- output of $t"; ctest -R "^$t\$" --output-on-failure 2>&1 | tail -40
  done
  echo "RESULT $name: TESTS FAILED"; exit 1
fi
echo "RESULT $name: OK"
