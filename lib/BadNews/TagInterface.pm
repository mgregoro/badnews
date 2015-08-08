# $Id: TagInterface.pm 441 2006-12-11 21:32:47Z corrupt $
# BadNews::TagInterface
# ok .. fine i did it

package BadNews::TagInterface;

@ISA = ('BadNews');
use BadNews::Calendar::Event;
use BadNews::File;
use BadNews::Article;
use BadNews::Tag;
use BadNews;
use Carp;

sub new {
    my ($class) = @_;
    return bless({}, $class);
}

sub all_tags {
    my ($self) = @_;
    my @tags;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, name, type, count, ent_id, modify_time from tags");
    $sth->execute;

    while (my $hr = $sth->fetchrow_hashref) {
        push(@tags, BadNews::Tag->objectify($hr));
    }

    $tags[$#tags]->is_last(1) if scalar(@tags);

    return @tags;
}

# things that might be in a TagInterface type class, had i made one... tags are simple so we'll
# just put that type of thing right here. (i moved it to TagInterface.. rock on)
sub tags {
    my ($self, $type, $ent_id) = @_;
    my @tags;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, name, type, count, ent_id, modify_time from tags where type = ? && ent_id = ?");
    $sth->execute($type, $ent_id);

    while (my $hr = $sth->fetchrow_hashref) {
        push(@tags, BadNews::Tag->objectify($hr));
    }

    $tags[$#tags]->is_last(1) if scalar(@tags); 

    return @tags;
}

sub tags_by_type {
    my ($self, $type) = @_;
    my @tags;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, name, type, count, ent_id, modify_time from tags where type = ?");
    $sth->execute($type);

    while (my $hr = $sth->fetchrow_hashref) {
        push(@tags, BadNews::Tag->objectify($hr));
    }

    $tags[$#tags]->is_last(1) if scalar(@tags);

    return @tags;
}

# we'll support events, articles, and files for now.. none of the
# other subsystems are 100% done yet.
sub entity_by_tag {
    my ($self, $tag) = @_;

    my $ent;

    unless (ref($tag) eq "BadNews::Tag") {
        if ($tag =~ /^\d+$/) {
            $tag = BadNews::Tag->open($tag);
        } else {
            croak "Must specify either a tag id or a BadNews::Tag object in entity_by_tag..";
        }
    }
    if ($tag->type eq "article") {
        $ent = BadNews::Article->open($tag->ent_id);
    } elsif ($tag->type eq "file") {
        $ent = BadNews::File->open_by_id($tag->ent_id);
    } elsif ($tag->type eq "event") {
        $ent = BadNews::Calendar::Event->open($tag->ent_id);
    }

    return $ent;
}

sub entities_by_name {
    my ($self, $name) = @_;

    unless ($name) {
        croak "Must specify name for entities_by_name";
    }

    my @entities;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
                select id, name, type, count, ent_id, modify_time from tags
                    where name = ?
                /);

    $sth->execute($name);

    # iterate through the tags returned to come up with the entities
    while (my $hr = $sth->fetchrow_hashref) {
        my $entity = $self->entity_by_tag(BadNews::Tag->objectify($hr));
        if (ref($entity) =~ /BadNews/o) {
            push(@entities, $entity);
        }
    }

    $entities[$#entities]->is_last(1) if scalar(@entities);

    return (@entities);
}

sub entities_by_type {
    my ($self, $type) = @_;

    unless ($type) {
        croak "Must specify type for entities_by_type";
    }

    my @entities;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
                select id, name, type, count, ent_id, modify_time from tags
                    where type = ?
                /);

    $sth->execute($type);

    # iterate through the tags returned to come up with the entities
    while (my $hr = $sth->fetchrow_hashref) {
        my $entity = $self->entity_by_tag(BadNews::Tag->objectify($hr));
        if (ref($entity) =~ /BadNews/o) {
            push(@entities, $entity);
        }
    }

    $entities[$#entities]->is_last(1) if scalar(@entities);

    return (@entities);
}

sub entities_by_name_and_type {
    my ($self, $name, $type, $to, $from) = @_;

    # make sure we have a default value set here.
    $to = "5" unless $to;

    unless ($name && $type) {
        croak "Must specifiy name and type for entities_by_name_and_type()";
    }

    my $limit = $from ? "limit $from, $to" : "limit $to";

    my @entities;

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
                    select id, name, type, count, ent_id, modify_time from tags 
                        where name = ? && type = ? $limit
                    /);

    $sth->execute($name, $type);

    # iterate through the tags returned to come up with the entities
    while (my $hr = $sth->fetchrow_hashref) {
        my $entity = $self->entity_by_tag(BadNews::Tag->objectify($hr));
        if (ref($entity) =~ /BadNews/o) {
            push(@entities, $entity);
        }
    }

    $entities[$#entities]->is_last(1) if scalar(@entities);

    return (@entities);
}
    
sub previous_entities_by_name_and_type {
    my ($self, $name, $type, $to, $from) = @_;

    my $limit = $from ? "limit $from, " . ($to + $from) : "limit $to";
    
    my $sth = $dbh->prepare(qq/
                    select count(id) from tags 
                        where name = ? && type = ? $limit
                    /);

    $sth->execute($name, $type);
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

