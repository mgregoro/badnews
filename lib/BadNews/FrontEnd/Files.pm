# $Id: Files.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Files;

@ISA = ('BadNews::FrontEnd::Extension');

use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;
use BadNews::FrontEnd::Extension;
use BadNews::File;
use BadNews;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $image_cache_duration = $fe->c->IMAGE_CACHE_DURATION ? $fe->c->IMAGE_CACHE_DURATION : 3600 * 48;

    # this is a file.
    my $file_name = join('/', @uri[1..$#uri]);

    # declare the file variable..
    my $file;
    if ($file_name =~ /^\d+$/o) {
        $file = BadNews::File->open_by_id($file_name);
    } else {
        $file = BadNews::File->open($file_name);
    }

    if ($file) {
        $r->content_type($file->media_type);
        $r->header_out('Content-Length', $file->size);
        if ($http_version >= 1.1) {
            $r->header_out('Cache-Control', 'max-age=' . $image_cache_duration);
        } else {
            $r->header_out('Expires', ht_time(time + $image_cache_duration));
        }
        $r->send_http_header;
        return OK if $r->method eq "HEAD";
        print $file->data;
    } else {
        # error...
        $r->content_type('text/html');
        $r->send_http_header;
        return OK if $r->method eq "HEAD";
        $fe->template->process($fe->theme . '/error.tt2', { error => "Can't find the file: $file_name\n, $!, $@"});
    }
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

