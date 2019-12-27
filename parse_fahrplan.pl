#!/usr/bin/env perl
use warnings;
use strict;
use XML::Simple;

use Encode;

my $xml = `cat schedule`;
my $ref = XMLin($xml);

my (undef,$min,$hour,$mday,$mon,$year,undef,undef,undef) =
    localtime(time);
$mon+=1;
$year+=1900;

# overwrite current time via commandline for test purposes
# format is YYYYMMDDhhmm
# starting from the right, only give what you want to change
# eg. '1255' would change time to 12:55 and keep the date
if (defined $ARGV[0]) {
    my $cmdline = $ARGV[0];

    if ($cmdline =~ s/(\d\d)$//) {
	$min = $1;
    }
    if ($cmdline =~ s/(\d\d)$//) {
	$hour = $1;
    }
    if ($cmdline =~ s/(\d\d)$//) {
	$mday = $1;
    }
    if ($cmdline =~ s/(\d\d)$//) {
	$mon = $1;
    }
    if ($cmdline =~ s/(\d\d\d\d)$//) {
	$year = $1;
    }
    printf "time overwritten as %04d-%02d-%02d %02d:%02d\n", $year, $mon, $mday, $hour, $min;
}

if ($hour < 4) {
    $mday--;
}

my %seen;

sub ttm ($) {
# time to minutes
    if ($_[0] =~ /(\d+):(\d+)/) {
	return ($1*60 + $2);
    }
    return 0;
}

sub search($$$);

sub search($$$) {
# die eigentliche Suche

    my ($saal, $recurse, $offset) = (@_);
    my $found = 0;

    foreach my $day (@{$ref->{day}}) {

	next unless $day->{date} eq "$year-$mon-$mday";

	foreach my $event_id ( keys %{$day->{room}->{$saal}->{event}} ) {

	    my $event = $day->{room}->{$saal}->{event}->{$event_id};

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
		    @persons = map { $_->{content} } values %{$event->{persons}->{person}};
		}

		$seen{$event_id}++; ### WTF HACKS!

		printf("  %sh -> +%sh  %s\n                     [%s]\n\n",
		       $event->{start},
		       $event->{duration},
		       encode_utf8($event->{title}),
		       encode_utf8(join (', ', @persons))
		    );
		$found++;

		if ($recurse) {
		    $offset = $offset + ttm($event->{duration});
		    search($saal, 0, $offset);
		}
	    }

	}

    }

    return $found;
}

foreach my $saal ('Ada', 'Borg', 'Clarke', 'Dijkstra', 'Eliza') {
    print "$saal:\n";

    foreach my $lookahead (qw(0 20 40 60 80 100 120 140 160 180)) {
	last if search($saal, 1, $lookahead);
    }
}

if (-e 'schedule_sz') {
    $xml = `cat schedule_sz`;
    $ref = XMLin($xml);

    print "Sendezentrum:\n"; # skip 'Podcaster-Tisch'
    foreach my $saal ("Sendezentrumsb\x{fc}hne", 'Sendezentrumsbühne') { # cheap umlaut encoding hack

	foreach my $lookahead (qw(0 20 40 60 80 100 120 140 160 180)) {
	    last if search($saal, 1, $lookahead);
	}
    }
}
