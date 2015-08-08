# the user perl module for BadNews... defines users opens users authenticates users...
# $Id: User.pm 441 2006-12-11 21:32:47Z corrupt $
#

package BadNews::User;

@ISA = ('BadNews');
use BadNews;
use Carp;

sub new {
    my ($class, %user) = @_;
    my $self = bless(\%user, $class);
    if ($self->username && $self->{password}) {
        if ($self->user_exists($self->username)) {
            return "user " . $self->username . " already exists! pick a new name!";
        }
        # we have enough for a new user!
        my $dbh = $self->open_db;
        $self->{common_name} = $self->{common_name} ? $self->{common_name} : $self->username;
        $self->{extended_attributes} = $self->{extended_attributes} ? $self->{extended_attributes} : 0;

        $dbh->do("insert into users (username, password, common_name, create_time, extended_attributes) VALUES (" . 
            $dbh->quote($self->username) . ", " . "md5(" . $dbh->quote($self->{password}) . "), " .
            $dbh->quote($self->common_name) . ", now(), " . $dbh->quote($self->extended_attributes) . ")");

        $self->{id} = $dbh->{mysql_insertid};
        if ($self->extended_attributes) {
            # if we have extended attributes, we should add them..
            foreach my $key (keys %$self) {
                # ignore if the key is one of our reserved methods or attributes...
                if ($key eq "username"        ||      $key eq "password"          ||      $key eq "common_name"       ||
                    $key eq "create_time"     ||      $key eq "extended_attributes" ||    $key eq "modify_time"
                ) {
                    next;
                # or if the key is some internal data like _extended_attributes..
                } elsif ($key =~ /^_/) {
                    next;
                }

                # otherwise... call the autoloader on this extended attribute
                $self->$key($self->{$key});
            }
        }

        # return a shiny new object to clear up confusion.. (but im still confused, mikey :()
        return BadNews::User->open($self->id);
    } else {
        croak "can't create user without username and password!";
    }
}

sub user_exists {
    my ($self, $username) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from users where username = " . $dbh->quote($username));
    $sth->execute();
    my $ar = $sth->fetchrow_arrayref;
    return 1 if $$ar[0];
    return undef;
}

sub open_by_name {
    my ($class, $username) = @_;
    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select id, username, common_name, create_time, modify_time, flags, extended_attributes from users where username = " . $dbh->quote($username));
    $sth->execute();

    my $hr = $sth->fetchrow_hashref;
    return undef unless $hr;

    foreach my $key (keys %$hr) {
        if ($key eq "flags") {
            $self->{$key} = [ split(/,/, $$hr{$key}) ];
        } else {
            $self->{$key} = $hr->{$key};
        }
    }
    return $self;
} 

sub open {
    my ($class, $id) = @_;
    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select id, username, common_name, create_time, modify_time, flags, extended_attributes from users where id = $id");
    $sth->execute();

    my $hr = $sth->fetchrow_hashref;
    return undef unless $hr;

    foreach my $key (keys %$hr) {
        if ($key eq "flags") {
            $self->{$key} = [ split(/,/, $$hr{$key}) ];
        } else {
            $self->{$key} = $hr->{$key};
        }
    }
    return $self;
}

sub obj {
    my ($class) = @_;
    my $self = bless({}, $class);
    return $self;
}

sub list {
    my ($class) = @_;
    my $self;

    # just in case im stupid and call you from an object... which i probably will..
    if (ref($class) =~ /BadNews/) {
        $self = $class;
    } else {
        $self = bless({}, $class);
    }

    my $dbh = $self->open_db;

    my @users;

    my $sth = $dbh->prepare("select id from users");
    $sth->execute();

    while (my $ar = $sth->fetchrow_arrayref) {
        push (@users, BadNews::User->open($$ar[0]));
    }

    return @users;
}

