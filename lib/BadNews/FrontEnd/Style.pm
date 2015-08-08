# $Id: Style.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Style;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews::FrontEnd::Extension;
use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;
use BadNews;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $css_cache_duration = $fe->c->CSS_CACHE_DURATION ? $fe->c->CSS_CACHE_DURATION : 3600 * 48;

    my ($css_theme) = $uri[1] =~ /^(\w+)\./;
    my $page = "css_stylesheet";

    # set our theme to whatever css this is asking for..
    $fe->theme($css_theme);
    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $css_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $css_cache_duration));
    }
    $r->content_type('text/css');
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

