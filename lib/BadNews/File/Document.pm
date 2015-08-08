# a 'subdriver' for the file type 'Document'
# $Id: Document.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::File::Document;

@ISA = ('BadNews');
use BadNews;
use Carp;

sub apply {
    my ($class, $self) = @_;
    open(FH, ">", "/tmp/$$.tmp.doc");
    print FH $self->data;
    close(FH);
    my @output = `/usr/bin/antiword -i 1 /tmp/$$.tmp.doc`;
    $self->{content} = join(undef, @output);
    $self->{media_type} = 'application/msword';
    unlink("/tmp/$$.tmp");
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
