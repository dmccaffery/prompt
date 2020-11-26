#!/usr/bin/env sh

final=0

for test in ./test/sh/scripts/*.test.sh; do
    TERM=dumb $test
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        name=$(basename $test)
        echo "test ($name) failed: $exit_code"
        final=1
    fi
done

exit $final
