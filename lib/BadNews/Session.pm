# session code for the CMS
# $Id: Session.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::Session;

@ISA = ('BadNews');
our $quiet = 1;

use BadNews;
use BadNews::User;
use Carp;
use BadNews::EzDate;
use DBI;
use Digest::MD5 qw(md5_hex);
use DBD::mysql;

# set the value to be considered
$BadNews::EzDate::overload = 'epoch second';

sub new {
    my ($class, %attribs) = @_;
    my $self = bless (\%attribs, $class);
    if ($self->setup) {
        return $self;
    } else {
        return undef;
    }
}

sub setup {
    my ($self) = @_;

    unless ($self->{session_id} =~ /^[0-9a-f]+$/) {
        unless ($self->{session_id} = $self->new_session_id) {
            return undef;
        }
    }

    $self->get_session_data;
    $self->{data}->{create_time} = $self->now unless $self->create_time;
    if ($self->session_expired) {
        $self->{status} = "expired";
        return $self;
    }
    if ($self->is_active == 1) {
        $self->{status} = "active";
    } else {
        $self->{data}->{is_active} = 1;
        $self->{is_new} = 1;
        $self->{status} = "active";
    }

    if ($self->{is_new}) {
        unless ($self->{User} || $self->{Anon}) {
            warn "Illegal session attempt!\n" unless $quiet;
            return undef;
        }
        if ($self->{User}) {
            if ($self->{Anon}) {
                warn "Both User and Anon specified\n" unless $quiet;
                return undef;
            } else {
                $self->{data}->{user} = $self->{User};
            }
        } else {
            $self->{data}->{user} = 'anonymous';
        }
    }
    
    $self->set_session_data;
    return $self;
}

sub new_session_id {
    my ($self) = @_;
    if ($self->{User}) {
        $user = BadNews::User->open_by_name($self->{User});
        if (!$user) {
            warn "No such user!\n" unless $quiet;
            return undef;
        }
        if ($user->authenticate($self->{Pass})) {
            # we're an authenticated session
            return _rand_md5hex($self->{Pass});
        } else {
            # authentication failed
            warn "Invalid login and password!\n" unless $quiet;
            return undef;
        }
    } elsif ($self->{Anon}) {
        # we're an anonymous session
        return _rand_md5hex('anonymous');
    } 
    warn "Improper session credentials!\n" unless $quiet;
    return undef;
}

sub _rand_md5hex {
    my ($password) = @_;
    $password = substr($_[0], sprintf('%d', rand(length($password))), 4) if ($_[0]);
    my ($r1, $r2, $r3, $r4);
    $r1 = sprintf('%d2', rand(100));
    $r2 = rand($r1);
    $r3 = sprintf('%d2', rand(122580 + $r2));
    $r4 = rand($r3 + $r2);
    return md5_hex("$r1$r2$r3$password$r4");
}

sub session_expired {
    my ($self) = @_;
    my ($ttu, $date, $date_string);
    if (exists($self->{data})) {
        if (exists($self->{data}->{update_time})) {
            $ttu = $self->{data}->{update_time};
        } elsif (exists($self->{data}->{create_time})) {
            $ttu = $self->{data}->{create_time};
        } else {
            $self->close_session;
            return 1;
        }
    } else {
        $self->close_session;
        return 1;
    }
    $ttu =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/g;

    # date math using EzDate
    $date = BadNews::EzDate->new($ttu);
    $date->set_format('default', '{year}{month number base 1}{day of month}{hour}{minute}{second}');
    $date += $self->c->COOKIE_DURATION;
    $date_string = "$date";

    # check if we're expired
    if ($date_string < $self->now) {
        $self->close_session;
        return 1;
    } else {
        return undef;
    }
}

sub status {
    my ($self) = @_;
    return $self->{status};
}

sub is_new {
    my ($self) = @_;
    return $self->{is_new};
}

sub get_session_data {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select name, value from " . $self->c->SESSION_TABLE . " where session_id = " .
            $dbh->quote($self->session_id));
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        $self->{data}->{$$ar[0]} = $$ar[1];
    }
}

sub data {
    my ($self) = @_;
    $self->get_session_data;
    return $self->{data};
}

# modified existing yields '1'
# added new yields '2'
# both yield '3'

