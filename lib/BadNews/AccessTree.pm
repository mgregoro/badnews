#
#
# the access tree module ;)
# $Id: AccessTree.pm 441 2006-12-11 21:32:47Z corrupt $
#

package BadNews::AccessTree;

@ISA = ('BadNews');
use BadNews::AccessTree::Node;
use BadNews::User;
use BadNews;
use Carp;

sub add_flag {
    my ($self, $flag) = @_;
    my $flag = BadNews::AccessTree::Node->new(%$flag);
    my @af;
    if (ref($flag) eq "BadNews::AccessTree::Node") {

    } else {
        croak "Couldn't add flag $flag->{flag_name}!";
    }
}

sub remove_flag {

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
