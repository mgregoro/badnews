#!/usr/bin/perl
# $Id: citest.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2root/web/bndev.mg2.org/lib');
$ENV{'DOCUMENT_ROOT'} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::CalendarInterface;

my $ci = BadNews::CalendarInterface->new();

my %event = (
    start_time        =>      "20061028030000",
    end_time          =>      "20061028045500",
    coordinator       =>      "Paul",
    place             =>      "home",
    summary           =>      "paul does the laundry",
    description       =>      "paul does the laundry!",
    type              =>      "general",
    recurring_event   =>      1,
    recur_interval    =>      "4d",
    recur_until       =>      "20081028162500",
    show_event        =>      1,
);

foreach $date ($ci->project_recur_dates(\%event)) {
    my @events = $ci->check_overlap($date, $event{type});
    foreach my $event (@events) {
        if (ref($event) eq "BadNews::Calendar::Event") {
            print $event->id . " conflicts!\n";
        }
    }
}

foreach my $event (@conflicting_events) {
    print $event->summary . " conflicts! (" . $event->id . ")\n";
}

#$ci->any_to_ezdate("01/06/2005");

#my $date = sprintf('%02d/%02d/%02d %02d:%02d:%02d %s', $ci->month, $ci->day, $ci->year, $ci->hour, $ci->min, $ci->sec, uc($ci->ampm));

#$ci->add_hour;

#my $date2 = sprintf('%02d/%02d/%d %02d:%02d:%02d %s', $ci->month, $ci->day, $ci->year, $ci->hour, $ci->min, $ci->sec, uc($ci->ampm));

#print "$date\n";
#print "$date2\n";

#my @mih = $ci->minutes_in_hour;

#print "@mih\n";

#my @nh = $ci->nhours;

#print "@nh\n";

#my @events = $ci->events_by_type;

#foreach my $event (@events) {
#    print $event->start_time_short . "\n";
#}

#$ci->add_event_type("your mom");

#print "Hour: " . $ci->hour . "\n";

#$ci->add_hour();

#print $ci->ezdate->{hour} . "\n";

#$ci->switch_to_this_month;

#my $ezdate = $ci->ezdate;

#print "$ezdate\n";

#print "This month...\n";

#print $ci->month_name . "\n";

#print "Next month...\n";

#$ci->next_month;

#print $ci->month_name . "\n";

#print "This month...\n";

#$ci->last_month;

#print $ci->month_name . "\n";

#$ci->add_event_type("test", 1);

#if ($ci->type_allows_overlap("test")) {
#    print "test allows overlap!\n";
#}

#foreach my $event ($ci->check_overlap('20050529100500', 'Birthdays')) {
#    if ($event) {
#        print "Conflict found: " . $event->description . "\n";
#        print $event->start_time . " <=> " . $event->end_time . "\n";
#        print $event->id . "\n";
#    }
#}

#my $ezdate = $ci->funk_to_ezdate("10/15/2004 01:00:00 AM");

#print "$ezdate\n";
