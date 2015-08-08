#!/usr/bin/perl
# $Id: article_search.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2root/web/bndev.mg2.org/lib');

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::Article::Search;

my $search = BadNews::Article::Search->new(category  =>  'general',
                                            limit_string => 'limit 1; select * from');

foreach my $result ( $search->results) {
    print $result->subject . "\n";
    my @files = $result->files;
    foreach my $file (@files) {
        print ref($file) . "\n";
    }
}


