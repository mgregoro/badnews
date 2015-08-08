# objects that contain event information, time, place, etc.  Talks to the database.
# $Id: Event.pm 441 2006-12-11 21:32:47Z corrupt $

@ISA = ('BadNews');

package BadNews::Calendar::Event;

@ISA = ('BadNews');
use BadNews::Calendar::DateTool;
use BadNews::EzDate;
use BadNews;
use Carp;

# creates a new event
sub new {
    my ($class, %event) = @_;
    my $self = bless(\%event, $class);
    # removed place as a requirement, as iCal imported events won't have a place :(
    if ($self->start_time && $self->end_time && $self->summary) {
        # we have enough for an event!
        $self->{description} = $self->{description} ? $self->{description} : $self->{summary};
        $self->{show_event} = $self->{show_event} ? $self->{show_event} : 0;
        $self->{recur_until} = $self->{recur_until} ? $self->{recur_until} : 0;
        $self->{recurring_event} = $self->{recurring_event} ? $self->{recurring_event} : 0;
        $self->{coordinator} = $self->{coordinator} ? $self->{coordinator} : 'unknown';
        $self->{type} = $self->{type} ? $self->{type} : 'general';

        my $dbh = $self->open_db;

        $dbh->do("insert into events (type, description, summary, start_time, end_time, place, show_event, recurring_event, recur_interval, recur_until, coordinator) VALUES (" .
        $dbh->quote($self->type) . ", " . $dbh->quote($self->description) . ", " . $dbh->quote($self->summary) . ", " .
        $dbh->quote($self->start_time) . ", " . $dbh->quote($self->end_time) . ", " . $dbh->quote($self->place) . ", " .
        $dbh->quote($self->show_event) . ", " . $dbh->quote($self->recurring_event) . ", " . $dbh->quote($self->recur_interval) . ", " . 
        $dbh->quote($self->recur_until) . ", " . $dbh->quote($self->coordinator) . ")");

        $self->{id} = $dbh->{mysql_insertid};
        if ($self->recurring_event) {
            $self->project_recur_dates;
        }

        return BadNews::Calendar::Event->open($self->id);
    } else {
        croak "start_time, end_time, summary, and place are all required to create an event.";
    }
}

sub open {
    my ($class, $passed_id) = @_;
    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my ($id, $start_dim, $end_dim);
    if ($passed_id =~ /^(\d+):(\d+):(\d+)$/) {
        ($id, $start_dim, $end_dim) = ($1, $2, $3);
    } else {
        $id = $passed_id;
    }

    my $sth = $dbh->prepare("select id, type, description, summary, start_time, end_time, place, show_event, modify_time, recurring_event, recur_interval, recur_until, coordinator from events where id = $id");
    $sth->execute();

    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    foreach my $key (keys %$hr) {
        $self->{$key} = $hr->{$key};
    }

    if ($start_dim) {
        $self->{start_ezdate} = $self->dim_to_ezdate($start_dim);
        $self->start_time($start_dim);
    } else {
        $self->{start_ezdate} = BadNews::EzDate->new($self->{start_time});
    }

    if ($end_dim) {
        $self->{end_ezdate} = $self->dim_to_ezdate($end_dim);
        $self->end_time($end_dim);
    } else {
        $self->{end_ezdate} = BadNews::EzDate->new($self->{end_time});
    }

    $self->{recur_ezdate} = BadNews::EzDate->new($self->{recur_until}) if $self->{recur_until} > 0;

    $self->{id} = $passed_id;

    return $self;
}

sub objectify {
    my ($class, $hr) = @_;
    my $self = bless($hr, $class);

    $self->{start_ezdate} = BadNews::EzDate->new($self->{start_time});
    $self->{end_ezdate} = BadNews::EzDate->new($self->{end_time});
    return $self;
}

sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;

    if ($self->recurring_event) {
        $self->project_recur_dates;
    }

    my $sql = "update events set ";
    my @attribs = ('type', 'description', 'summary', 'start_time', 'end_time', 'place', 'show_event', 'recurring_event', 'recur_interval', 'recur_until', 'coordinator');
    my $i;

    my ($id);
    if ($self->id =~ /^(\d+):(\d+):(\d+)$/) {
        $id = $1;
    } else {
        $id = $self->id;
    }

    foreach my $attr (@attribs) {
        ++$i;
        if ($i == scalar(@attribs)) {
            $sql .= "$attr = " . $dbh->quote($self->$attr);
        } else {
            $sql .= "$attr = " . $dbh->quote($self->$attr) . ", ";
        }
    }
    $sql .= " where id = " . $id;

    $dbh->do($sql);

    $self->refresh_ezdates;
}

sub refresh_ezdates {
    my ($self) = @_;
    $self->{start_ezdate} = BadNews::EzDate->new($self->{start_time});
    $self->{end_ezdate} = BadNews::EzDate->new($self->{end_time});
    $self->{recur_ezdate} = BadNews::EzDate->new($self->{recur_until}) if $self->{recur_until} > 0;
}

