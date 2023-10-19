#!/usr/bin/env bash

if [[ -f .git || -d .git ]]; then
    files=$(git ls-files | grep -E '\.(c|cpp)$')
else
    files=$(find . -type f -not \( -path '*/build/*' -prune \) -name '*.c' -or -name '*.cpp')
fi
res=$?

if [ "$res" != 0 ]; then
    exit 1
else
    echo "$files"
fi

exit 0
