#!/usr/bin/env bash

if [[ -f .git || -d .git ]]; then
    files=$(git ls-files | grep -E '\.(c|cpp)$')
else
    files=$(find . -name '*.c' ! -path '*/build/*' -or -name '*.cpp' ! -path '*/build/*')
fi
res=$?

if [ "$res" != 0 ]; then
    exit 1
else
    echo "$files"
fi

exit 0
