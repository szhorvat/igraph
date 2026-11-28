#!/bin/bash
# Usage: run.sh <label> <runs> <compiler> <flags...>
label=$1; runs=$2; cc=$3; shift 3
exe=sd_$label.exe
$cc -O2 "$@" ci-seh/sehdiag.c -o $exe || exit 1
: > res_$label.txt
for i in $(seq $runs); do
  out=$(./$exe 2>&1); code=$?
  pred=$(echo "$out" | grep -o 'predict=[A-Z]*' | cut -d= -f2)
  top=$(echo "$out" | grep -o 'top=rbp+[0-9]*' | cut -d+ -f2)
  xmm=$(echo "$out" | grep -o 'xmm6=[^ ]*' | cut -d= -f2)
  if echo "$out" | grep -q 'survived=1'; then res=survived; else res=crash$code; fi
  echo "$top $xmm $pred $res" >> res_$label.txt
done
echo "== $label ($cc $*): $runs runs"
echo "   prediction/outcome counts:"; awk '{print "     " $3, $4}' res_$label.txt | sort | uniq -c
echo "   StackBase - rbp: min/max"; awk '{print $1}' res_$label.txt | sort -n | sed -n '1p;$p' | tr '\n' ' '; echo
echo "   unwinder's xmm6 slot:"; awk '{print $2}' res_$label.txt | sort | uniq -c | head -3
