# BadNews::CalendarInterface is the CMS interface to the calendar subsystem.
# $Id: CalendarInterface.pm 441 2006-12-11 21:32:47Z corrupt $
# involved in taking form elements passed back from a web form and preparing them
# to be turned into BadNews::Calendar::Event s.

package BadNews::CalendarInterface;

@ISA = ('BadNews');
use BadNews::EzDate;
use BadNews::Calendar::Event;
use BadNews::Calendar;
use BadNews;
use Carp;

# gotta cache the upcoming events, it's ugly.
our $upcoming_cache = {};

sub setup {
    my ($self) = @_;
    $ezdate = BadNews::EzDate->new();
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{ezdate} = $ezdate;
    return $self;
}

sub refresh {
    my ($self) = @_;
    $self->{weekday} = $self->current_day->{weekdaylong};
    $self->{day} = $self->current_day->{'day of month'};
    $self->{year} = $self->current_day->{year};
    $self->{month_long} = $self->current_day->{monthlong};
    $self->{month} = $self->current_day->{'month number base 1'};
    $self->{hour} = $self->current_day->{ampmhour};
    $self->{min} = $self->current_day->{min};
    $self->{sec} = $self->current_day->{sec};
    my $ezdate = $self->current_day;
    $self->{today} = "$ezdate";
}

