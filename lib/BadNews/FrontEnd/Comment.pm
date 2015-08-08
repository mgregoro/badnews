
package BadNews::FrontEnd::Comment;

@ISA = ('BadNews::FrontEnd::Extension', 'BadNews');

# for bN compatibility

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Constants qw/:common/;
use Apache::Util qw /ht_time/;

use JSON;

# create one instance... for all to use ;)
my $json = JSON->new(   convblessed     =>      1,
                        skipinvalid     =>      1);

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $page_cache_duration = $fe->c->PAGE_CACHE_DURATION ? $fe->c->PAGE_CACHE_DURATION : 15 * 60;

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }

    # here we are :)

    $r->content_type('application/x-javascript');
    $r->send_http_header;

    my $cobj = $fe->ai->open_comment_by_id($uri[1]);
    my $comment = {};

    # transfer what we have here..
    foreach my $key (keys %$cobj) {
        $comment->{$key} = $cobj->{$key};
    }

    # add in some stuff that requires a bit of computing
    $comment->{count_children} = $cobj->count_children;
    my @dc = map( $_->{id}, $cobj->direct_children );
    $comment->{direct_children} = \@dc;
    $comment->{pretty_create_time} = $fe->ai->pretty_date($cobj->{create_time});
    print $json->objToJson($comment, {pretty        =>      1});

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

