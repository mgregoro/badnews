# responsible for setting and retrieving files to and from the BadNews file
# $Id: File.pm 441 2006-12-11 21:32:47Z corrupt $
# repository.  methods include get() and put() 
# get would require say a file name, and put would require a FileInterface object

package BadNews::File;

@ISA = ('BadNews');
use BadNews::CalendarInterface;
use BadNews;
use Carp;

sub new {
    my ($class, %attribs) = @_;
    my $self = bless(\%attribs, $class);
    $self->put;
    return $self;
}

sub put {
    my ($self) = @_;
    if ($self->{file_name} && $self->{data}) {
        # get rid of path info.. stupid windows browsers
        $self->{file_name} =~ s/^.+(?:\\|\/)([\[\]\w\_\-\(\)\!\@\.]+)$/$1/g;
        $self->{added_date} = 'now()';
        $self->{description} =~ s/[\r\n]+/ /g;
        $self->{description} = "No description given." unless $self->{description};
        return ($self->sql_insert);
    } else {
        croak "Can't create file without file_name and data attributes.";
    }
}

# constructor and populator all in one..
sub open {
    my ($class, $file_name) = @_;
    my $self = bless({}, $class);
    return $self->get($file_name);
}

# constructor and populator all in one..
sub open_by_id {
    my ($class, $id) = @_;
    my $self = bless({}, $class);
    return $self->get_by_id($id);
}

