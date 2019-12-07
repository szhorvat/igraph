#!/bin/sh

set -e

cwd=$(pwd)
upd=$cwd/..

gmp=gmp-6.1.2
cd $upd
if [ ! -d ${gmp} ]; then
  wget https://gmplib.org/download/gmp/${gmp}.tar.bz2
  tar xfj ${gmp}.tar.bz2
  cd ${gmp}
  ./configure --prefix=$HOME/local
  make
  make install
else
  echo ${gmp} exists!
fi

cd $upd
glpk=glpk-4.65
if [ ! -d ${glpk} ]; then
  wget http://ftp.gnu.org/gnu/glpk/${glpk}.tar.gz
  tar xfz ${glpk}.tar.gz
  cd ${glpk}
  ./configure --prefix=$HOME/local
  make
  make install
else
  echo ${glpk} exists!
fi

cd $cwd
