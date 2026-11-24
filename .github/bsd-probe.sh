#!/bin/sh
# Temporary probe: which feature-test macro combinations work with C and C++ on this system?
cat > t.cpp <<'X'
#include <iostream>
#include <sstream>
#include <sys/time.h>
int main() { struct timeval t; gettimeofday(&t, NULL); std::ostringstream s; s << t.tv_sec; std::cout << s.str() << std::endl; return 0; }
X
cat > t.c <<'X'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <locale.h>
#include <setjmp.h>
#include <sys/time.h>
jmp_buf b;
__attribute__((__noreturn__)) void f(void) { longjmp(b, 1); }
int main(void) { struct timeval t; char *s = strdup("x"); char *n = strndup("xy", 1); locale_t l = newlocale(LC_ALL_MASK, "C", (locale_t) 0); uselocale(l);
  gettimeofday(&t, NULL); printf("%d %s %s\n", strcasecmp(s, "X"), s, n); free(s); free(n); return 0; }
X
for d in "" "-D_POSIX_C_SOURCE=200809L" "-D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700" "-D_XOPEN_SOURCE=700" \
         "-D_POSIX_C_SOURCE=200809L -D__BSD_VISIBLE=1" "-D_POSIX_C_SOURCE=200809L -D_BSD_SOURCE" \
         "-D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE" "-D_POSIX_C_SOURCE=200809L -D_NETBSD_SOURCE" \
         "-D_POSIX_C_SOURCE=200809L -D__EXTENSIONS__"; do
  for lang in c cxx; do
    if [ $lang = c ]; then cmd="cc -std=gnu99 -Wall -Werror $d t.c -o t"; else cmd="c++ -std=gnu++14 -Wall -Werror $d t.cpp -o t"; fi
    if out=$($cmd 2>&1); then echo "OK    $lang [$d]"; else echo "FAIL  $lang [$d]: $(echo "$out" | grep -m2 'error' | tr '\n' ' ' | cut -c1-220)"; fi
  done
done