# get events happening in the next 60 days
# $upcoming_cache to the rescue!
sub upcoming_events {
    my ($self, $limit) = @_;
    my @events;

    if (exists($upcoming_cache->{$ENV{SERVER_NAME}}->{$limit})) {
        # check to see if the cache is older than c->UPCOMING_EVENTS_CACHE seconds
        if ((time - $upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{age}) > $self->c->UPCOMING_EVENTS_CACHE) {
            # recache and return
            my $dbh = $self->open_db;
            my $days = 60;      # the number of days we have to process

            # set the date object to right now..
            $self->any_to_ezdate;
            until ($days < 0 || scalar(@events) == $limit) {
                my $day = BadNews::Calendar::Day->new($self->dim);
                push(@events, $day->public_events);

                # add a day!
                $self->increment_date(1, 'd');
                --$days;
            }
            $events[$#events]->is_last(1) if scalar(@events);
            $upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{age} = time;
            $upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{value} = \@events;
            return (@events[0...($limit - 1)]);
        } else {
            # return from cache!
            return (@{$upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{value}}[0...($limit - 1)]);
        }
    } else {
        # cache for the first time
        my $dbh = $self->open_db;
        my $days = 60;      # the number of days we have to process

        # set the date object to right now..
        $self->any_to_ezdate;
        until ($days < 0 || scalar(@events) >= $limit) {
            my $day = BadNews::Calendar::Day->new($self->dim);

            push(@events, $day->public_events);

            # add a day!
            $self->increment_date(1, 'd');
            --$days;
        }
        $events[$#events]->is_last(1) if scalar(@events);
        $upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{age} = time;
        $upcoming_cache->{$ENV{SERVER_NAME}}->{$limit}->{value} = \@events;
        return (@events[0...($limit - 1)]);
    }
}

sub count_upcoming_events {
    my ($self, $limit) = @_;
    return scalar($self->upcoming_events($limit));
}

sub day {
    my ($self) = @_;
    return $self->ezdate->{dayofmonth};
}

sub year {
    my ($self) = @_;
    return $self->ezdate->{year};
}

sub month {
    my ($self) = @_;
    return $self->ezdate->{monthnumberbase1};
}

sub month_name {
    my ($self) = @_;
    return $self->ezdate->{monthlong};
}

sub hour {
    my ($self) = @_;
    return $self->ezdate->{ampmhour};
}

sub min {
    my ($self) = @_;
    return $self->ezdate->{min};
}

sub sec {
    my ($self) = @_;
    return $self->ezdate->{sec};
}

sub ampm {
    my ($self) = @_;
    return uc($self->ezdate->{ampm});
}

sub rss_format {
    my ($self, $newdate) = @_;
    $self->switch_date($newdate) if $newdate;
    return $self->ezdate->{year} . '-' . $self->ezdate->{monthnumberbase1} . '-' . $self->ezdate->{dayofmonth} . "T" .
    $self->ezdate->{hour} . ':' . $self->ezdate->{min} . $self->c->RSS_TIMEZONE;
}

sub format_date {
    my ($self, $format) = @_;
    my $ezdate = $self->ezdate;
    my $formatted = "$ezdate->{$format}";
    return $formatted;
}

sub time_short {
    my ($self) = @_;
    return $self->ezdate->{monthnumberbase1} . "/" . $self->ezdate->{dayofmonth} . "/" . $self->ezdate->{yeartwodigits} . " " .
    $self->ezdate->{ampmhour} . ":" . $self->ezdate->{min} . ":" . $self->ezdate->{sec} . " " . uc($self->ezdate->{ampm});
}

sub dim_to_short {
    my ($self, $dim) = @_;
    my $ezdate = $self->dim_to_ezdate($dim);
    return $ezdate->{monthnumberbase1} . "/" . $ezdate->{dayofmonth} . "/" . $ezdate->{yeartwodigits} . " " . $ezdate->{ampmhour} . ":" . $ezdate->{min} . ":" . $ezdate->{sec} . " " . uc($ezdate->{ampm});
}

sub today {
    my ($self) = @_;
    my $ezdate = $self->ezdate;
    return "$ezdate";
}

# next month
sub next_month {
    my ($self) = @_;
    $self->ezdate->next_month(1);
}

# last month
sub last_month {
    my ($self) = @_;
    $self->ezdate->next_month(-1);
}

# weekday
sub weekday {
    my ($self) = @_;
    return $self->ezdate->{weekdaylong};
}

sub days_in_month {
    my ($self) = @_;
    return $self->ezdate->{daysinmonth};
}

# months but this month
sub nmonths {
    my ($self) = @_;
    my @months;
    for (my $i = 1; $i <= 12; $i++) {
        my $month = sprintf('%02d', $i);
        next if $month eq $self->month;
        push (@months, $month);
    }
    return @months;
}

sub next_few_years {
    my ($self) = @_;
    my @years;
    for (my $i = ($self->year + 1); $i <= ($self->year + 6); $i++) {
        push (@years, $i);
    }
    return @years;
}

# days but today
sub ndays {
    my ($self) = @_;
    my @days;
    for (my $i = 1; $i <= $self->days_in_month; $i++) {
        my $day = sprintf('%02d', $i);
        next if $day eq $self->day;
        push (@days, $day);
    }
    return @days;
}

# event type stuff...

sub events_by_type {
    my ($self, $type, $old_events) = @_;
    my $dbh = $self->open_db;
    my ($sth, @events);
    if ($old_events) {
        if ($type && $type !~ /^all$/i) {
            $sth = $dbh->prepare("select id from events where type = " . $dbh->quote($type) . " order by start_time");
        } else {
            $sth = $dbh->prepare("select id from events order by start_time");
        }
    } else {
        if ($type && $type !~ /^all$/i) {
            $sth = $dbh->prepare("select id from events where type = " . $dbh->quote($type) . " && start_time > date_sub(now(), interval 7 day) order by start_time");
        } else {
            $sth = $dbh->prepare("select id from events where start_time > date_sub(now(), interval 7 day) order by start_time");
        }
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }
    $events[$#events]->is_last(1) if scalar(@events);
    return (@events);
}

# for some reason this dissapeared, I hope this is the extent of the "damage"
sub type_exists {
    my ($self, $type) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from event_types where type = " . $dbh->quote($type));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    if ($$ar[0]) {
        return 1;
    }
    return undef;
}

sub add_event_type {
    my ($self, $type, $allow_overlap) = @_;
    unless (($self->type_exists($type)) || ($type =~ /^all$/i)) {
        my $dbh = $self->open_db;
        return $dbh->do("insert into event_types (type, allow_overlap) values (" . $dbh->quote($type) . ", " 
                       . $dbh->quote($allow_overlap) . ")");
    }
    return undef;
}

sub type_allows_overlap {
    my ($self, $type) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select allow_overlap from event_types where type = " . $dbh->quote($type));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return ($$ar[0]);
}

sub delete_event_type {
    my ($self, $type) = @_;
    if ($self->type_exists($type)) {
        my $dbh = $self->open_db;
        return $dbh->do("delete from event_types where type = " . $dbh->quote($type));
    }
    return undef;
}

sub list_event_types {
    my ($self) = @_;
    my @types;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select type from event_types order by type asc");
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@types, $$ar[0]);
    }
    return @types;
}

