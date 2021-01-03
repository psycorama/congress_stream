#!/bin/bash

## configuration

test_schedule=tests/schedule.test

## init temporary files

tempdir=$(mktemp -d --tmpdir parse_fahrplan.test.XXXXXXXXXX)
stdout="$tempdir/stdout"
stderr="$tempdir/stderr"
tests="$tempdir/tests"
expected="$tempdir/expected"
tempfile="$tempdir/tempfile"

cleanup()
{
    rm -rf "$tempdir"
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

file_contains_expected()
{
    local file=$1
    local firstline start length end

    read -r firstline < "$expected"

    start=$(grep -F -n "$firstline" "$file" | cut -f1 -d:)

    if [ -z "$start" ]; then
	return 1
    fi

    read -r length _ < <(wc -l "$expected")
    end=$(( start + length - 1))

    sed -n "$start","$end"p "$file" > "$tempfile"

    diff "$expected" "$tempfile" > /dev/null
}

file_contains_string()
{
    local file=$1 expected=$2

    grep -F -q "$expected" "$file"
}

show_diff_to_expected()
{
    local actual=$1
    
    diff -u "$expected" "$actual" || true
}

fail()
{
    echo
    echo " ! $*"
}

assert_stdout_is_empty()
{
    if ! file_is_empty "$stdout"; then
	fail "stdout is not empty"
	cat "$stdout"
	return 1
    fi
}

assert_stderr_is_empty()
{
    if ! file_is_empty "$stderr"; then
	fail "stderr is not empty"
	cat "$stderr"
	return 1
    fi
}

## the tests - functions must start with "test_"

test_no_filename_returns_error()
{
    if call_script; then
	echo 'RC == 0'
	return 1
    fi

    assert_stdout_is_empty || return

    if ! file_contains_string "$stderr" 'no fahrplan filenames given'; then
	echo "error message not found:"
	cat "$stderr"
	return 1
    fi
}

test_wrong_filename_returns_error()
{
    if call_script $test_schedule NON-EXISTING-FILE; then
	echo 'RC == 0'
	return 1
    fi

    assert_stdout_is_empty || return

    if ! file_contains_string "$stderr" "can't open \`NON-EXISTING-FILE':"; then
	echo "error message not found:"
	cat "$stderr"
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
	show_diff_to_expected "$stdout"
	return 1
    fi

    assert_stderr_is_empty || return
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
	show_diff_to_expected "$stdout"
	return 1
    fi

    assert_stderr_is_empty || return
}

test_day_with_many_eventy_lists_rooms_in_random_order()
{
    if ! call_script -faketime=202012281300 $test_schedule; then
	echo 'RC != 0'
	return 1
    fi

    if ! file_contains_string "$stdout" 'time overwritten as 2020-12-28 13:00'; then
	echo "fake time notification not found in stdout:"
	cat "$stdout"
	return 1
    fi

    set_expected <<EOF
reruns:
  12:52h -> +00:56h  playing videogames for fun and profit
                     []

  13:48h -> +00:40h  hacking things
                     []

EOF

    if ! file_contains_expected "$stdout"; then
	echo "expected text not found in stdout:"
	cat "$expected"
	show_diff_to_expected "$stdout"
	return 1
    fi

    set_expected <<EOF
room 1:
  12:00h -> +01:00h  hack ALL the things
                     [Rubeen, Doren, Johan]

  14:00h -> +00:40h  hacking things for fun and profit
                     [Lesy, Hathrin, Jooordt]

EOF

    if ! file_contains_expected "$stdout"; then
	echo "expected text not found in stdout:"
	cat "$expected"
	show_diff_to_expected "$stdout"
	return 1
    fi

    set_expected <<EOF
room 2:
  13:00h -> +01:00h  data for (data) digitizens
                     [Gelisa]

EOF

    if ! file_contains_expected "$stdout"; then
	echo "expected text not found in stdout:"
	cat "$expected"
	show_diff_to_expected "$stdout"
	return 1
    fi

    set_expected <<EOF
rümlaut:
  12:00h -> +03:00h  Digitale Affenbande
                     [Wawr]

EOF

    if ! file_contains_expected "$stdout"; then
	echo "expected text not found in stdout:"
	cat "$expected"
	show_diff_to_expected "$stdout"
	return 1
    fi

    assert_stderr_is_empty || return
}

## run tests

declare -F > "$tests"

test_sum=0
test_ok=0
test_fail=0
while read -r _ _ function; do
    if [ "${function:0:5}" = 'test_' ]; then
	(( test_sum++ ))
	echo -n " * $function: "
	if eval "$function"; then
	    echo "OK"
	    (( test_ok++ ))
	else
	    (( test_fail++ ))
	    echo
	fi
    fi
done < "$tests"

## show results

echo
echo '--------------'
printf "ran %3d tests:\\n" $test_sum
printf "%3d tests succeeded\\n" $test_ok
printf "%3d tests failed\\n" $test_fail

[ $test_fail -eq 0 ]
