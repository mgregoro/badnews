#!/usr/bin/perl
# $Id: ical_test.pl 428 2006-08-30 02:00:57Z corrupt $
use lib ('/mg2root/web/bndev.mg2.org/lib');
$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::Calendar::ICal;

my $ical = BadNews::Calendar::ICal->new(filename => '/tmp/my_calendar.ics');

use Data::Dumper;

print Dumper($ical);

exit();

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