# event place stuff

sub events_by_place {
    my ($self, $place) = @_;
    my $dbh = $self->open_db;
    my ($sth, @events);
    if ($place && $place !~ /^all$/i) {
        $sth = $dbh->prepare("select id from events where place = " . $dbh->quote($place) . " && start_time > date_sub(now(), interval 7 day) order by start_time");
    } else {
        $sth = $dbh->prepare("select id from events where start_time > date_sub(now(), interval 7 day) order by start_time");
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }
    $events[$#events]->is_last(1) if scalar(@events);
    return (@events);
}

sub add_event_place {
    my ($self, $place, $allow_overlap) = @_;
    unless (($self->place_exists($place)) || ($place =~ /^all$/i)) {
        my $dbh = $self->open_db;
        return $dbh->do("insert into event_places (place, allow_overlap) values (" . $dbh->quote($place) . ", "
                       . $dbh->quote($allow_overlap) . ")");
    }
    return undef;
}

sub place_allows_overlap {
    my ($self, $place) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select allow_overlap from event_places where place = " . $dbh->quote($place));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return ($$ar[0]);
}

sub delete_event_place {
    my ($self, $place) = @_;
    if ($self->place_exists($place)) {
        my $dbh = $self->open_db;
        return $dbh->do("delete from event_places where place = " . $dbh->quote($place));
    }
}

sub place_exists {
    my ($self, $place) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from event_places where place = " . $dbh->quote($place));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    if ($$ar[0]) {
        return 1;
    }
    return undef;
}

sub list_event_places {
    my ($self) = @_;
    my @places;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select place from event_places order by place asc");
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@places, $$ar[0]);
    }
    return @places;
}

sub nhours {
    my ($self) = @_;
    my @hours;
    for (my $i = 1; $i <= 12; $i++) {
        my $hour = sprintf('%02d', $i);
        next if $hour eq $self->hour;
        push(@hours, $hour);
    }
    return @hours;
}

sub months_in_year {
    my ($self) = @_;
    return ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12');
}

sub hours_in_day {
    my ($self) = @_;
    return ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12');
}

sub nmins {
    my ($self) = @_;
    my @minutes;
    for ($i = 0; $i < 60; $i++) {
        my $min = sprintf('%02d', $i);
        next if $min eq $self->min;
        push(@minutes, $min);
    }
    return @minutes;
}

sub minutes_in_hour {
    my ($self) = @_;
    my @minutes;
    for ($i = 0; $i < 60; $i++) {
        push(@minutes, sprintf('%02d', $i));
    }
    return @minutes;
}

sub rmins {
    my ($self) = @_;
    return ('05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55');
}

sub add_hour {
    my ($self) = @_;
    if ($self->ezdate->{hour} == 23) {
        $self->ezdate->{epochday}++;
        $self->ezdate->{hour} = 0;
    } else {
        $self->ezdate->{hour}++;
    }
}

sub add_months {
    my ($self, $months) = @_;
    $months = $months ? $months : 6;
    $self->ezdate->next_month($months);
}

# ezdate is a BadNews::EzDate object ;)
sub ezdate {
    my ($self) = @_;
    return $self->{ezdate};
}

# funky to ezdate
sub funk_to_ezdate {
    my ($self, $funk) = @_;
    my $ezdate = BadNews::EzDate->new($funk);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    return $ezdate;
}

# diminished time to ezdate
sub dim_to_ezdate {
    my ($self, $dim) = @_;
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/og;
    my $ezdate = BadNews::EzDate->new($dim);
    if ($ezdate) {
        $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
        return $ezdate;
    } else {
        return undef;
    }
}