sub sd {
    my ($self) = @_;
    return $self->{start_ezdate};
}

sub ed {
    my ($self) = @_;
    return $self->{end_ezdate};
}

sub rd {
    my ($self) = @_;
    return $self->{recur_ezdate};
}

sub start_time_short {
    my ($self) = @_;
    return $self->sd->{monthnumberbase1} . "/" . $self->sd->{dayofmonth} . "/" . $self->sd->{yeartwodigits} . " " .
    $self->sd->{ampmhour} . ":" . $self->sd->{min} . ":" . $self->sd->{sec} . " " . uc($self->sd->{ampm});
}

sub end_time_short {
    my ($self) = @_;
    return $self->ed->{monthnumberbase1} . "/" . $self->ed->{dayofmonth} . "/" . $self->ed->{yeartwodigits} . " " .
    $self->ed->{ampmhour} . ":" . $self->ed->{min} . ":" . $self->ed->{sec} . " " . uc($self->ed->{ampm});
}

sub start_day {
    my ($self) = @_;
    return $self->sd->{weekdaylong} . ", " . $self->sd->{monthlong} . " " . $self->sd->{dayofmonth} . " " . $self->sd->{year};
}

sub end_day {
    my ($self) = @_;
    return $self->ed->{weekdaylong} . ", " . $self->ed->{monthlong} . " " . $self->ed->{dayofmonth} . " " . $self->ed->{year};
}

sub start_hms {
    my ($self) = @_;
    return $self->sd->{ampmhour} . ":" . $self->sd->{min} . ":" . $self->sd->{sec} . " " . uc($self->sd->{ampm});
}

sub end_hms {
    my ($self) = @_;
    return $self->ed->{ampmhour} . ":" . $self->ed->{min} . ":" . $self->ed->{sec} . " " . uc($self->ed->{ampm});
}

sub recur_time_short {
    my ($self) = @_;
    return $self->rd->{monthnumberbase1} . "/" . $self->rd->{dayofmonth} . "/" . $self->rd->{yeartwodigits} . " " .
    $self->rd->{ampmhour} . ":" . $self->rd->{min} . ":" . $self->rd->{sec} . " " . uc($self->rd->{ampm});
}

sub recur_day {
    my ($self) = @_;
    return $self->rd->{weekdaylong} . ", " . $self->rd->{monthlong} . " " . $self->rd->{dayofmonth} . " " . $self->rd->{year};
}

sub recur_hms {
    my ($self) = @_;
    return $self->rd->{ampmhour} . ":" . $self->rd->{min} . ":" . $self->rd->{sec} . " " . uc($self->rd->{ampm});
}


sub delete {
    my ($self) = @_;
    my $dbh = $self->open_db;
    $dbh->do("delete from recur_dates where event_id = " . $self->id);
    $dbh->do("delete from events where id = " . $self->id);
} 

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub type {
    my $self = shift;
    if ($_[0]) {
        $self->{type} = $_[0];
    }
    return $self->{type};
}

sub description {
    my $self = shift;
    if (scalar(@_)) {
        $self->{description} = $_[0];
    }
    return $self->{description};
}

sub is_last {
    my $self = shift;
    if (scalar(@_)) {
        $self->{is_last} = $_[0];
    }
    return ($self->{is_last});
}

sub show_event {
    my $self = shift;
    # could be an untrue value!
    if (scalar(@_)) {
        $self->{show_event} = $_[0];
    }
    return $self->{show_event};
}

sub public {
    my ($self) = @_;
    if ($self->{show_event}) {
        return "Yes";
    } else {
        return "No";
    }
}

sub start_time {
    my $self = shift;
    if ($_[0]) {
        $self->{start_time} = $_[0];
        $self->{start_time} =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
    }
    my $pre_ret = $self->{start_time};
    $pre_ret =~ s/[\-\:\s]+//g;
    return $pre_ret;
}

sub end_time {
    my $self = shift;
    if ($_[0]) {
        $self->{end_time} = $_[0];
        $self->{end_time} =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
    }
    my $pre_ret = $self->{end_time};
    $pre_ret =~ s/[\-\:\s]+//g;
    return $pre_ret;
}

sub summary {
    my $self = shift;
    if ($_[0]) {
        $self->{summary} = $_[0];
    }
    return $self->{summary};
}

sub place {
    my $self = shift;
    if ($_[0]) {
        $self->{place} = $_[0];
    }
    return $self->{place};
}

sub projected_dates {
    my ($self, $pd) = @_;
    if ($pd) {
        $self->{projected_dates} = $pd;
    }
    return $self->{projected_dates};
}

sub coordinator {
    my ($self, $coordinator) = @_;
    if ($coordinator) {
        $self->{coordinator} = $coordinator;
    }
    return $self->{coordinator};
}

# recurring subs!
sub recurring_event {
    my ($self, $re) = @_;
    if (defined($re)) {
        $self->{recurring_event} = $re;
    }
    return $self->{recurring_event};
}

