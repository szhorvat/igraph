#! /bin/sh

## Find out our version number, need git for this
printf "Finding out version number/string... "
tools/getversion.sh > VERSION
cat VERSION

for i in glibtoolize libtoolize; do
  LIBTOOLIZE=`which $i` && break
done
if [ -z "$LIBTOOLIZE" ]; then
  echo libtoolize or glibtoolize not found or not in the path!
  exit 1
fi

set -x
aclocal
$LIBTOOLIZE --force --copy
autoheader
automake --add-missing --copy
autoconf

# Try to patch ltmain.sh to allow -fsanitize=* linker flags to be passed
# through to the linker. Don't do anything if it fails; maybe libtool has
# been upgraded already.
patch -N -p0 <tools/ltmain.patch >/dev/null || true