sub set_session_data {
    my ($self) = @_;

    # update the update_time
    $self->{data}->{update_time} = $self->now;

    my (@changed, @unchanged, $return, $added_new);
    # get the newest data in case another instance updated this session
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select name, value from " . $self->c->SESSION_TABLE . " where session_id = " .
            $dbh->quote($self->session_id));
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        if (exists($self->{data}->{$$ar[0]})) {
            if ($$ar[1] eq $self->{data}->{$$ar[0]}) {
                push (@unchanged, $$ar[0]);
            } else {
                push (@changed, $$ar[0]);
            }
        }
    }

    # update modified
    if (scalar(@changed) > 0) {
        my $update_prefix = "update " . $self->c->SESSION_TABLE . " set ";
        for ($i = 0; $i <= $#changed; $i++) {
            $update_statement = $update_prefix . "value = " . $dbh->quote($self->{data}->{$changed[$i]})  .
                " where session_id = " . $dbh->quote($self->session_id) . " && name = " . $dbh->quote($changed[$i]);

            $dbh->do($update_statement);

        }
        $return += 1;
    }

    # add new!
    my $insert_prefix = "insert into " . $self->c->SESSION_TABLE . " (session_id, name, value, expire_timestamp) VALUES ";
    foreach my $key (keys %{$self->{data}}) {
        my $is_present;
        foreach my $ele (@changed, @unchanged) {
            $is_present = 1 if $ele eq $key;
        }
        next if $is_present;
        # if it wasn't one of the changed ones.... add it!
        $added_new = 1;
        $dbh->do($insert_prefix . "(" . $dbh->quote($self->session_id) . ", " .
                $dbh->quote($key) . ", " . $dbh->quote($self->{data}->{$key}) . ", date_add(now(), interval " . 
                $self->c->COOKIE_DURATION . " second))");
    }
    delete $self->{data};

    # make sure the session doesn't expire
    $self->refresh_session;

    # clear out all the old sessions
    $self->clear_old_sessions;

    $return += 2 if $added_new;
    return $return;
}

sub refresh_session {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $timestamp_update = "update " . $self->c->SESSION_TABLE . " set expire_timestamp = " .    
            " date_add(now(), interval " . $self->c->COOKIE_DURATION . " second) where session_id = " .
             $dbh->quote($self->session_id);
    $dbh->do($timestamp_update);
    return 1;
}

sub clear_old_sessions {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select session_id from " . $self->c->SESSION_TABLE . " where expire_timestamp < now() group by session_id");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        $dbh->do("delete from " . $self->c->SESSION_TABLE . " where session_id = " . $dbh->quote($$ar[0]));
    }
}
        
sub close_session {
    my ($self) = @_;
    my $dbh = $self->open_db;
    delete $self->{data};
    return $dbh->do("delete from " . $self->c->SESSION_TABLE . " where session_id = " . $dbh->quote($self->session_id));
}

sub session_id {
    my ($self) = @_;
    return $self->{session_id};
}

sub DESTROY {
    my ($self) = @_;
    # here's a good place to put this...
    $self->clear_old_sessions if $self;
    delete $self->{data};

}

sub AUTOLOAD {
    my ($self, $arg) = @_;
    $self->get_session_data;
    our $AUTOLOAD;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://g;
    *$AUTOLOAD = sub () {
        my ($self, $arg) = (@_);
        my $name = $name;
        
        # get data, unless we have the data.
        $self->get_session_data unless exists $self->{data};

        if (defined($arg)) { # if there's an arguement, set our value to it
            if ($arg eq '__clear__') {
                $arg = undef;
                my $dbh = $self->open_db;
                $dbh->do("delete from " . $self->c->SESSION_TABLE . " where (session_id = " . $dbh->quote($self->session_id) . 
                    " && name = " . $dbh->quote($name) . ")");
                delete $self->{data}->{$name};
                $self->set_session_data;
            } else {
                $self->{data}->{$name} = $arg;
                $self->set_session_data;
            }
            return $arg;
        } elsif (exists($self->{data}->{$name})) {
            return $self->{data}->{$name};
        } else {
            return undef;
        }
    };
    goto &$AUTOLOAD; # re-run the routine.
}

sub bnuser {
    my ($self) = @_;
    return BadNews::User->open_by_name($self->user);
}

sub now {
    my $self = shift;
    my @time = localtime(time);
    $time[5] += 1900;
    $time[4] += 1;
    for (my $i = 0; $i < 5; $i++) {
        if ($time[$i] < 10) {
            $time[$i] = "0$time[$i]";
        }
    }
    return ("$time[5]$time[4]$time[3]$time[2]$time[1]$time[0]");
} 

1;

=head1 NAME

BadNews::Session - Mikey G's session clipboard!

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=back

=head1 KNOWN ISSUES
C<mg2::Session> does the wrong thing sometimes.

=over2

* runs set_session_data when the updates via the autoloader are very specific

=back

=head1 AUTHOR

Michael Gregorowicz <michael@gregorowicz.com>

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

