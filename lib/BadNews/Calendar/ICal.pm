
package BadNews::Calendar::ICal;

use Data::ICal;
use BadNews;
use Carp;

@ISA = ('Data::ICal', 'BadNews');

sub new {
    my ($class, %attribs) = @_;
    my $self = Data::ICal::new($class, %attribs);
    return $self;
}

# some method that lets the ICal file sync with bN
# add events that aren't there mostly
sub update_bn {

}

# takes a bN Calendar::Event object and adds it to the ICal file
sub add_bn_entry {

}

# returns a string of an ICal file
sub print_ical {

}

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
