# subdriver for mp3s aacs and other music file types
# $Id: Music.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::File::Music;

@ISA = ('BadNews');
use BadNews;
use Carp;
use MP3::Info;

sub apply {
    my ($class, $self) = @_;
    open(FH, ">", "/tmp/$$.tmp.mp3");
    print FH $self->data;
    close(FH);
    my $tag = get_mp3tag("/tmp/$$.tmp.mp3");
    my $info = get_mp3info("/tmp/$$.tmp.mp3");

    $self->{artist} = $tag->{ARTIST};
    $self->{'time'} = $info->{TIME};
    $self->{album} = $tag->{ALBUM};
    $self->{track} = $tag->{TRACKNUM};
    $self->{song_name} = $tag->{TITLE};
    $self->{year} = $tag->{YEAR};
    $self->{media_type} = 'audio/mpeg3';

    unlink("/tmp/$$.tmp.mp3");

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
