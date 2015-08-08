# $Id: Tags.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Tags;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::TagInterface;
use BadNews::FrontEnd::Extension;
use Apache::Constants qw/:common/;
use Apache::Util qw /ht_time/;

use JSON;

# create one instance... for all to use ;)
my $json = JSON->new(   convblessed     =>      1,
                        skipinvalid     =>      1);

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;

    # no caching :~(
    my $page_cache_duration = 1;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;

    my $tags = [];
    my $ti = BadNews::TagInterface->new;

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }

    my $tag_type = $uri[1];
    my $tag_ent_id = $uri[2];

    foreach my $tag ($ti->tags($tag_type, $tag_ent_id)) {
        push(@{$tags}, $tag);
    }

    $r->content_type('application/x-javascript');
    $r->header_out('X-bN-Tag-Entity', $tag_ent_id);
    $r->header_out('X-bN-Tag-Type', $tag_type);
    $r->send_http_header;

    # goodies time ;)

    print $json->objToJson($tags, {pretty        =>      1});
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

