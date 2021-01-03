#!/usr/bin/env perl
use strict;
use warnings;

use JSON::MaybeXS qw(encode_json decode_json);

sub keepkeys {
    my $ref = shift;
    my %keep = map { $_ => 1 } @_;

    delete $ref->{$_} foreach grep { ! exists $keep{$_} } keys %{$ref};
}

$/ = undef;
my $in = decode_json(<>);

my $conference = $in->{schedule}->{conference};
keepkeys($conference, qw(title days));

for my $day (@{$conference->{days}}) {
    keepkeys($day, qw(rooms date));

    for my $room (values %{$day->{rooms}}) {
	for my $event (@{$room}) {
	    keepkeys($event, qw(id start duration persons title));

	    for my $person (@{$event->{persons}}) {
		keepkeys($person, qw(public_name));
	    }
	}
    }
}

my $out->{schedule}->{conference} = $conference;
print encode_json($out);
