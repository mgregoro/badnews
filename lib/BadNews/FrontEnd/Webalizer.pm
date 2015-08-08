
# $Id: Cms.pm 428 2006-08-30 02:00:57Z corrupt $

package BadNews::FrontEnd::Webalizer;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Registry;
use Apache::Constants qw/:common :http/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    unless ($fe->uri =~ /\/$/) {
        $r->header_out("Location"   =>      $fe->bn_location . "/webalizer/");
        $r->status(HTTP_MOVED_TEMPORARILY);
        $r->send_http_header;
        return HTTP_MOVED_TEMPORARILY;
    }
    $r->internal_redirect($fe->bn_location . "/webalizer/index.html");
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

