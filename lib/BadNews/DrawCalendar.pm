# takes a BadNews::Calendar object and renders it into html
# $Id: DrawCalendar.pm 441 2006-12-11 21:32:47Z corrupt $
# ok so not quite.. but it at least provides some convienience methods to help!

package BadNews::DrawCalendar;

@ISA = ('BadNews');
use BadNews;
use BadNews::Calendar;
use Carp;

sub new {
    my ($class, $month, $year) = @_;
    my $self = bless({}, $class);
    my @cal_array;
    $self->{cal} = BadNews::Calendar->new(this_month($month, $year));
    my $dow = $self->cal->day_of_week;
    my @days_in_month = $self->cal->days;
    for ($i = 0; $i < 35; $i++) {
        if ($i == $dow) {
            push(@cal_array, @days_in_month);
            $i += scalar(@days_in_month);
        } else {
            push(@cal_array, undef);
        }
    }
    $self->{cal_array} = \@cal_array;
    return $self;
}

sub days {
    my ($self) = @_;
    return (1, @{$self->{cal_array}});
}

sub month {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    return $ezdate->{monthlong};
}

sub year {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    return $ezdate->{year};
}

sub last_month {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    $ezdate->next_month(-1);
    return $ezdate->{monthnumberbase1};
}

sub last_month_year {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    $ezdate->next_month(-1);
    return $ezdate->{year};
}

sub next_month {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    $ezdate->next_month(1);
    return $ezdate->{monthnumberbase1};
}

sub next_month_year {
    my ($self) = @_;
    my $ezdate = $self->cal->current_day->clone();
    $ezdate->next_month(1);
    return $ezdate->{year};
}

sub cal {
    my ($self) = @_;
    return $self->{cal};
}

sub this_month {
    my ($self, $month, $year) = @_;
    unless (ref($self) eq "BadNews::DrawCalendar") {
        $year = $month;
        $month = $self;
    }
    my @time = localtime(time);

    # make sure the month has a leading zero
    $month = sprintf('%02d', $month) if $month;

    $time[5] += 1900;
    $time[4] = sprintf('%02d', $time[4] + 1);

    # let's simplify this...
    if ($year && $month) {
        return "$year$month" . "01000000";
    } elsif ($year) {
        return "$year$time[4]01000000";
    } elsif ($month) {
        return "$time[5]$month" . "01000000";
    } else {
        return "$time[5]$time[4]01000000";
    }
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