sub switch_to_this_month {
    my ($self) = @_;
    my $ezdate = BadNews::EzDate->new();
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    my $dim = "$ezdate";
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-01 00:00:00/og;
    $ezdate = BadNews::EzDate->new($dim);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{ezdate} = $ezdate;
    return undef;
}

sub dim {
    my ($self) = @_;
    my $ezdate = $self->{ezdate};
    return "$ezdate";
}

# this totally belongs here.
sub increment_date {
    my ($self, $qty, $interval) = @_;

    if ($interval eq "d") {
        # $qty * 1 days!
        $self->ezdate->{epochday} += $qty;
    } elsif ($interval eq "w") {
        # $qty * 7 days!
        $self->ezdate->{epochday} += $qty * 7;
    } elsif ($interval eq "m") {
        # $qty * 1 month!
        $self->add_months($qty);
    } elsif ($interval eq "y") {
        # $qty * 1 year!
        $self->ezdate->{year} += $qty;
    }
}

# returns a list if no arguements are passed of the valid recur intervals
# otherwise it just resolves whatever you pass it to whatever it needs to be
# based on the anonymous hash defined below.
sub recur_intervals {
    my ($self, $interval) = @_;
    my $resolver = {
        day     =>      'Day(s)',
        week    =>      'Week(s)',
        month   =>      'Month(s)',
        d       =>      'day',
        w       =>      'week',
        m       =>      'month'
    };
    if ($interval) {
        return $resolver->{$interval};
    } else {
        return ('day', 'week', 'month');
    }
}

sub check_overlap_by_type {
    my ($self, $start_dim, $type, $recurring_event) = @_;
    my $dbh = $self->open_db;
    my @events;
    my $sth = $dbh->prepare("select id from events where start_time <= $start_dim && end_time > $start_dim && " 
              . "type = " . $dbh->quote($type));

    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }

    # Kriss nor I can come up with a decent (and tolerably efficient) way to project intersections 
    # of possibly infinite date recursion
    if ($recurring_event) {
        push(@events, $self->check_recurring_event_overlap_by_type($start_dim, $type));
    }

    if ($events[0]) {
        return @events;
    } else {
        return undef;
    }
}

sub check_overlap_by_place {
    my ($self, $start_dim, $place, $recurring_event) = @_;
    my $dbh = $self->open_db;
    my @events;
    my $sth = $dbh->prepare("select id from events where start_time <= $start_dim && end_time > $start_dim && "
              . "place = " . $dbh->quote($place));

    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }

    # Kriss nor I can come up with a decent (and tolerably efficient) way to project intersections 
    # of possibly infinite date recursion
    if ($recurring_event) {
        push(@events, $self->check_recurring_event_overlap_by_place($start_dim, $place));
    }

    if ($events[0]) {
        return @events;
    } else {
        return undef;
    }
}

# switch date
sub switch_date {
    my ($self, $dim) = @_;
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/og;
    my $ezdate = BadNews::EzDate->new($dim);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{ezdate} = $ezdate;
}

sub to_start_of_day {
    my ($self) = @_;
    my $dim = $self->dim;
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 00:00:00/og;
    my $ezdate = BadNews::EzDate->new($dim);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{ezdate} = $ezdate;
}

# attempts to convert the date to ezdate
sub any_to_ezdate {
    my ($self, $date) = @_;
    my $ezdate = BadNews::EzDate->new($date);
    if ($ezdate) {
        $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
        $self->{ezdate} = $ezdate;
    } else {
        return undef;
    }
}

