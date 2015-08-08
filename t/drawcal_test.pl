#!/usr/bin/perl
# $Id: drawcal_test.pl 428 2006-08-30 02:00:57Z corrupt $

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';
use lib('/mg2root/web/bndev.mg2.org/lib');

use BadNews::DrawCalendar;
use Data::Dumper;

my $cal = BadNews::DrawCalendar->new($ARGV[0], $ARGV[1]);

my $i = 0;

#foreach my $day ($cal->days) {
#    next if $day == 1;
#    if ($day) {
#        printf ("%2s", $day->single_day);
#    } else {
#        print "  ";
#    }
#    $i++;
#    if ($i == 7 or $i == 14 or $i == 21 or $i == 28 or $i == 35) {
#        print "\n";
#    } else {
#        print " ";
#    }
#}

my @events = $cal->cal->all_public_events('All');

#print Dumper(@events);
print scalar(@events) . "\n";

