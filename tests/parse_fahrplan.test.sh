#!/bin/bash

## configuration

test_schedule=tests/schedule.test

## init temporary files

stdout=$(mktemp --tmpdir stdout.XXXXXXXXXX)
stderr=$(mktemp --tmpdir stderr.XXXXXXXXXX)
tests=$(mktemp --tmpdir tests.XXXXXXXXXX)
expected=$(mktemp --tmpdir expected.XXXXXXXXXX)

cleanup()
{
    rm -f "$stdout" "$stderr" "$tests" "$expected"
}

trap cleanup EXIT

## helper functions

call_script()
{
    ./parse_fahrplan.pl "$@" 1> "$stdout" 2> "$stderr"
}

file_is_empty()
{
    local file=$1

    ! [ -s "$file" ]
}

set_expected()
{
    cat > "$expected"
}

matches_expected()
{
    local actual=$1
    
    diff "$expected" "$actual" > /dev/null
}

show_diff()
{
    local actual=$1
    
    diff -u "$expected" "$actual" || true
}

file_contains()
{
    local file=$1 expected=$2

    grep -q "$expected" "$file"
}

## the tests - functions must start with "test_"

test_no_filename_returns_error()
{
    if call_script; then
	echo 'RC == 0'
	return 1
    fi

    if ! file_is_empty "$stdout"; then
	echo "stdout is not empty"
	return 1
    fi

    if ! file_contains "$stderr" 'no fahrplan filenames given'; then
	echo "error message not found"
	return 1
    fi
}

test_wrong_filename_returns_error()
{
    if call_script $test_schedule NON-EXISTING-FILE; then
	echo 'RC == 0'
	return 1
    fi

    if ! file_is_empty "$stdout"; then
	echo "stdout is not empty"
	return 1
    fi

    if ! file_contains "$stderr" "can't open \`NON-EXISTING-FILE':"; then
	echo "error message not found"
	return 1
    fi
}

test_day_with_no_events_lists_empty_fahrplan()
{
    if ! call_script -faketime=202012201515 $test_schedule; then
	echo 'RC != 0'
	return 1
    fi

    set_expected <<EOF
time overwritten as 2020-12-20 15:15
EOF

    if ! matches_expected "$stdout"; then
	echo "stdout differs from expected:"
	show_diff "$stdout"
	return 1
    fi

    if ! file_is_empty "$stderr"; then
	echo "stderr is not empty"
	return 1
    fi
}

test_day_with_single_room_lists_only_that_room()
{
    if ! call_script -faketime=202012292000 $test_schedule; then
	echo 'RC != 0'
	return 1
    fi

    set_expected <<EOF
time overwritten as 2020-12-29 20:00
only room:
  19:45h -> +00:25h  Eventually consistent
                     [Joordt, t.k.l, m.t.h]

EOF

    if ! matches_expected "$stdout"; then
	echo "stdout differs from expected:"
	show_diff "$stdout"
	return 1
    fi

    if ! file_is_empty "$stderr"; then
	echo "stderr is not empty"
	return 1
    fi
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
