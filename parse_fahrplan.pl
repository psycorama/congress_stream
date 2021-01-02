#!/usr/bin/env perl
use warnings;
use strict;
use JSON::MaybeXS qw(decode_json);

binmode STDOUT, ':encoding(UTF-8)';

# usage:
# parse_fahrplan.pl [-faketime=YYYYMMDDhhmm] <file1> [<file2> [...]]

my (undef,$min,$hour,$mday,$mon,$year,undef,undef,undef) =
    localtime(time);
$mon+=1;
$year+=1900;

# overwrite current time via commandline for test purposes
# format is "-faketime=YYYYMMDDhhmm"
# starting from the right, only give what you want to change
# eg. '1255' would change time to 12:55 and keep the date
if (defined $ARGV[0] and $ARGV[0] =~ /^-faketime=\d+$/) {
    my $faketime = shift @ARGV;

    if ($faketime =~ s/(\d\d)$//) {
	$min = $1;
    }
    if ($faketime =~ s/(\d\d)$//) {
	$hour = $1;
    }
    if ($faketime =~ s/(\d\d)$//) {
	$mday = $1;
    }
    if ($faketime =~ s/(\d\d)$//) {
	$mon = $1;
    }
    if ($faketime =~ s/(\d\d\d\d)$//) {
	$year = $1;
    }
    printf "time overwritten as %04d-%02d-%02d %02d:%02d\n", $year, $mon, $mday, $hour, $min;
}

if ($hour < 4) {
    $mday--;
}

# TODO: pass around, don't use globals
my $ref;
my %seen;

sub ttm ($) {
# time to minutes
    if ($_[0] =~ /(\d+):(\d+)/) {
	return ($1*60 + $2);
    }
    return 0;
}

sub format_duration($) {
    my $duration = shift;
    $duration =~ s/^(\d):/0$1:/;
    return $duration;
}

sub search($$$);

sub handle_event($$$$) {

    my ($event, $saal, $recurse, $offset) = @_;
    my $event_id = $event->{id};
    my @found;
    
    my $now = $hour*60 + $min + $offset;
    if ($now >= ttm($event->{start})
	and
	$now <= ttm($event->{start})+ttm($event->{duration})
	and
	!exists $seen{$event_id}) {
	
	my @persons = map { $_->{public_name} } @{$event->{persons}};
	
	$seen{$event_id}++; ### WTF HACKS!

	push @found, {
	    START    => $event->{start},
	    DURATION => format_duration($event->{duration}),
	    TITLE    => $event->{title},
	    PERSONS  => join (', ', @persons)
	};
	
	if ($recurse) {
	    $offset = $offset + ttm($event->{duration});
	    push @found, search($saal, $recurse-1, $offset);
	}
    }

    return @found;
}

sub search($$$) {
# die eigentliche Suche

    my ($saal, $recurse, $offset) = (@_);
    my @found;

    foreach my $day (@{$ref->{schedule}->{conference}->{days}}) {

	next unless $day->{date} eq "$year-$mon-$mday";

	my $events = $day->{rooms}->{$saal};
	foreach my $event ( @{$events} ) {
	    push @found, handle_event($event, $saal, $recurse, $offset);
	}

    }

    return @found;
}

sub get_all_rooms()
{
    my %rooms;
    foreach my $day (@{$ref->{schedule}->{conference}->{days}}) {
	foreach my $room (keys %{$day->{rooms}}) {
	    $rooms{$room}++;
	}
    }
    return keys %rooms;
}

sub parse_file($)
{
    my $filename = shift;
    
    open my $json, '<', $filename or die "can't open `$filename': $!";
    local $/ = undef;
    $ref = decode_json(<$json>);
    close $json or die "can't close `$filename': $!";

    # reset cache
    %seen = ();

    # NOTE: the rooms are not sorted but with so many rooms shuffling the
    # order on every display is a good thing, so everybody gets to be on
    # top once in a while
    foreach my $saal (get_all_rooms()) { # foreach my $saal ('rC1', 'rC2', ... ) {
	foreach my $lookahead (qw(0 20 40 60 80 100 120 140 160 180)) {
	    if (my @events = search($saal, 1, $lookahead)) {
		printf "%s:\n", $saal;
		foreach my $event (@events) {
		    printf("  %sh -> +%sh  %s\n                     [%s]\n\n",
			   $event->{START},
			   $event->{DURATION},
			   $event->{TITLE},
			   $event->{PERSONS},
			);
		}
		last;
	    }
	}
    }
}

my @filenames = @ARGV;
die "no fahrplan filenames given" unless @filenames;
parse_file $_ foreach @filenames;
