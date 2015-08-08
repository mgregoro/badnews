# package for management of the links
# $Id: Links.pm 441 2006-12-11 21:32:47Z corrupt $
#
package BadNews::Links;

@ISA = ('BadNews');
use BadNews;
use Carp;

sub new {
    my ($class, %attribs) = @_;
    my $self = bless(\%attribs, $class);
    if ($self->{short_name} && $self->{url}) {
        # we have enough to add a link!
        my $dbh = $self->open_db;

        # make the category generic if none specified.
        $self->{category} = $self->{category} ? $self->{category} : 'generic';
        $self->{published} = defined($self->{published}) ? $self->{published} : 1;

        $dbh->do("insert into links (short_name, long_name, url, category, published) VALUES (" . $dbh->quote($self->short_name) . ", " .
                $dbh->quote($self->long_name) . ", " . $dbh->quote($self->url) . ", " . $dbh->quote($self->category) 
                . ", " . $dbh->quote($self->published) . ")");
        $self->{id} = $dbh->{mysql_insertid};
        return $self;
    } else {
        croak "Can't create a new link without short name and url.";
    }
}

sub open {
    my ($class, $link_id) = @_;
    my $self = bless({}, $class);
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, category, short_name, long_name, url, published from links where id = $link_id");
    $sth->execute();
    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    foreach my $key (keys %$hr) {
        $self->{$key} = $hr->{$key};
    }
    return $self;
}

sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;
    my $sql = "update links set ";
    my @attribs = ('category', 'short_name', 'long_name', 'url', 'published');
    my $i;

    foreach my $attr (@attribs) {
        ++$i;
        if ($i == scalar(@attribs)) {
            $sql .= "$attr = " . $dbh->quote($self->$attr);
        } else {
            $sql .= "$attr = " . $dbh->quote($self->$attr) . ", ";
        }
    }
    $sql .= " where id = " . $self->id;

    $dbh->do($sql);
}

sub delete {
    my ($self) = @_;
    my $dbh = $self->open_db;
    $dbh->do("delete from links where id = " . $self->id);
}

# i didnt want to do this.. they made me do it.
sub obj {
    my ($class) = @_;
    my $self = bless({}, $class);
    return $self;
}

sub all_links {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my (@links);
    my $sth = $dbh->prepare("select id from links");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@links, BadNews::Links->open($$ar[0]));
    }

    $links[$#links]->is_last(1) if scalar(@links);

    return @links;
}

sub links_by_cat {
    my ($class, $cat) = @_;
    my (@links, $sth);
    my $self = bless({}, $class);
    my $dbh = $self->open_db;
    if ($cat =~ /^all$/i) {
        $sth = $dbh->prepare("select id from links where published = '1'");
    } else {
        $sth = $dbh->prepare("select id from links where published = '1' and category = " . $dbh->quote($cat));
    }
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push (@links, BadNews::Links->open($$ar[0]));
    }

    $links[$#links]->is_last(1) if scalar(@links);

    return @links;
}

sub add_category {
    my ($self, $cat) = @_;
    unless (($self->category_exists($cat)) || ($cat =~ /^all$/i)) {
        my $dbh = $self->open_db;
        return $dbh->do("insert into link_categories (category) values (" . $dbh->quote($cat) . ")");
    }
    return undef;
}

sub delete_category {
    my ($self, $cat) = @_;
    if ($self->category_exists($cat)) {
        my $dbh = $self->open_db;
        return $dbh->do("delete from link_categories where category = " . $dbh->quote($cat));
    }
    return undef;
}

sub is_system_category {
    my ($self, $cat) = @_;
    if ($cat =~ /^\[SYS\]/) {
        return 1;
    } else {
        return undef;
    }
}

sub category_exists {
    my ($self, $cat) = @_;
    foreach my $ty ($self->list_categories) {
        return 1 if $ty eq $cat;
    }
    return undef;
}

sub list_categories {
    my ($self) = @_;
    my @categories;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select category from link_categories order by category asc");
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@categories, $$ar[0]);
    }
    return @categories;
}

sub category {
    my $self = shift;
    if ($_[0]) {
        $self->{category} = $_[0];
    }
    return $self->{category};
}

sub name_short {
    my ($self) = @_;
    if (length($self->{short_name}) > 19) {
        return substr($self->{short_name}, 0, 19) . '...';
    } else {
        return $self->{short_name};
    }
}


sub short_name {
    my $self = shift;
    if ($_[0]) {
        $self->{short_name} = $_[0];
    }
    return $self->{short_name};
}

sub long_name {
    my $self = shift;
    if ($_[0]) {
        $self->{long_name} = $_[0];
    }
    return $self->{long_name};
}

sub id {
    my $self = shift;
    return $self->{id};
}

sub is_last {
    my ($self) = shift;
    if (scalar(@_)) {
        $self->{is_last} = $_[0];
    }
    return ($self->{is_last});
}

sub url {
    my $self = shift;
    if ($_[0]) {
        $self->{url} = $_[0];
    }
    return $self->{url};
}

sub published {
    my ($self, $published) = @_;
    if (defined($published)) {
        $self->{published} = $published;
    }
    return $self->{published};
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

