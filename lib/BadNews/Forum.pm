#
# Forum.pm - forum wrapper around Article.pm
#

package BadNews::Forum;

use base qw/BadNews::Article/;

sub base_post {
    my ($self) = @_;
    return $self->article;
}

sub posts {
    my ($self) = @_;
    return $self->comments;
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
