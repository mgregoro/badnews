# objects that populate the calendar object.  they have attributes like date,
# $Id: Day.pm 441 2006-12-11 21:32:47Z corrupt $
# holiday, etc.

package BadNews::Calendar::Day;

@ISA = ('BadNews');

use BadNews::EzDate;
use BadNews::Calendar::Event;
use BadNews::CalendarInterface;
use BadNews::Calendar::DateTool;
use BadNews::Article;
use Carp;

our $dt = BadNews::Calendar::DateTool->new();

sub new {
    my ($class, $date) = @_;
    my $self = bless({}, $class);
    $self->{today} = $date;
    $self->setup;
    return $self;
}

# this should retrieve all events, recurring or not!
sub events {
    my ($self, $type, $l_start, $l_rows) = @_;
    my $dbh = $self->open_db;
    my ($sth, $limit);

    if ($l_start && $l_rows) {
        $limit = "limit $l_start, $l_rows";
    } elsif ($l_start) {
        $limit = "limit $l_start";
    }

    if ($type && $type !~ /^all$/i) {
        $sth = $dbh->prepare("select id from events where type = " . $dbh->quote($type) . " && (start_time >= " . $dbh->quote($self->today) . " && start_time < " . $dbh->quote($self->tomorrow) . ") $limit");
    } else {
        $sth = $dbh->prepare("select id from events where start_time >= " . $dbh->quote($self->today) . " && start_time < " . $dbh->quote($self->tomorrow) . $limit);
    }
    $sth->execute();
    my @events;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }

    return @events;
}

sub articles {
    my ($self, $type, $to, $from) = @_;
    $type = "create" unless $type;
    my $from_date = $self->today;
    my $to_date = $self->tomorrow;
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
    my $from_date = $self->today;
    my $to_date = $self->tomorrow;
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

sub public_events {
    my ($self, $type, $l_start, $l_rows) = @_;
    my $dbh = $self->open_db;
    my ($sth, $limit);

    if ($l_start && $l_rows) {
        $limit = "limit $l_start, $l_rows";
    } elsif ($l_start) {
        $limit = "limit $l_start";
    }

    if ($type && $type !~ /^all$/i) {
        $sth = $dbh->prepare("select id from events where show_event = '1' && recurring_event = '0' && type = " . $dbh->quote($type) . " && (start_time >= " . $dbh->quote($self->today) . " && start_time < " . $dbh->quote($self->tomorrow) . ") $limit");
    } else {
        $sth = $dbh->prepare("select id from events where show_event = '1' && recurring_event = '0' && start_time >= " . $dbh->quote($self->today) . " && start_time < " . $dbh->quote($self->tomorrow) . $limit);
    }
    $sth->execute();
    my @events;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@events, BadNews::Calendar::Event->open($$ar[0]));
    }

    # now get the recurring events
    push(@events, $self->recurring_events($type));

    return sort {$a->start_time <=> $b->start_time} @events;
}

# this should only be run on public events .. since the recurring events aren't actually multiple events
# just ONE event that occurs many times..
sub recurring_events {
    my ($self, $type) = @_;
    my $dbh = $self->open_db;
    my $sth;

    my @events;

    if ($type && $type !~ /^all$/i) {
        $sth = $dbh->prepare("select id, start_time, end_time, recur_interval from events where show_event = '1' && type = " . $dbh->quote($type) . " && recurring_event = '1' && (recur_until > $self->{today} || recur_until = 00000000000000)");
    } else {
        $sth = $dbh->prepare("select id, start_time, end_time, recur_interval from events where show_event = '1' && recurring_event = '1' && (recur_until > $self->{today} || recur_until = 00000000000000)");
    }
    $sth->execute();

    while (my $ar = $sth->fetchrow_arrayref) {
        $dt->any_to_ezdate($$ar[1]);
        my $time_difference = $self->quick_dim($$ar[2]) - $self->quick_dim($$ar[1]);
        my ($qty, $interval) = $$ar[3] =~ /^(\d+)([A-Za-z])$/o;
        my $i = 0;

        my ($today_dim, $tomorrow_dim) = ($self->{today}, $self->{tomorrow});

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
                push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
                $dt->increment_date($qty, $interval);
            }
            ++$i;
        }
    }
    return @events;
}


sub setup {
    my ($self) = @_;
    $date = $self->today;
    $date =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/og;
    $ezdate = BadNews::EzDate->new($date);
    $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $self->{current_day} = $ezdate->clone();
    $self->{weekday} = $ezdate->{weekdaylong};
    $self->{day} = $ezdate->{'day of month'};
    $self->{year} = $ezdate->{year};
    $self->{month_long} = $ezdate->{monthlong};
    $self->{month} = $ezdate->{monthnumberbase1};
    $ezdate->{epochday}++;
    $self->{tomorrow} = "$ezdate";
}

sub single_day {
    my ($self) = @_;
    return sprintf('%d', $self->day);
}

sub current_day {
    my ($self) = @_;
    return $self->{current_day};
}

sub month_long {
    my ($self) = @_;
    return $self->{month_long};
}

sub today {
    my ($self) = @_;
    return $self->{today};
}

# lets you know if the day this object represents is today.
sub is_today {
    my ($self) = @_;
    my $ezdate = BadNews::EzDate->new("12:00AM");
    my $cd = $self->current_day;
    return 1 if $ezdate->{epochday} == $cd->{epochday}; #($cd->{epochday} + 1);
}

sub tomorrow {
    my ($self) = @_;
    return $self->{tomorrow};
}

sub weekday {
    my ($self) = @_;
    return $self->{weekday};
}

sub day {
    my ($self) = @_;
    return $self->{day};
}

sub year {
    my ($self) = @_;
    return $self->{year};
}

sub month {
    my ($self) = @_;
    return $self->{month};
}

# just take the -'s :'s and \s' out!
sub quick_dim {
    my ($self, $date) = @_;
    unless (ref($self) eq "BadNews::Calendar::Day") {
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
