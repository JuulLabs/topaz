#!/bin/sh
#
# Not sure when it changed but altool no longer returns a non-zero exit code on failure.
# This script scans command output for errors and injects the non-zero exit code on match.


if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <error-regex> <command>"
    exit 1
fi

TMPFILE=$(mktemp /tmp/error_scan.XXXXXX)
REGEX="$1"
shift

set -o pipefail
$@ 2>&1 | tee "$TMPFILE"
if [ $? -ne 0 ]; then
    # This script only exists because altool currently returns 0 even on error, maybe it will get fixed someday
    echo "Command emitted non-zero exit code - consider removing error_scan.sh wrapper."
    rm "$TMPFILE"
    exit 1
fi

grep -q -i "$REGEX" "$TMPFILE" && {
    echo "Error detected in command output - returning non-zero exit code."
    rm "$TMPFILE"
    exit 1
}
rm "$TMPFILE"
