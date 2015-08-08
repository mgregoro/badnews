# $Id: Tag.pm 441 2006-12-11 21:32:47Z corrupt $
# BadNews::Tag - for tagging articles / dates / files with infos
#
# will have some corresponding url like:
# [% fe.bn_location %]/tag/file/id/?tag=oatmeal
# w/ a comma delimited list of tags w/ counts at [% fe.bn_location %]/tag/file/id/
#

package BadNews::Tag;

@ISA = ('BadNews');
use BadNews;
use Carp;

# we still are going to use dualing constructors
sub new {
    my ($class, %tag) = @_;
    my $self = bless(\%tag, $class);
    my $dbh = $self->open_db;

    unless ($self->{name} && $self->{type} && $self->{ent_id}) {
        croak "Can't create a new tag without a name, type, and ent_id (id of the item of the type you want to tag)";
    }

    # what we'll end up returning...
    my $tag_object;

    if (my $id = $self->tag_exists) {
        $self = BadNews::Tag->open($id);

        # increment the count for this tag..
        $self->increment_count;

        # reassign for returnage.
        # I so just want to write return $self; ...
        $tag_object = $self;
    } else {
        # create this tag
        my $sth = $dbh->prepare(qq/
                    insert into tags (name, type, ent_id) 
                        VALUES (?, ?, ?)
                    /);
        $sth->execute($self->{name}, $self->{type}, $self->{ent_id});
        my $id = $dbh->{mysql_insertid};

        # assign the final value to the tag object.
        # I so just want to write return BadNews::Tag->open($id); ...
        $tag_object = BadNews::Tag->open($id);
        $tag_object->{created_new} = 1;
    }

    return $tag_object;
}

# en garde!
sub open {
    my ($class, $id) = @_;

    return undef unless $id;

    # bless the object for the parent's database methods
    my $self = bless({}, $class);

    # do database stuff..
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
                select id, name, type, count, ent_id, modify_time from tags
                    where id = ?
                /);
    $sth->execute($id);
    my $hr = $sth->fetchrow_hashref;

    # saves us a copy to just return the blessed hashref
    return $hr ? bless($hr, $class) : undef;
}

# one more generic constructor.. 
sub objectify {
    my ($class, $hr) = @_;

    unless (ref($hr) eq "HASH") {
        croak "Must specify a hash ref as the first argument to objectify.  Must contain keys and values for: id, name, type, count, ent_id, and modify_time."
    }

    return bless($hr, $class);
}

# To save the data with.
sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;

    my $sth = $dbh->prepare(qq/
                update tags set name = ?, type = ?, count = ?, ent_id = ?
                    where id = ?
                /);

    $sth->execute($self->{name}, $self->{type}, $self->{count}, $self->{ent_id}, $self->{id});

}

# increment the tag count...
sub increment_count {
    my ($self) = @_;
    $self->count($self->count + 1);
    $self->save;
    return $self;
}

sub id {
    my ($self) = @_;
    return ($self->{id});
}

sub ent_id {
    my ($self, $ent_id) = @_;
    $self->{ent_id} = $ent_id ? $ent_id : $self->{ent_id};
    return ($self->{ent_id});
}

sub name {
    my ($self, $name) = @_;
    $self->{name} = $name ? $name : $self->{name};
    return ($self->{name});
}

sub type {
    my ($self, $type) = @_;
    $self->{type} = $type ? $type : $self->{type};
    return ($self->{type});
}

sub count {
    my ($self, $count) = @_;
    $self->{count} = $count ? $count : $self->{count};
    return ($self->{count});
}

sub created_new {
    my ($self) = @_;
    return ($self->{created_new});
}

sub modify_time {
    my ($self) = @_;
    return ($self->{modify_time});
}

# see if a tag exists that matches this one
sub tag_exists {
    my ($self, $tag, $type, $ent_id) = @_;
    $tag = $tag ? $tag : $self->{name};
    $type = $type ? $type : $self->{type};
    $ent_id = $ent_id ? $ent_id : $self->{ent_id};

    my $dbh = $self->open_db;

    # find out if there's a tag with this name already
    my $sth = $dbh->prepare(qq/
                select id from tags where name = ? && type = ? && ent_id = ?
                /);

    $sth->execute($tag, $type, $ent_id);

    my $ar = $sth->fetchrow_arrayref;

    return $$ar[0];
}

sub is_last {
    my ($self) = shift;
    if (scalar(@_)) {
        $self->{is_last} = $_[0];
    }
    return ($self->{is_last});
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

