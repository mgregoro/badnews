#!/usr/bin/perl

use Data::ICal;

my $ical = Data::ICal->new(filename =>  'my_calendar.ics');

foreach my $e (@{$ical->entries}) {
    if (ref($e) eq "Data::ICal::Entry::Event") {
        my $entry_data = $e->properties;
        print "EVENT:\n";
        foreach my $key (keys %$entry_data) {
            print $key . "\n";
            my $values = $entry_data->{$key};
            foreach my $v (@$values) {
                print "\t" . $v->value . "\n";
            }
        }
        print "\n\n";
    }
}

print "\n";
