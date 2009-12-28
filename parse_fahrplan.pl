#!/usr/bin/perl -w
use strict;
use XML::Simple;

my $xml = `wget -qO- http://events.ccc.de/congress/2009/Fahrplan/schedule.de.xml | sed s/00:00/24:00/`;
my $ref = XMLin($xml);

# use Data::Dumper;
# print Dumper($ref);


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#    localtime(time-(60*60*6));
    localtime(time);
$mon+=1;
$year+=1900;

my %seen;

sub ttm ($) {
# time to minutes
    if ($_[0] =~ /(\d+):(\d+)/) {
	return ($1*60 + $2);
    }
    return 0;
}

sub search($$);

sub search($$) {
# die eigentliche Suche

    my ($saal, $offset) = (@_);
    
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
		
		$seen{$event_id}++; ### WTF HACKS!

		print "  $event->{start}h +$event->{duration}  $event->{title}\n";
		
		if ($offset == 0) {
		    $offset = ttm($event->{duration});
		    search($saal, $offset);
		}
	    }
	    
	}
	
    }
}

foreach my $saal qw(Saal1 Saal2 Saal3) {
    print "$saal:\n";
    search($saal, 0);
}
