# a 'subdriver' for the file type 'Image'
# $Id: Image.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::File::Image;

@ISA = ('BadNews');
use Image::Info qw(image_info);
use BadNews;
use Carp;

sub apply {
    my ($class, $self) = @_;
    my $info = image_info(\$$self{data});
    $self->{height} = $info->{height};
    $self->{width} = $info->{width};
    $self->{media_type} = $info->{file_media_type};
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
