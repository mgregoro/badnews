
# $Id: Rss.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::FrontEnd::Rss;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews::FrontEnd::Extension;
use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;
use XML::RSS;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my $page_cache_duration = $fe->c->PAGE_CACHE_DURATION ? $fe->c->PAGE_CACHE_DURATION : 15 * 60;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }

    # first try..
    my $category = $uri[1] unless $uri[1] eq "rss.xml";

    # second try...
    $category = $fe->cgi->param('category') unless $category;

    my $rss = XML::RSS->new(version     =>      2);

    $rss->channel(
        title               =>      $fe->c->APP_TITLE,
        link                =>      $fe->c->RSS_SITE_LINK,
        description         =>      $fe->c->RSS_DESCRIPTION,
        dc                  =>  {
            date                =>      $fe->ci->rss_format,
            subject             =>      $fe->c->RSS_SUBJECT . " (" . $category . ")",
            creator             =>      $fe->c->RSS_CREATOR,
            publisher           =>      $fe->c->RSS_PUBLISHER,
            rights              =>      $fe->c->RSS_COPYRIGHT,
            language            =>      $fe->c->RSS_LANGUAGE
        },
        syn                 =>  {
            updatePeriod        =>      $fe->c->RSS_SYN_UPDATE_PERIOD,
            updateFrequency     =>      $fe->c->RSS_SYN_UPDATE_FREQUENCY,
            updateBase          =>      $fe->c->RSS_SYN_UPDATE_BASE
        }
    );

    my @articles;
    if ($category) {
        @articles = $fe->ai->articles_by_category($category, 'create', $fe->c->RSS_NUMBER_OF_ARTICLES);
    } else {
        @articles = $fe->ai->recent_articles($fe->c->RSS_NUMBER_OF_ARTICLES);
    }

    foreach my $article (@articles) {
        my @tags = $fe->ti->tags('article', $article->id);
        $rss->add_item(
            title           =>      $article->subject,
            link            =>      $fe->c->RSS_ARTICLE_URL . $article->id,
            description     =>      $article->body,
            dc              =>  {
                date            =>      $fe->ci->rss_format($article->create_time),
                subject         =>      $article->category . " - " . join(', ', map($_->name, @tags)),
            }
        );
    }
    $r->content_type('text/xml');
    $r->send_http_header;
    print $rss->as_string;
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

