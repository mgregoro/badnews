# search object for the BadNews file repository
# $Id: Search.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::File::Search;

@ISA = ('BadNews', 'BadNews::File');
use BadNews::File;
use BadNews;
use Carp;

sub new {
    my ($class, %criteria) = @_;
    
    my $self = bless({criteria  =>  \%criteria}, $class);

    $self->fetch_results;

    return $self;
}

sub results {
    my ($self) = @_;
    return @{$self->{results}};
}

sub formulate_sql {
    my ($self) = @_;
    my $criteria = $self->criteria;
    my $sql;
    if (exists($self->criteria->{all})) {
        $sql = "select files.id from files, files_data where files_data.id = files.id";
    } else {
        $sql = "select files.id from files, files_data where files_data.id = files.id && (";
        my ($i, $len) = (0, scalar(keys(%$criteria)));
        foreach my $key (keys %$criteria) {
            ++$i;
            if ($i == $len) {
                $sql .= "$key like " . '\'%' . "$criteria->{$key}" . '%\'';
            } else {
                $sql .= "$key like " . '\'%' . "$criteria->{$key}" . '%\' || ';
            }
        }
        $sql .= ")";
    }
    return $sql;
}

sub fetch_results {
    my ($self) = @_;
    my $sql = $self->formulate_sql;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        my $id = $$ar[0];
        push(@{$self->{results}}, BadNews::File->open_by_id($id));
    }
}

sub criteria {
    my ($self) = @_;
    return $self->{criteria};
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
