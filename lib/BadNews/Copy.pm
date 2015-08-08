# $Id: Copy.pm 428 2006-08-30 02:00:57Z corrupt $
# BadNews::Copy - small bits of text categorized by language
#

package BadNews::Copy;

@ISA = ('BadNews', 'Class::Accessor');
use vars qw($AUTOLOAD);
use BadNews::GenericCache;
use Class::Accessor;
use BadNews;
use Carp;

our $gc = BadNews::GenericCache->new();

# Thx for the free accessor methods Schwern!
BadNews::Copy->mk_accessors(qw(lang copy name));
BadNews::Copy->mk_ro_accessors(qw(id create_time modify_time));

# we still are going to use dualing constructors
sub new {
    my ($class, %copy) = @_;
    my $self = bless(\%copy, $class);
    my $dbh = $self->open_db;

    unless ($self->{copy} && $self->{name}) {
        croak "Can't create a new instance of BadNews::Copy without some damned copy! (copy => 'your copy')... ";
    }

    if ($self->copy_by_name($self->{name})) {
        croak "Can't create copy $self->{name}, it already exists!";
    }

    # what we'll end up returning
    my $copy_object;

    my $sth = $dbh->prepare(qq/
                insert into copy (copy, name, lang, create_time)
                    VALUES (?, ?, ?, now())
                /);

    $sth->execute($self->{copy}, $self->{name}, $self->{lang});

    my $id = $dbh->{mysql_insertid};

    $copy_object = BadNews::Copy->open($id);

    return $copy_object;
}

# en garde!
sub open {
    my ($class, $id) = @_;

    return undef unless $id;

    # bless the object for the parent's database methods
    my $self = bless({}, $class);

    # do database stuff..
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select * from copy where id = ?");
    $sth->execute($id);
    my $hr = $sth->fetchrow_hashref;

    return $hr ? bless($hr, $class) : undef;
}

# returns an object from which "all" copy can be retrieved
sub all {
    my ($class) = @_;
    return bless({}, $class);
}

# one more generic constructor.. 
sub objectify {
    my ($class, $hr) = @_;

    unless (ref($hr) eq "HASH") {
        croak "Must specify a hash ref as the first argument to objectify."
    }

    return bless($hr, $class);
}

# To save the data with.
sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;

    my $sth = $dbh->prepare(qq/
        update copy set copy = ?, name = ?, lang = ?
            where id = ?
        /);
    $sth->execute($self->{copy}, $self->{name}, $self->{lang}, $self->{id});
}

sub copy_by_name {
    my ($self, $name) = @_;
    my $class;
    if (ref($self)) {
        # got called as a method...
        $class = ref($self);
    } else {
        # got called as a constructor
        $class = $self;
    }
    my $copy = bless({}, $class);
    my $dbh = $copy->open_db;
    my $sth = $dbh->prepare("select * from copy where name = ?");
    $sth->execute($name);
    my $hr = $sth->fetchrow_hashref;

    return $hr ? bless($hr, $class) : undef;
}

sub copy_by_lang_and_name {
    my ($self, $lang, $name) = @_;
    my $class;
    if (ref($self)) {
        # got called as a method...
        $class = ref($self);
    } else {
        # got called as a constructor
        $class = $self;
    }
    my $copy = bless({}, $class);
    my $dbh = $copy->open_db;
    my $sth = $dbh->prepare("select * from copy where lang = ? && name = ?");
    $sth->execute($lang, $name);
    my $hr = $sth->fetchrow_hashref;

    return $hr ? bless($hr, $class) : undef;
}

sub is_last {
    my ($self) = shift;
    if (scalar(@_)) {
        $self->{is_last} = $_[0];
    }
    return ($self->{is_last});
}

# ok $copy->lang->name
sub AUTOLOAD {
    my ($self) = @_;

    my $option = $AUTOLOAD;
    $option =~ s/.*:://g;

    # determine if this is a language call
    # if it is make a package for this language and set up an autoloader for this class
    # also define a subroutine for this behavior and load it up (zero overhead on the next pass)

    if (ref($self) eq "BadNews::Copy") {
        # this is a lang or default call.
        if (my $copy = $self->copy_by_lang_and_name($self->c->DEFAULT_LANG, $option)) {
            my $copy_text = $copy->copy;
            *$AUTOLOAD = sub {
                return $copy_text;    
            };

            # return the value of our new sub!
            goto &$AUTOLOAD;
        } else {
            # this is a lang call!
            my $class = $AUTOLOAD;

            # Try caching for performance
            if (${"$class\::exists"}) {
                if (my $structure = $gc->get_from_cache($ENV{SERVER_NAME})) {
                    # if it was in the cache, return it..
                    if (defined($structure->{$option})) {
                        return $structure->{$option};
                    } else {
                        # we have a structure, but nothing for this option..
                        $structure->{$option} = bless({lang => $option}, $class);
                        $gc->add_to_cache($ENV{SERVER_NAME}, $structure);
                        return $structure->{$option};
                    }
                } else {
                    # add it to the cache
                    my $structure;
                    $structure->{$option} = bless({lang => $option}, $class);
                    $gc->add_to_cache($ENV{SERVER_NAME}, $structure);
                    return $structure->{$option};
                }

            } else {
                #warn "$class\::AUTOLOAD\n";

                # scope out the hott namespace.
                my $class_guts = "package $class;\n";
                
                # gotta cache per site for context, so use BadNews::GenericCache
                $class_guts .= 'use BadNews::GenericCache;' . "\n";
                $class_guts .= 'our $gc = BadNews::GenericCache->new();' . "\n";

                # tell the world that we exist
                $class_guts .= 'our $exists = 1;';

                $class_guts .= q|
                    sub AUTOLOAD {
                        my ($self) = @_;

                        # this is scoped within our dynamically generated lang subclass
                        our $AUTOLOAD;
                        my $option = $AUTOLOAD;
                        $option =~ s/.*:://g;

                        if (my $copy = BadNews::Copy->copy_by_lang_and_name($self->{lang}, $option)) {
                            $gc->add_to_cache($ENV{SERVER_NAME}, $copy->copy);
                            *$AUTOLOAD = sub {
                                return $gc->get_from_cache($ENV{SERVER_NAME});
                            };
                            goto &$AUTOLOAD;
                        } else {
                            return undef;
                        }
                    }

                    sub DESTROY {
                        # noop!
                    }
    
                    1;
                    __END__
                |;

                eval($class_guts);
            }

            return bless({lang => $option}, $class);
        }
    }

    warn join(', ', $AUTOLOAD, caller()) . "\n";
    return $self;
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
