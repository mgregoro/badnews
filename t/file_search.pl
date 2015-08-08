#!/usr/bin/perl
# $Id: file_search.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2web/www.ascscyo.org/lib');
use BadNews::File::Search;

my $fs = BadNews::File::Search->new(artist      =>      'ublim');

foreach my $file ($fs->results) {
    print $file->file_name . "\n";
}
