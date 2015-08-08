# $Id: Tag.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Tag;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::Tag;
use BadNews::FrontEnd::Extension;
use Apache::Constants qw/:common/;
use Apache::Util qw /ht_time/;

use JSON;

# create one instance... for all to use ;)
my $json = JSON->new(   convblessed     =>      1,
                        skipinvalid     =>      1);

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my $page_cache_duration = 1; # no caching here pls
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;


    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }

    my $tag_type = $uri[1];
    my $tag_ent_id = $uri[2];
    my $tag_name = $fe->param('tag_name');

    # rather than a generic internal server error...
    unless ($tag_type && $tag_ent_id && $tag_name) {
        $r->content_type('text/html');
        $r->send_http_header;
        $fe->render_error("Improper use of Tag extension!");
        return OK;
    }

    my $tag = BadNews::Tag->new(
                name            =>          $tag_name,
                type            =>          $tag_type,
                ent_id          =>          $tag_ent_id,
            );

    $r->content_type('application/x-javascript');
    $r->header_out('X-bN-Tag-Entity', $tag_ent_id);
    $r->header_out('X-bN-Tag-Type', $tag_type);
    $r->send_http_header;

    # goodies time ;)

    print $tag->id . "\n" . $tag->created_new;
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

