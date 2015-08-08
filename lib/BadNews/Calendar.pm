# the BadNews calendar object is made up of Calendar::Day objects.
# $Id: Calendar.pm 441 2006-12-11 21:32:47Z corrupt $
# the attributes it should have are month name.
# the BadNews::Calendar object can either be a week long or a month long

package BadNews::Calendar;

@ISA = ('BadNews');
use BadNews::EzDate;
use BadNews::Calendar::Day;
use BadNews::Calendar::DateTool;
use BadNews::Article;
use BadNews;
use Carp;

our $dt = BadNews::Calendar::DateTool->new();

sub new {
    my ($class, $date) = @_;
    my $self = bless({}, $class);
    $self->setup($date);
    return $self;
}

sub setup {
    my ($self, $date) = @_;
    $date =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/og;
    $ezdate = BadNews::EzDate->new($date);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{this_month} = "$ezdate";
    my $cezdate = $ezdate->clone;
    $cezdate->next_month(1);
    $self->{next_month} = "$cezdate";
    $self->{current_day} = $ezdate;
    $self->{year} = $ezdate->{year};
    $self->{month} = $ezdate->{'month number base 1'};
    $self->{daysinmonth} = $ezdate->{daysinmonth};
}

sub days {
    my ($self) = @_;
    my @days;
    my $cd = $self->current_day->clone();
    #die "Got here: CD: $cd, Day Of Month: $cd->{dayofmonth}, Days In Month: " . $self->days_in_month;
    while ($cd->{'day of month'} <= $self->days_in_month) {
        push (@days, BadNews::Calendar::Day->new("$cd"));
        last if ($cd->{'day of month'} == $self->days_in_month);
        ++$cd->{epochday};
    }
    #die "Got here: CD: $cd, Day Of Month: $cd->{dayofmonth}, Days In Month: " . $self->days_in_month;
    return @days;
}

sub articles {
    my ($self, $type, $to, $from) = @_;
    $type = "create" unless $type;
    my $from_date = $self->this_month;
    my $to_date = $self->next_month;
    my $dbh = $self->open_db;
    my @articles;
    my $sth;
    if ($from) {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $from, $to");
    } elsif ($to) {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $to");
    } else {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc");
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }
    $articles[$#articles]->is_last(1) if scalar(@articles);
    return (@articles);
}

sub has_articles {
    my ($self, $type, $to, $from) = @_;
    $type = "create" unless $type;
    my $from_date = $self->this_month;
    my $to_date = $self->next_month;
    my $dbh = $self->open_db;
    my @articles;
    my $sth;
    if ($from) {
        $sth = $dbh->prepare("select count(id) from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $from, $to");
    } elsif ($to) {
        $sth = $dbh->prepare("select count(id) from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $to");
    } else {
        $sth = $dbh->prepare("select count(id) from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc");
    }
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}


sub all_public_events {
    my ($self, $type, $l_start, $l_rows) = @_;

    my $dbh = $self->open_db;

    if ($l_start && $l_rows) {
        $limit = "limit $l_start, $l_rows";
    } elsif ($l_start) {
        $limit = "limit $l_start";
    }

    if ($type && $type !~ /^all$/i) {
        #$sth = $dbh->prepare("select id, type, description, summary, start_time, end_time, place, show_event, modify_time from events where show_event = '1' && type = " . $dbh->quote($type) . " && (start_time >= " . $dbh->quote($self->this_month) . " && start_time < " . $dbh->quote($self->next_month) . ") order by start_time asc");
        $sth = $dbh->prepare("select id from events where show_event = '1' && type = " . $dbh->quote($type) . " && recurring_event = '0' && (start_time >= " . $dbh->quote($self->this_month) . " && start_time < " . $dbh->quote($self->next_month) . ") order by start_time asc $limit");
    } else {
        #$sth = $dbh->prepare("select id, type, description, summary, start_time, end_time, place, show_event, modify_time from events where show_event = '1' && start_time >= " . $dbh->quote($self->this_month) . " && start_time < " . $dbh->quote($self->next_month) . " order by start_time asc");
        $sth = $dbh->prepare("select id from events where show_event = '1' && recurring_event = '0' && start_time >= " . $dbh->quote($self->this_month) . " && start_time < " . $dbh->quote($self->next_month) . " order by start_time asc $limit");
    }
    $sth->execute;
    my @events;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }

    push(@events, $self->recurring_events($type));

    # this really didn't increase performance much
    #while (my $hr = $sth->fetchrow_hashref) {
    #    push(@events, BadNews::Calendar::Event->objectify($hr));
    #}

    @events = sort {$a->start_time <=> $b->start_time} @events;
    return @events;
}

