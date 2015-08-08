# $Id: Task.pm 441 2006-12-11 21:32:47Z corrupt $
#
# An individual task on the todo list
#

package BadNews::Todo::Task;

@ISA = ('BadNews');
use BadNews::CalendarInterface;
use BadNews::Todo;
use BadNews;
use Carp;

# all time in diminished time (YYYYMMDDHHMMSS)

# creates a new task
sub new {
    my ($class, %task) = @_;
    my $self = bless(\%task, $class);
    if ($self->description && $self->creator) {
        # we have a task description and task creator.. thats all we need. 
        # lets see what else we have. and default the rest.
        my $ci = BadNews::CalendarInterface->new();

        # task is owned by the creator if no owner is specified
        $self->{owner} = $self->{owner} ? $self->{owner} : $self->creator;

        # comment log is "created task" if there's no comment log.
        $self->{comment_log} = $self->{comment_log} ? $self->{comment_log} : "[" . $ci->time_short . "] " . $self->creator . " created task\n";

        $self->{category} = $self->{category} ? $self->{category} : "Generic";
        $self->{parent} = $self->{parent} ? $self->{parent} : 0;
        $self->{name} = $self->{name} ? $self->{name} : undef;
        $self->{completed} = $self->{completed} ? $self->{completed} : 0;
        $self->{active} = $self->{active} ? $self->{active} : 0;
        $self->{published} = $self->{published} ? $self->{published} : 0;
        $self->{extended_attributes} = $self->{extended_attributes} ? $self->{extended_attributes} : 0;
        if ($self->completed) {
            $self->{complete_time} = $ci->dim;
        }

        # insert non extended attributes first cos we need the id.. to do the extended attributes
        my $dbh = $self->open_db;
        my $sth = $dbh->prepare("insert into tasks (parent, name, creator, owner, category, description, comment_log, create_time, due_time, eta_time, complete_time, " . 
                                "completed, active, published, extended_attributes, factor_likeness, factor_satisfaction, factor_stress, factor_coop, factor_difficulty " . 
                                ") VALUES (?,?,?,?,?,?,?,now(),?,?,?,?,?,?,?,?,?,?,?,?)");
        $sth->execute($self->parent, $self->name, $self->creator, $self->owner, $self->category, $self->description, $self->comment_log,
                        $self->due_time, $self->eta_time, $self->complete_time, $self->completed, $self->active, 
                        $self->published, $self->extended_attributes, $self->factor_likeness, $self->factor_satisfaction,
                        $self->factor_stress, $self->factor_coop, $self->factor_difficulty);

        $self->{id} = $dbh->{mysql_insertid}; 

        if ($self->extended_attributes) {
            # if we have extended attributes, we should add them..
            foreach my $key (keys %$self) {
                # ignore if the key is one of our reserved methods or attributes...
                if ($key eq "parent"        ||      $key eq "name"          ||      $key eq "description"       ||
                    $key eq "create_time"   ||      $key eq "modify_time"   ||      $key eq "due_time"          ||
                    $key eq "eta_time"      ||      $key eq "complete_time" ||      $key eq "completed"         ||
                    $key eq "active"        ||      $key eq "published"     ||      $key eq "extended_attributes" || 
                    $key eq "config"        ||      $key eq "owner"         ||      $key eq "creator"           ||
                    $key eq "factor_likeness" ||   $key eq "factor_satisfaction" || $key eq "factor_stress"     ||
                    $key eq "factor_coop"   ||      $key eq "factor_difficulty" ||  $key eq "comment_log"       ||
                    $key eq "category"
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

        # return a shiny new object to clear up any confusion...
        return BadNews::Todo::Task->open($self->id);
    }
    return undef;
}

# opens a new task by id
sub open {
    my ($class, $id) = @_;

    return undef unless $id;
    
    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select id, parent, name, description, create_time, modify_time, due_time, eta_time, complete_time, completed, active, published, " .
                            "extended_attributes, owner, creator, factor_likeness, factor_satisfaction, factor_stress, factor_coop, factor_difficulty, " . 
                            "comment_log from tasks where id = $id");

    $sth->execute;

    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    # just bless what we get from mysql.
    $self = bless($hr, $class);
    return $self;
}

# saves a changed task
sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;

    my $sql = "update tasks set ";
    my @attribs = qw(parent name description due_time eta_time complete_time completed active published extended_attributes creator owner factor_likeness factor_satisfaction
                    factor_stress factor_coop factor_difficulty comment_log);
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

sub id {
    my ($self) = @_;
    return $self->{id} if exists $self->{id};
}

sub category {
    my ($self, $category) = @_;
    if ($category) {
        $self->{category} = $category;
        return $category;
    }
    if (exists($self->{category})) {
        return $self->{category};
    } else {
        return undef;
    }
}

sub owner {
    my ($self, $owner) = @_;
    if ($owner) {
        $self->{owner} = $owner;
        return $owner;
    }
    if (exists($self->{owner})) {
        return $self->{owner};
    } else {
        return undef;
    }
}

sub creator {
    my ($self, $creator) = @_;
    if ($creator) {
        $self->{creator} = $creator;
        return $creator;
    }
    if (exists($self->{creator})) {
        return $self->{creator};
    } else {
        return undef;
    }
}

sub parent {
    my ($self, $parent) = @_;
    if ($parent) {
        $self->{parent} = $parent;
    }
    if (exists($self->{parent})) {
        return $self->{parent};
    } else {
        return undef;
    }
}

sub name {
    my ($self, $name) = @_;
    if ($name) {
        $self->{name} = $name;
        return $name;
    }
    if (exists($self->{name})) {
        return $self->{name};
    } else {
        return undef;
    }
}   

sub description {
    my ($self, $desc) = @_;
    if ($desc) {
        $self->{description} = $desc;
        return $desc;
    }
    if (exists($self->{description})) {
        return $self->{description};
    } else {
        return undef;
    }
}

sub comment_log {
    my ($self, $line) = @_;
    if ($line) {
        my $ci = BadNews::CalendarInterface->new();
        $self->{comment_log} .= "[" . $ci->time_short . "] " . $line . "\n";
        return $self->comment_log;
    }
    if (exists($self->{comment_log})) {
        return $self->{comment_log};
    } else {
        return undef;
    }
}

sub create_time {
    my ($self, $time) = @_;
    if ($time) {
        $self->{create_time} = $time;
        return $time;
    } 
    if (exists($self->{create_time})) {
        return $self->{create_time};
    } else {
        return undef;
    }
}

sub modify_time {
    my ($self, $time) = @_;
    if ($time) {
        $self->{modify_time} = $time;
        return $time;
    } 
    if (exists($self->{modify_time})) {
        return $self->{modify_time};
    } else {
        return undef;
    }
}

sub due_time {
    my ($self, $time) = @_;
    if ($time) {
        $self->{due_time} = $time;
        return $time;
    } 
    if (exists($self->{due_time})) {
        return $self->{due_time};
    } else {
        return undef;
    }
}

sub eta_time {
    my ($self, $time) = @_;
    if ($time) {
        $self->{eta_time} = $time;
        return $time;
    } 
    if (exists($self->{eta_time})) {
        return $self->{eta_time};
    } else {
        return undef;
    }
}

sub complete_time {
    my ($self, $time) = @_;
    if ($time) {
        $self->{complete_time} = $time;
        return $time;
    }
    if (exists($self->{complete_time})) {
        return $self->{complete_time};
    } else {
        return undef;
    }
}

sub completed {
    my ($self, $completed) = @_;
    if (defined $completed) {
        $self->{completed} = $completed;
        return $completed;
    } 
    if (exists($self->{completed})) {
        return $self->{completed};
    } else {
        return undef;
    }
}

sub active {
    my ($self, $active) = @_;
    if (defined $active) {
        $self->{active} = $active;
        return $active;
    } 
    if (exists($self->{active})) {
        return $self->{active};
    } else {
        return undef;
    }
}

sub published {
    my ($self, $published) = @_;
    if (defined $published) {
        $self->{published} = $published;
        return $published;
    } 
    if (exists($self->{published})) {
        return $self->{published};
    } else {
        return undef;
    }
}  

sub extended_attributes {
    my ($self, $extended_attributes) = @_;
    if (defined $extended_attributes) {
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
        if ($self->{_extended_attributes}->{$option}->{timestamp} + $self->c->TODO_EA_CACHE < time) {
            # the cache is expired.. recache.
            my $dbh = $self->open_db;
            my $sth = $dbh->prepare("select attribute_value from task_attributes where task_id = " . $self->id . " && attribute_name = " .
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
        my $sth = $dbh->prepare("select attribute_value from task_attributes where task_id = " . $self->id . " && attribute_name = " . 
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
                $dbh->do("update task_attributes set attribute_value = " . $dbh->quote($value) . " where task_id = " . $self->id . 
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
            my $sth = $dbh->prepare("insert into task_attributes (task_id, attribute_name, attribute_value, create_time) values (?,?,?,now())");
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