sub delete {
    my ($self) = @_;
    my $dbh = $self->open_db;
    $dbh->do("delete from users where id = " . $self->id);
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub authenticate {
    my ($self, $attempt) = @_;
    if ($attempt) {
        my $dbh = $self->open_db;
        my $sth = $dbh->prepare("select password, md5(" . $dbh->quote($attempt) . ") from users where id = " . $self->id);
        $sth->execute;
        my $ar = $sth->fetchrow_arrayref;
        if ($$ar[0] eq $$ar[1]) {
            return 1;
        } else {
            return undef;
        }
    } else {
        return undef;
    }
}

sub change_pass {
    my ($self, $new_pass) = @_;
    if ($new_pass) {
        my $dbh = $self->open_db;
        return $dbh->do("update users set password = md5(" . $dbh->quote($new_pass) . ") where id = " . $self->id);
    }
}

sub common_name {
    my ($self, $common_name) = @_;
    if ($common_name) {
        $self->{common_name} = $common_name;
        my $dbh = $self->open_db;
        $dbh->do("update users set common_name = " . $dbh->quote($common_name) . " where id = " . $self->id);
    }
    return $self->{common_name};
}

sub create_time {
    my ($self) = @_;
    return $self->{create_time};
}

sub username {
    my ($self) = @_;
    return $self->{username};
}

sub remove_flag {
    my ($self, $flag) = @_;
    return undef unless $flag =~ /^[A-Za-z_]{1,32}$/;
    if ($self->has_flag($flag)) {
        my $dbh = $self->open_db;
        my @flags;
        foreach my $fl ($self->flags) {
            push(@flags, $fl) unless $fl eq $flag;
        }
        $self->{flags} = \@flags;
        return $dbh->do("update users set flags = " . $dbh->quote(join(',', @flags)) . " where id = " . $self->id);
    }
    return undef;
}

sub add_flag {
    my ($self, $flag) = @_;
    return undef unless $flag =~ /^[A-Za-z_]{1,32}$/;
    unless ($self->has_flag($flag)) {
        # add the damn flag to the data structure
        push(@{$self->{flags}}, $flag);
        my $dbh = $self->open_db;
        return $dbh->do("update users set flags = " . $dbh->quote(join(',', $self->flags)) . " where id = " . $self->id);
    }
    return undef;
}

sub flags {
    my ($self) = @_;
    return @{$self->{flags}};
}

sub has_flag {
    my ($self, $flag) = @_;
    foreach my $fl ($self->flags) {
        return 1 if $fl eq $flag;
    }
    return undef;
}

sub extended_attributes {
    my ($self, $extended_attributes) = @_;
    if (defined $extended_attributes) {
        my $dbh = $self->open_db;
        $dbh->do("update users set extended_attributes = " . $dbh->quote($extended_attributes) . " where id = " . $self->id);
        $self->{extended_attributes} = $extended_attributes;
        return $extended_attributes;
    }
    if (exists($self->{extended_attributes})) {
        return $self->{extended_attributes};
    } else {
        return undef;
    }
}

sub DESTROY {
    my ($self) = @_;
    $self = {};
    return;
}

sub AUTOLOAD {
    my ($self, $value) = @_;

    return undef unless $self->extended_attributes;

    # the lowercase version of whatever method was called...
    my $option = $AUTOLOAD;
    $option =~ s/^.+::([\w\_]+)$/$1/g;
    $option = lc($option);

    my $attribute_value;

    # cache the query.. 
    if (exists($self->{_extended_attributes}->{$option})) {
        if ($self->{_extended_attributes}->{$option}->{timestamp} + $self->c->USER_EA_CACHE < time) {
            # the cache is expired.. recache.
            my $dbh = $self->open_db;
            my $sth = $dbh->prepare("select attribute_value from user_attributes where user_id = " . $self->id . " && attribute_name = " .
                                 $dbh->quote($option));
            $sth->execute;
            my $ar = $sth->fetchrow_arrayref;
            $attribute_value = $$ar[0];
            $self->{_extended_attributes}->{$option}->{value} = $attribute_value;
            $self->{_extended_attributes}->{$option}->{timestamp} = time;
        } else {
            $attribute_value = $self->{_extended_attributes}->{$option}->{value};
        }
    } else {
        my $dbh = $self->open_db;
        my $sth = $dbh->prepare("select attribute_value from user_attributes where user_id = " . $self->id . " && attribute_name = " .
                    $dbh->quote($option));
        $sth->execute;
        my $ar = $sth->fetchrow_arrayref;
        $attribute_value = $$ar[0];
        $self->{_extended_attributes}->{$option}->{value} = $attribute_value;
        $self->{_extended_attributes}->{$option}->{timestamp} = time;
    }

    if (defined($value)) {
        if (defined $attribute_value) {
            if ($attribute_value ne $value) {
                # update with the new value
                my $dbh = $self->open_db;
                $dbh->do("update user_attributes set attribute_value = " . $dbh->quote($value) . " where user_id = " . $self->id .
                         " && attribute_name = " . $dbh->quote($option));
                $self->{_extended_attributes}->{$option}->{value} = $value;
                $self->{_extended_attributes}->{$option}->{timestamp} = time;
                return $value;
            } else {
                # it's just the same but .. we should still update the timestamp cos it was the same as of this point
                $self->{_extended_attributes}->{$option}->{timestamp} = time;
                return $attribute_value;
            }
        } else {
            # create a new value
            my $dbh = $self->open_db;
            my $sth = $dbh->prepare("insert into user_attributes (user_id, attribute_name, attribute_value, create_time) values (?,?,?,now())");
            $sth->execute($self->id, $option, $value);
            $self->{_extended_attributes}->{$option}->{value} = $value;
            $self->{_extended_attributes}->{$option}->{timestamp} = time;
            return $value;
        }
    } else {
        # regular run of the mill return..
        return $attribute_value;
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

