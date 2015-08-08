#!/usr/bin/perl
# $Id: event_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib ('/mg2root/web/bndev.mg2.org/lib');

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

#use Date::Manip;
use BadNews::Calendar::Event;

#my ($start_date, $end_date) = (UnixDate($ARGV[0], '%Y%m%d%H%M%S'), UnixDate($ARGV[1], '%Y%m%d%H%M%S'));

#my $event = BadNews::Calendar::Event->new(start_time    =>      '20061031030000',
#                                          end_time      =>      '20061031033000',
#                                          summary       =>      "a nice little get together riight..",
#                                          place         =>      "my house",
#                                          recurring_event   =>  '1',
#                                          recur_interval    =>  '3d',
#                                          show_event    =>      '1',
#                                          recur_until   =>      '20081031033000'
#                                      );

#use Data::Dumper;

#my $event = BadNews::Calendar::Event->open(16);

#$event->end_time('20051114093000');

#$event->show_event(f);

#$event->summary("A VIOLENT BRAWL");

#$event->save;

foreach $id (qw(6 7 12 13 29)) {
    my $event = BadNews::Calendar::Event->open($id);
    $event->project_recur_dates;
}

#print $event->start_time_short . "\n";
#print $event->public . "\n";
#print $event->end_time_short . "\n";
#print $event->summary . "\n";
