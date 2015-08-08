
# $Id: Cms.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::FrontEnd::Cms;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Registry;
use Apache::Constants qw/:common :http/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    unless ($uri[1]) {
        $r->header_out("Location"   =>      $fe->bn_location . "/cms/tools/login");
        $r->status(HTTP_MOVED_TEMPORARILY);
        $r->send_http_header;
        return HTTP_MOVED_TEMPORARILY;
    }
    Apache::Registry::handler($r);
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

