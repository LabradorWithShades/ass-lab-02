#!/bin/bash

git submodule update --init

fasm source.asm lr.com
mv lr.com vm/floppy/

cd vm
./run_v31.sh
