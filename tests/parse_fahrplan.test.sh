#!/bin/bash

## init temporary files

stdout=$(mktemp)
stderr=$(mktemp)
tests=$(mktemp)

cleanup()
{
    rm -f "$stdout" "$stderr" "$tests"
}

trap cleanup EXIT


## the tests - functions must start with "test_"

test_ok()
{
    return 0
}

test_fail()
{
    echo "failed"
    return 1
}

## run tests

declare -F > "$tests"

test_sum=0
test_ok=0
test_fail=0
while read -r _ _ function; do
    if [ "${function:0:5}" = 'test_' ]; then
	(( test_sum++ ))
	echo -n "$function: "
	if eval "$function"; then
	    echo "OK"
	    (( test_ok++ ))
	else
	    (( test_fail++ ))
	fi
    fi
done < "$tests"

## show results

echo
printf "ran %3d tests\\n" $test_sum
printf "%3d tests succeeded\\n" $test_ok
printf "%3d tests failed\\n" $test_fail

[ $test_fail -eq 0 ]
