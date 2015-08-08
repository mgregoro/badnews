#!/usr/bin/perl
# $Id: linkstest.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2web/www.ascscyo.org/lib');
use BadNews::Links;

#my $link = BadNews::Links->new(short_name   =>      'a link to mg2',
#                               url          =>      'http://www.mg2.org');

my @links = BadNews::Links->all_links;

foreach my $link (@links) {
    $link->url('http://www.jetski.com');
    $link->save;
    print "<a href='" . $link->url . "'>" . $link->short_name . "</a>\n";
}
