#!/bin/bash

set -u

parent_pid="$PPID"
child_pid=""

terminate_child() {
    if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
        kill -TERM "$child_pid" 2>/dev/null || true
    fi
}

trap terminate_child HUP INT TERM EXIT

"$@" &
child_pid="$!"

while kill -0 "$child_pid" 2>/dev/null; do
    if ! kill -0 "$parent_pid" 2>/dev/null; then
        terminate_child
        break
    fi
    sleep 1
done

wait "$child_pid"
exit_code="$?"
trap - EXIT
exit "$exit_code"
