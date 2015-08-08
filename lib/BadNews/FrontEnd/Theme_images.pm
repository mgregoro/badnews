# $Id: Theme_images.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Theme_images;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews::FrontEnd::Extension;
use BadNews;
use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $image_cache_duration = $fe->c->IMAGE_CACHE_DURATION ? $fe->c->IMAGE_CACHE_DURATION : 3600 * 48;

    my $theme = lc($uri[1]);
    my $image = join('/', @uri[2..$#uri]);
    my @paths = split(/:/, $fe->c->THEME_PATH);
    my ($image_file, $media_type);

    foreach my $path (@paths) {
        $image_file = $path . "/" . $theme . "/images/" . $image;
        last if -e $image_file;
        undef $image_file;
    }

    unless ($image_file) {
        $r->content_type('text/html');
        $r->send_http_header;
        $fe->template->process($fe->theme . '/error.tt2', { error => "Can't find the file: $image\n, $!, $@"});
        return OK;
    }

    # try and get the mime type from the file name
    if ($image =~ /\.gif/o) {
        $media_type = "image/gif";
    } elsif ($image =~ /\.png/o) {
        $media_type = "image/png";
    } elsif ($image =~ /\.jpe?g$/o) {
        $media_type = "image/jpeg";
    } elsif ($image =~ /\.xpm$/o) {
        $media_type = "image/xpm";
    } elsif ($image =~ /\.tif{1,2}/o) {
        $media_type = "image/tiff";
    } else {
        $media_type = "image/unknown";
    }

    # get ready to take in file_data...
    my $file_data;

    if (open(IMAGE, '<', $image_file)) {
        local $/;
        $file_data = <IMAGE>;
        close(IMAGE);
    }

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $image_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $image_cache_duration));
    }
    $r->content_type($media_type);
    $r->header_out('Content-Length', length($file_data));
    $r->send_http_header;
    print $file_data;
    return OK;
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