sub recur_interval_split {
    my ($self) = @_;
    $ri = $self->recur_interval;
    if ($ri =~ /^(\d+)(\w)$/) {
        if ($1) {
            return ($1, $2);
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

sub recur_interval {
    my ($self, $ri) = @_;
    if (defined($ri)) {
        $self->{recur_interval} = $ri;
    }
    return $self->{recur_interval};
}

sub recur_until {
    my $self = shift;
    if ($_[0]) {
        $self->{recur_until} = $_[0];
        $self->{recur_until} =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
    }
    my $pre_ret = $self->{recur_until};
    $pre_ret =~ s/[\-\:\s]+//g;
    return $pre_ret;
}

# diminished time to ezdate
sub dim_to_ezdate {
    my ($self, $dim) = @_;
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
    my $ezdate = BadNews::EzDate->new($dim);
    if ($ezdate) {
        $ezdate->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
        return $ezdate;
    } else {
        return undef;
    }
}

# project this event's recur dates..
sub project_recur_dates {
    my ($self) = @_;

    # only handle a recurring event!
    unless ($self->recurring_event) {
        return undef;
    }

    my $dbh = $self->open_db;

    # clear out any references to this event in the recur_dates table, as we're re-computing them!
    $dbh->do("delete from recur_dates where event_id = " . $dbh->quote($self->id));

    my ($qty, $interval) = $self->recur_interval =~ /^(\d+)([A-Za-z])$/;
    my $i = 0;

    my $dt = BadNews::Calendar::DateTool->new();

    $dt->switch_date($self->start_time);
    my $today_dim = $dt->dim;
    my $tomorrow_dim;

    if ($self->recur_until > 0) {
        $tomorrow_dim = $self->recur_until;
    } else {
        # 20050101000000
        #    50000000000 = 5 years baby!
        $tomorrow_dim = ($self->start_time + $self->c->MAX_RECUR_UNTIL * 10000000000);
    }

    #print "$today_dim, $tomorrow_dim\n\n";

    my $sql; #= "insert into recur_dates (event_id, start_time, end_time, recur_number) VALUES ";
    my @data;

    # check to see if we've already projected the dates..
    if ($self->projected_dates) {
        # if so just insert them into sql!
        foreach my $hr (@{$self->projected_dates}) {
            unless ($sql) {
                $sql = "insert into recur_dates (event_id, start_time, end_time, recur_number, type, place) VALUES (?, ?, ?, ?, ?, ?)";
                push(@data, $self->id, $hr->{start_time}, $hr->{end_time}, $hr->{recur_number}, $self->type, $self->place);
                next;
            }
            $sql .= ", (?, ?, ?, ?, ?, ?)";
            push(@data, $self->id, $hr->{start_time}, $hr->{end_time}, $hr->{recur_number}, $self->type, $self->place);
        }
        my $sth = $dbh->prepare($sql);
        $sth->execute(@data);
        return 1;
    }

    # get the difference between the start time and end time
    my $time_difference = $self->end_time - $self->start_time;

    for (my $event_start_dim = $dt->dim; $dt->dim < $tomorrow_dim; $dt->increment_date($qty, $interval)) {
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
                    unless ($sql) {
                        $sql = "insert into recur_dates (event_id, start_time, end_time, recur_number, type, place) VALUES (?, ?, ?, ?, ?, ?)";
                        push(@data, $self->id, $event_start_dim, $event_end_dim, $i, $self->type, $self->place);
                        $dt->switch_date($event_start_dim);
                        $dt->increment_date($qty, $inverval);
                        ++$i;
                        next;
                    }
                    $sql .= ", (?, ?, ?, ?, ?, ?)";
                    push(@data, $self->id, $event_start_dim, $event_end_dim, $i, $self->type, $self->place);
                    #$dbh->do("insert into recur_dates (event_id, start_time, end_time, recur_number) VALUES (" . $self->id . ", $event_start_dim, $event_end_dim, $i)");
                    #push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
                }
            } else {
                unless ($sql) {
                    $sql = "insert into recur_dates (event_id, start_time, end_time, recur_number, type, place) VALUES (?, ?, ?, ?, ?, ?)";
                    push(@data, $self->id, $event_start_dim, $event_end_dim, $i, $self->type, $self->place);
                    $dt->switch_date($event_start_dim);
                    $dt->increment_date($qty, $inverval);
                    ++$i;
                    next;
                }
                $sql .= ", (?, ?, ?, ?, ?, ?)";
                push(@data, $self->id, $event_start_dim, $event_end_dim, $i, $self->type, $self->place);
                #$dbh->do("insert into recur_dates (event_id, start_time, end_time, recur_number) VALUES (" . $self->id . ", $event_start_dim, $event_end_dim, $i)");
                #push(@events, BadNews::Calendar::Event->open("$$ar[0]:$event_start_dim:$event_end_dim"));
            }
            $dt->switch_date($event_start_dim);
            #$dt->increment_date($qty, $inverval);
        }
        ++$i;
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute(@data);
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
