#!/usr/bin/perl
# $Id: cal_test.pl 428 2006-08-30 02:00:57Z corrupt $

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use lib('/mg2root/web/bndev.mg2.org/lib');
use BadNews::Calendar;

my $cal = BadNews::Calendar->new("11-1-05");

my @days = $cal->days;

foreach my $day (@days) {
    @events = $day->public_events;
    foreach my $event (@events) {
        print "Start: " . $event->start_day . " at " . $event->start_hms . "\n";
        print "End  : " . $event->end_day . " at " . $event->end_hms . "\n";
        print "Desc : " . $event->description . "\n";
        print "Place: " . $event->place . "\n";
        print "\n";
    }
}
