# the BadNews::Calendar::Event::Conflict object

package BadNews::Calendar::Event::Conflict;

use BadNews::Calendar::Event;
use Carp;

sub new {
    my ($class, %conflict) = @_;
    if ($conflict{event_id}) {
        $conflict{event} = BadNews::Calendar::Event->open($conflict{event_id});
        unless (ref($conflict{event}) eq "BadNews::Calendar::Event") {
            croak "Guessing $conflict{event_id} wasn't valid.";
        }
    } else {
        croak "We need at least an event id of the conflicting event!\n";
    }
    return bless(\%conflict, $class);
}

sub recur_instance {
    my ($self) = @_;
    return $self->{recur_instance} if exists $self->{recur_instance};
}

sub number_of_conflicts {
    my ($self) = @_;
    return $self->{number_of_conflicts} if exists $self->{number_of_conflicts};
}

sub event {
    my ($self) = @_;
    return $self->{event};
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
