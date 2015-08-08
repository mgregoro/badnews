#
#
# every tree needs a leaf/branch.
# $Id: Node.pm 446 2007-01-02 23:52:45Z corrupt $
#

package BadNews::AccessTree::Node;

@ISA = ('BadNews');
use BadNews;
use Carp;

# used to store the rudiments!
our @rudiments;

# .. we need a constructor
sub new {
    my ($class, %attribs) = @_;

    # we need it in object form asap since we're doing database stuff.. and we need to inherit the goodies
    # from BadNews.
    my $self = bless(\%attribs, $class);

    # we're looking for flag_name, flag_description (optional),
    # parent_flag_id, parent_flag_name..
    if (exists($self->{flag_name})) {
        # we have a flag, this is enough to create an entry..

        croak("flag for $self->{flag_name} already exists!") if $self->flag_exists($self->{flag_name});

        # resolve parent id to name, and parent name to id.... for lazy programmers like me
        if (exists($self->{parent_flag_name})) {
            $self->{parent_flag_id} = $self->flag_id_by_name($self->{parent_flag_name});
        } elsif (exists($self->{parent_flag_id})) {
            $self->{parent_flag_name} = $self->flag_name_by_id($self->{parent_flag_id});
        }

        $self->{flag_description} = $self->{flag_name} unless $self->{flag_description};
        # insert!

        my $dbh = $self->open_db;

        my $sth = $dbh->prepare(qq/

            insert into access_tree
                (flag_name, flag_description, parent_flag_id, parent_flag_name, create_time)
            VALUES
                (?,?,?,?,now())

        /);

        $sth->execute($self->flag_name, $self->flag_description, $self->parent_flag_id, $self->parent_flag_name);
        $self->{id} = $dbh->{mysql_insertid};
        return $self;
    }
}

sub open {
    my ($class, $id, $level) = @_;
    my $self;

    if (ref($class) eq "BadNews::AccessTree::Node") {
        $self = $class;
    } else {
        $self = bless({}, $class);
    }

    my $dbh = $self->open_db;

    # sql code here!
    my $sth = $dbh->prepare(qq/

        select id, flag_name, flag_description, parent_flag_id, 
               parent_flag_name, create_time, modify_time 
        from access_tree where id = ?

    /);

    $sth->execute($id);
    my $hr = $sth->fetchrow_hashref;

    # bless the hash ref into this class..
    $self = bless($hr, $class);

    # set a level of some sort
    $self->{level} = $level ? $level : "0";

    # return the object!
    return $self;
}

sub save {
    my ($self) = @_;
    my $dbh = $self->open_db;

    # sql followz!~
    my $sth = $dbh->prepare(qq/

        update access_tree set flag_name = ?, flag_description = ?, parent_flag_id = ?,
                parent_flag_name = ?
        where id = ?

    /);

    $sth->execute($self->flag_name, $self->flag_description, $self->parent_flag_id, $self->parent_flag_name, $self->id);
}

sub count_direct_descendents {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select count(id) from access_tree where parent_flag_id = " . $self->id);
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}

sub direct_descendents {
    my ($self) = @_;
    my @descendents;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from access_tree where parent_flag_id = " . $self->id);
    $sth->execute;

    while (my $ar = $sth->fetchrow_arrayref) {
        push(@descendents, BadNews::AccessTree::Node->open($$ar[0]));
    }

    return @descendents;
}

sub id {
    my ($self) = @_;
    return ($self->{id});
}

sub flag_exists {
    my ($self, $flag) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from access_tree where flag_name = " . $dbh->quote($flag));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}

sub flag_name {
    my ($self, $flag_name) = @_;
    $self->{flag_name} = $flag_name ? $flag_name : $self->{flag_name};
    return ($self->{flag_name});
}

sub flag_description {
    my ($self, $flag_description) = @_;
    $self->{flag_description} = $flag_description ? $flag_description : $self->{flag_description};
    return ($self->{flag_description});
}

sub parent_flag_id {
    my ($self, $parent_flag_id) = @_;
    if ($parent_flag_id) {
        $self->{parent_flag_id} = $parent_flag_id;
        $self->{parent_flag_name} = $self->flag_name_by_id($parent_flag_id);
    }
    return ($self->{parent_flag_id});
}

sub parent_flag_name {
    my ($self, $parent_flag_name) = @_;
    if ($parent_flag_name) {
        $self->{parent_flag_name} = $parent_flag_name;
        $self->{parent_flag_id} = $self->flag_id_by_name($parent_flag_name);
    }
    return ($self->{parent_flag_name});
}

sub level {
    my ($self, $level) = @_;
    $self->{level} = $level ? $level : $self->{level};
    return ($self->{level});
}

sub parent_flags {
    my ($self) = @_;
    my $current = $self;
    my @flags;
    while ($current->parent_flag_id) {
        push(@flags, $current);
        $current = $current->parent;
    }
    return @flags;
}

sub parent {
    my ($self) = @_;
    if ($self->parent_flag_id) {
        return BadNews::AccessTree::Node->open($self->parent_flag_id);
    }
    return undef;
}

# return the base flags that this flag contains!
sub rudiments {
    my ($self, $level) = @_;
    unless ($level) {
        undef(@rudiments);
    }
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from access_tree where parent_flag_id = " . $self->id);
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        my $rudy = BadNews::AccessTree::Node->open($$ar[0], $level + 1);
        push(@rudiments, $rudy); # if $rudy->count_direct_descendents < 1;
        $rudy->rudiments($level + 1);
    }
    return (@rudiments);
}

sub flag_name_by_id {
    my ($self, $id) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select flag_name from access_tree where id = $id");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
}

sub flag_id_by_name {
    my ($self, $name) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from access_tree where flag_name = " . $dbh->quote($name));
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    return $$ar[0];
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