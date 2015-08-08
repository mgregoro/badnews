#!/usr/bin/perl
# $Id: comment_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib ('/mg2root/web/bndev.mg2.org/lib');
#use Benchmark;
#use diagnostics;
use BadNews::Article;
use BadNews::Article::Comment;
use Apache::DBI;

my $cmnt = BadNews::Article::Comment->open(12);

foreach my $c ($cmnt->dc) {
    print $c->comment . "\n";
}

#my $article = BadNews::Article->open(10);

#$article->add_comment('Mikey G', 'http://mike.mg2.org', 'Suck me dry cockfucker', $cmnt->id);