sub get {
    my ($self, $file_name) = @_;
    my $dbh = $self->open_db;

    my $sql = "select id, file_name, file_type, added_date, size, description from files where file_name = " .
              $dbh->quote($file_name);

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my $hr = $sth->fetchrow_hashref;

    # make sure we get something back..
    return undef unless $hr;

    foreach my $key (keys %$hr) {
        $self->{$key} = $hr->{$key};
    }

    if ($self->file_type ne "generic") {
        if ($self->file_type eq "image") {
            my $sth = $dbh->prepare("select height, width, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        } elsif ($self->file_type eq "music") {
           my $sth = $dbh->prepare("select artist, time, album, track, song_name, year, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        } elsif ($self->file_type eq "document") {
            my $sth = $dbh->prepare("select content, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        }
    }
    return $self;
}

sub get_by_id {
    my ($self, $id) = @_;
    my $dbh = $self->open_db;

    my $sql = "select id, file_name, file_type, added_date, size, description from files where id = $id";

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    foreach my $key (keys %$hr) {
        $self->{$key} = $hr->{$key};
    }

    if ($self->file_type ne "generic") {
        if ($self->file_type eq "image") {
            my $sth = $dbh->prepare("select height, width, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        } elsif ($self->file_type eq "music") {
           my $sth = $dbh->prepare("select artist, time, album, track, song_name, year, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        } elsif ($self->file_type eq "document") {
            my $sth = $dbh->prepare("select content, media_type from files_data where id = " . $self->id);
            $sth->execute();
            my $hr = $sth->fetchrow_hashref;
            foreach my $key (keys %$hr) {
                $self->{$key} = $hr->{$key};
            }
        }
    }

    return $self;

}

sub sql_insert {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my ($fstat, $fdstat);
    my $sql = "insert into files (added_date, file_name, data, file_type, size, description) " . 
              "VALUES (now(), " . $dbh->quote($self->file_name) . ", " . $dbh->quote($self->{data}) . ", " .
              $dbh->quote($self->file_type) . ", " . $dbh->quote(length($self->{data})) . ", " . $dbh->quote($self->description) . ")";

    $fstat = $dbh->do($sql);

    $self->{id} = $dbh->{'mysql_insertid'};

    if ($self->file_type ne "generic") {
        if ($self->file_type eq "image") {
            # get image attributes.. width and height.
            $self->apply_subdriver("BadNews::File::Image");
            $fdstat = $dbh->do("insert into files_data (id, height, width, media_type) VALUES (" . $self->id . ", " . $dbh->quote($self->height) . 
                     ", " . $dbh->quote($self->width) . ", " . $dbh->quote($self->media_type) . ")");
        } elsif ($self->file_type eq "music") {
            # get mp3 attributes..
            $self->apply_subdriver("BadNews::File::Music");
            $fdstat = $dbh->do("insert into files_data (artist, time, album, track, song_name, year, media_type, id) VALUES (" .
                     $dbh->quote($self->artist) . ", " . $dbh->quote($self->time) . ", " . $dbh->quote($self->album) . 
                     ", " . $dbh->quote($self->track) . ", " . $dbh->quote($self->song_name) . ", " . 
                     $dbh->quote($self->year) . ", " . $dbh->quote($self->media_type) . ", " . $self->id . ")");
        } elsif ($self->file_type eq "document") {
            # get document attribute 
            $self->apply_subdriver("BadNews::File::Document");
            $fdstat = $dbh->do("insert into files_data (content, media_type, id) VALUES (" . $dbh->quote($self->content) . 
                       ", " . $dbh->quote($self->media_type) . ", " . $self->id . ")");
        }
    } else {
        $fdstat = $dbh->do("insert into files_data (media_type, id) VALUES (" . $dbh->quote('application/octet-stream') . ", " . 
                    $dbh->quote($self->id) . ")");
    }
    return ($fstat, $fdstat);
}

sub delete {
    my ($self) = @_;
    my $ret;
    if ($self->id) {
        my $dbh = $self->open_db;
        $ret += $dbh->do("delete from files where id = " . $self->id);
        $ret += $dbh->do("delete from files_data where id = " . $self->id);
    }
    return $ret;
}

sub apply_subdriver {
    my ($self, $driver_name) = @_;
    eval "use $driver_name";
    if ($@) {
        croak "Error loading driver: $driver_name: $@";
    }
    return $driver_name->apply($self);
}

sub added_date {
    my ($self) = @_;
    my $ci = BadNews::CalendarInterface->new();
    $ci->switch_date($self->{added_date});
    return $ci->time_short;
}

sub media_type {
    my ($self) = @_;
    return $self->{media_type} ? $self->{media_type} : "application/octet-stream";
}

sub artist {
    my ($self) = @_;
    return $self->{artist}
}

sub time {
    my ($self) = @_;
    return $self->{'time'};
}

sub album {
    my ($self) = @_;
    return $self->{album};
}

sub track {
    my ($self) = @_;
    return $self->{track};
}

sub song_name {
    my ($self) = @_;
    return $self->{song_name};
}

sub year {
    my ($self) = @_;
    return $self->{year};
}

sub content {
    my ($self) = @_;
    return $self->{content};
}

sub height {
    my ($self) = @_;
    return $self->{height};
}

sub width {
    my ($self) = @_;
    return $self->{width};
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub url {
    my ($self) = @_;
    if ($ENV{SERVER_PORT} == 443) {
        return "https://$ENV{SERVER_NAME}/files/" . $self->file_name;
    } else {
        return "http://$ENV{SERVER_NAME}/files/" . $self->file_name;
    }
}

sub name {
    my ($self) = @_;
    return $self->{file_name};
}

sub name_short {
    my ($self) = @_;
    if (length($self->{file_name}) > 19) {
        return substr($self->{file_name}, 0, 19) . '...';
    } else {
        return $self->{file_name};
    }
}

sub file_name {
    my ($self) = @_;
    return $self->{file_name};
}

sub data {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sql = "select data from files where id = " . $self->id;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}

sub type {
    my ($self) = @_;
    return $self->{file_type} or "generic";
}

sub file_type {
    my ($self) = @_;
    return $self->{file_type} or "generic";
}

sub size {
    my ($self) = @_;
    if ($self->{size}) {
        return $self->{size};
    } else {
        return length($self->data);
    }
}

sub description {
    my ($self) = @_;
    return $self->{description};
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
