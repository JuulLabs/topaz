#!/bin/sh

VERSIONS=$(xcrun simctl list runtimes | grep '^iOS' | sort -r | cut -d\  -f 2 | xargs)
for VERSION in $VERSIONS; do
    UUID=$(xcrun simctl list devices available "iOS $VERSION" | grep -E 'iPhone \d+ Pro [^M]' | sort -r | head -1 | awk -F '[()]' '{ print $(NF-3) }')
    if [ ! -z "$UUID" ]; then
        echo $UUID
        exit 0
    fi
done
exit 1
