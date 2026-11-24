#!/bin/sh
# Temporary probe: why does glpk_support.c not warn about noreturn + longjmp while qhull does?
CC=$1
echo "=== sys/ccompile.h: __sun_attr__ and conditions"
grep -n '__sun_attr\|^#if\|^#else\|^#endif\|^#elif' /usr/include/sys/ccompile.h | sed -n '1,80p'
echo "=== sys/feature_tests.h: strict-mode macros"
grep -n '_STRICT_STDC\|_STRICT_SYMBOLS\|__EXTENSIONS__\|_STDC_C11\|_STDC_C99' /usr/include/sys/feature_tests.h | sed -n '1,60p'
printf '#include <setjmp.h>\njmp_buf b;\n__attribute__((__noreturn__)) void f(void) { longjmp(b, 1); }\n' > nr.c
for d in "-D_POSIX_C_SOURCE=200809L" "-D_POSIX_C_SOURCE=200809L -D__EXTENSIONS__" "-D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700" "-D_XOPEN_SOURCE=700" "-D__EXTENSIONS__"; do
  echo "=== nr.c -std=gnu99 $d"; $CC -std=gnu99 $d -Wall -c nr.c -o nr.o 2>&1 | grep 'warning' || echo clean
done
mkdir probe && cd probe
cmake .. -DCMAKE_C_COMPILER=$CC -DCMAKE_MAKE_PROGRAM=gmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DIGRAPH_USE_INTERNAL_BLAS=ON -DIGRAPH_USE_INTERNAL_LAPACK=ON -DIGRAPH_USE_INTERNAL_ARPACK=ON \
  -DIGRAPH_USE_INTERNAL_GLPK=ON -DIGRAPH_USE_INTERNAL_PLFIT=ON -DIGRAPH_USE_INTERNAL_GMP=ON > cfg.log 2>&1 || { tail -30 cfg.log; exit 1; }
gmake parsersources > /dev/null 2>&1 || true
for f in src/internal/glpk_support.c vendor/qhull/libqhull_r/user_r.c; do
  echo "=== compile command for $f"
  cmd=$(grep "\"command\": .*$f\"" compile_commands.json | sed 's/^ *"command": "//; s/",$//; s/\\"/"/g')
  dir=$(grep -B1 "\"command\": .*$f\"" compile_commands.json | head -1 | sed 's/^ *"directory": "//; s/",$//')
  echo "$cmd"
  pre=$(echo "$cmd" | sed 's/ -o [^ ]*/ -o -/; s/ -c / -E -dD /')
  echo "--- longjmp declaration and strict-mode macros seen in $f"
  (cd "$dir" && eval "$pre" 2>&1) | grep -n 'void longjmp\|define __EXTENSIONS__\|define _STRICT_STDC\|define _STRICT_SYMBOLS\|define __sun_attr__\|define _XOPEN_SOURCE\|define _POSIX_C_SOURCE\|define _GNU_SOURCE\|define _DARWIN_C_SOURCE\|define _BSD_SOURCE\|define _DEFAULT_SOURCE' | head -20
  echo "--- first headers included"
  (cd "$dir" && eval "$(echo "$pre" | sed 's/ -dD / -H /; s/ -o - / -o \/dev\/null /')" 2>&1 >/dev/null) | grep '^\.' | head -25
done