# project this event's recur dates..
sub project_recur_dates {
    my ($self, $event) = @_;

    # only handle a recurring event!
    unless ($event->{recurring_event}) {
        return undef;
    }

    my $dbh = $self->open_db;

    my ($qty, $interval) = $event->{recur_interval} =~ /^(\d+)([A-Za-z])$/o;
    my $i = 0;

    # we aren't using BadNews::Calendar::Event's accessor methods to get at this data, so it wont come back in 
    # diminished time.  I have no idea why I did it this way.  I feel bad about it.
    my $start_time = $self->quick_dim($event->{start_time});
    my $end_time = $self->quick_dim($event->{end_time});
    my $time_difference = $end_time - $start_time;

    $self->switch_date($start_time);
    my $today_dim = $self->dim;
    my $tomorrow_dim;

    if ($event->{recur_until} > 0) {
        $tomorrow_dim = $self->quick_dim($event->{recur_until});
    } else {
        # 20050101000000
        #    50000000000 = 5 years baby!
        $tomorrow_dim = ($start_time + $self->c->MAX_RECUR_UNTIL * 10000000000);
    }

    my @recur_dates;

    for (my $event_start_dim = $self->dim; $self->dim < $tomorrow_dim; $self->increment_date($qty, $interval)) {
        $event_start_dim = $self->dim;

        if ($event_start_dim >= $today_dim && $event_start_dim <= $tomorrow_dim) {
            # this event starts today at event_start_dim, lets find the end time
            my $event_end_dim = $event_start_dim + $time_difference; 

            # create the recurring event object
            push(@recur_dates, {
                start_time      =>      $event_start_dim,
                end_time        =>      $event_end_dim,
                recur_number    =>      $i,
            });
            $self->switch_date($event_start_dim);
        }
        ++$i;
    } 
    return (@recur_dates);
}

sub check_recurring_event_overlap_by_type {
    my ($self, $start_dim, $type) = @_;
    my @events;

    #print "$start_dim\n";

    # prepare the db and query!
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select event_id, start_time, end_time, recur_number from recur_dates where start_time <= $start_dim && end_time > $start_dim && "
              . "type = " . $dbh->quote($type));

    # run the query
    $sth->execute;

    while (my $ar = $sth->fetchrow_arrayref) {
        my $event_start_dim = $self->quick_dim($$ar[1]);
        my $event_end_dim = $self->quick_dim($$ar[2]);
        push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
    }
    
    return @events;
}

sub check_recurring_event_overlap_by_place {
    my ($self, $start_dim, $place) = @_;
    my @events;

    #print "$start_dim\n";

    # prepare the db and query!
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select event_id, start_time, end_time, recur_number from recur_dates where start_time <= $start_dim && end_time > $start_dim && "
              . "place = " . $dbh->quote($place));

    # run the query
    $sth->execute;

    while (my $ar = $sth->fetchrow_arrayref) {
        my $event_start_dim = $self->quick_dim($$ar[1]);
        my $event_end_dim = $self->quick_dim($$ar[2]);
        push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
    }

    return @events;
}

# articles n shite
sub recent_days_with_articles {
    my ($self, $number, $type, $from, $to) = @_;

    # set our CalendarInterface's date to 12:00:01AM this morning
    $self->any_to_ezdate;
    $self->to_start_of_day;

    my @days;
    my $earliest_article_dim = $self->quick_dim($self->earliest_article_date($type)) - 1000000;
    while ($number > scalar(@days) && $self->dim > $earliest_article_dim) {
        my $day = BadNews::Calendar::Day->new($self->dim);
        if ($day->has_articles($type, $from, $to)) {
            push(@days, $day);
        }
        $self->increment_date(-1, 'd');
    }

    return @days;
}

sub earliest_article_date {
    my ($self, $type) = @_;
    $type = "create" unless $type;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select min(" . $type . "_time) from articles where published = '1'");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}

# just take the -'s :'s and \s' out!
sub quick_dim {
    my ($self, $date) = @_;
    unless (ref($self) eq "BadNews::CalendarInterface") {
        $date = $self;
    }
    $date =~ s/[-\s:]+//og;
    return $date;
}

1;
__END__

=head1 COPYRIGHT

BadNews CMS
Copyright 2004-2006 by Michael Gregorowicz
                       the mg2 organization

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

the mg2 organization makes no representations about the suitability of
this software for any purpose. It is provided "as is" without express or
implied warranty.

See http://www.perl.com/perl/misc/Artistic.html

=cut