# this should only be run on public events .. since the recurring events aren't actually multiple events
# just ONE event that occurs many times..
sub recurring_events {
    my ($self, $type) = @_;
    my $dbh = $self->open_db;
    my $sth;

    my @events;

    if ($type && $type !~ /^all$/i) {
        $sth = $dbh->prepare("select id, start_time, end_time, recur_interval, recur_until "
                            . "from events where show_event = '1' && type = " . $dbh->quote($type)
                            . " && recurring_event = '1' && (recur_until > $self->{this_month} || recur_until = 00000000000000)");
    } else {
        $sth = $dbh->prepare("select id, start_time, end_time, recur_interval, recur_until "
                            . "from events where show_event = '1' && recurring_event = '1' && " 
                            . "(recur_until > $self->{this_month} || recur_until = 00000000000000)");
    }
    $sth->execute();

    while (my $ar = $sth->fetchrow_arrayref) {
        # get the diminished version of recur_until.
        my $recur_until = $self->quick_dim($$ar[4]);
        my $time_difference = $self->quick_dim($$ar[2]) - $self->quick_dim($$ar[1]);

        $dt->any_to_ezdate($$ar[1]);
        my ($qty, $interval) = $$ar[3] =~ /^(\d+)([A-Za-z])$/o;
        my $i = 0;

        # i mean today and tomorrow in the figurative sense here. sorry for being so lazy mikey in the future.
        my ($today_dim, $tomorrow_dim) = ($self->{this_month}, $self->{next_month});

        # interate through all possible dates up to today.
        for (my $event_start_dim = $dt->dim; $dt->dim < $tomorrow_dim; $dt->increment_date($qty, $interval)) {
            last unless $interval && $qty;
            $event_start_dim = $dt->dim;

            #print "TODAY_DIM: $today_dim\n";
            #print "START_DIM: $event_start_dim\n";
            #print "TMORO_DIM: $tomorrow_dim\n\n";

            if ($event_start_dim >= $today_dim && $event_start_dim <= $tomorrow_dim) {
                # this event starts today at event_start_dim, lets find the end time
                my $event_end_dim = $event_start_dim + $time_difference;

                # create the recurring event object
                if ($recur_until > 0) {
                    if ($event_start_dim <= $recur_until) {
                        push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
                    }
                } else {
                    push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
                }
                $dt->increment_date($qty, $inverval);
            }
            ++$i;
        }
    }
    return @events;
}

sub day_of_week {
    my ($self) = @_;
    return $self->current_day->{weekdaynumber};
}

sub days_in_month {
    my ($self) = @_;
    return $self->{daysinmonth};
}

sub current_day {
    my ($self) = @_;
    return $self->{current_day};
}

sub year {
    my ($self) = @_;
    return $self->{year};
}

sub month {
    my $self = @_;
    return $self->{month};
}

sub next_month {
    my ($self) = @_;
    return $self->{next_month};
}

sub this_month {
    my ($self) = @_;
    return $self->{this_month};
}

# just take the -'s :'s and \s' out!
sub quick_dim {
    my ($self, $date) = @_;
    unless (ref($self) eq "BadNews::Calendar") {
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
