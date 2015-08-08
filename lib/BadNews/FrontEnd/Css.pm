# $Id: Css.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Css;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews::FrontEnd::Extension;
use BadNews;
use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $css_cache_duration = $fe->c->CSS_CACHE_DURATION ? $fe->c->CSS_CACHE_DURATION : 3600 * 48;

    # get the dir we're supposed to be in..
    my $css_dir = $fe->c->CSS_DIR ? $fe->c->CSS_DIR : $ENV{DOCUMENT_ROOT} . "/css";

    my $file_name = "$css_dir/" . join('/', @uri[1..$#uri]);

    # multiple return points.. but a condition to return exists here.
    unless (-f $file_name) {
        $r->content_type('text/html');
        $r->send_http_header;
        $fe->render_error("Can't find the file: $file_name\n, $! $@");
        return OK;
    }

    # get ready to take in file_data...
    my ($file_data, $media_type);

    if ($file_name =~ /\.css$/o) {
        $media_type = "text/css";
    } elsif ($file_name =~ /\.gif$/o) {
        $media_type = "image/gif";   
    } else {
        $media_type = "text/html";
    }

    if (open(FILE, '<', $file_name)) {
        local $/;
        $file_data = <FILE>;
        close(FILE);
    }

    # handle the cache header ;)
    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $css_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $css_cache_duration));
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

