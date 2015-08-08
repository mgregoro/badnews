#!/usr/bin/perl
# $Id: day_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2root/web/bndev.mg2.org/lib');

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::Calendar::Day;

#my $day = BadNews::Calendar::Day->new('20041031000000');
my $day = BadNews::Calendar::Day->new('20050506000000');

use Data::Dumper;

print Dumper($day);

print $day->is_today . "\n";

#print $day->{month} . "\n";
#print $day->month . "\n";

#my @events = $day->events;

#foreach my $event (@events) {
#    print $event->description . "\n";
#}

