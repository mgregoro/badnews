# BadNews::Calendar::DateTool
# $Id: DateTool.pm 441 2006-12-11 21:32:47Z corrupt $
# comprises functionality that used to belong to BadNews::CalendarInterface
# specifically the ability to have a date that you can switch around a date and get diminished time values from it!

package BadNews::Calendar::DateTool;

use vars qw(@ISA);

@ISA = qw(BadNews);

use BadNews;
use BadNews::EzDate;
use Carp;

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
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
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
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-01 00:00:00/g;
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

# switch date
sub switch_date {
    my ($self, $dim) = @_;
    $dim =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;
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

# just take the -'s :'s and \s' out!
sub quick_dim {
    my ($self, $date) = @_;
    unless (ref($self) eq "BadNews::CalendarInterface") {
        $date = $self;
    }
    $date =~ s/[-\s:]+//g;
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
