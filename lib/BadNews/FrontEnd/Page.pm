# $Id: Page.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Page;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Constants qw/:common/;
use Apache::Util qw /ht_time/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $page_cache_duration = $fe->c->PAGE_CACHE_DURATION ? $fe->c->PAGE_CACHE_DURATION : 15 * 60;
    my $page = $uri[1];

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }
    for my $opt (@uri[2..$#uri]) {
        $fe->cgi->param($opt  =>  1);
    }
    $r->content_type('text/html');
    $r->send_http_header;
    $fe->render_page($page);
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

