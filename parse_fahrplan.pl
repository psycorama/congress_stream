#!/usr/bin/env perl
use warnings;
use strict;
use XML::Simple;

use Encode;

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

my $filename = shift @ARGV;
die "no fahrplan filename given" unless defined $filename;
my $xml = `cat $filename`;
my $ref = XMLin($xml);

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

sub handle_event($$$$$) {

    my ($event, $saal, $event_id, $recurse, $offset) = @_;
    my $found = 0;
    
    my $now = $hour*60 + $min + $offset;
    if ($now >= ttm($event->{start})
	and
	$now <= ttm($event->{start})+ttm($event->{duration})
	and
	!exists $seen{$event_id}) {
	
	my @persons;
	
	if (exists $event->{persons}->{person}->{content}) {
	    push @persons, $event->{persons}->{person}->{content};
	} else {
	    @persons = map { $_->{content} } grep { ref $_ eq 'HASH' } values %{$event->{persons}->{person}};
	}
	
	$seen{$event_id}++; ### WTF HACKS!
	
	printf("  %sh -> +%sh  %s\n                     [%s]\n\n",
	       $event->{start},
	       format_duration($event->{duration}),
	       encode_utf8($event->{title}),
	       encode_utf8(join (', ', @persons))
	    );
	$found++;
	
	if ($recurse) {
	    $offset = $offset + ttm($event->{duration});
	    $found += search($saal, 0, $offset);
	}
    }

    return $found;
}

sub search($$$) {
# die eigentliche Suche

    my ($saal, $recurse, $offset) = (@_);
    my $found = 0;

    foreach my $day (@{$ref->{day}}) {

	next unless $day->{date} eq "$year-$mon-$mday";

	my $events = $day->{room}->{$saal}->{event};

	if (exists $events->{id}) {
	    # whoops, just a single event, no list
	    $found += handle_event($events, $saal, $events->{id}, $recurse, $offset);
	}
	else {
	    foreach my $event_id ( keys %{$events} ) {
		my $event = $day->{room}->{$saal}->{event}->{$event_id};
		$found += handle_event($event, $saal, $event_id, $recurse, $offset);
	    }
	}

    }

    return $found;
}

sub get_all_rooms()
{
    my %rooms;
    foreach my $day (@{$ref->{day}}) {
	foreach my $room (keys %{$day->{room}}) {
	    $rooms{$room}++;
	}
    }
    return keys %rooms;
}

# NOTE: the rooms are not sorted but with so many rooms shuffling the
# order on every display is a good thing, so everybody gets to be on
# top once in a while
foreach my $saal (get_all_rooms()) { # foreach my $saal ('rC1', 'rC2', ... ) {
    printf "%s:\n", encode_utf8($saal);

    foreach my $lookahead (qw(0 20 40 60 80 100 120 140 160 180)) {
	last if search($saal, 1, $lookahead);
    }
}
