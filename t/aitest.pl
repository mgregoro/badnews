#!/usr/bin/perl
# $Id: aitest.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2root/web/bndev.mg2.org/lib');

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::ArticleInterface;

my $ai = BadNews::ArticleInterface->new();

#my $test_body = "Hi this is a test and boy it's cool.  I have some cool links i'd like to share with you, lets see" .
#                " one right now here it is [<href link_id=1>]. isnt that cool?  How about another?  I know you love\n" .
#                " them here we are. [<href link_id=8>].  And how about a cool picture? [<img file_id=26>].  God that's hot!\n" .
#                " i think we need some more.. yeah thats right [<href link_id=7>].";

#print "$test_body\n";

#my $new_body = $ai->parse_body($test_body);

#print "$new_body\n";

#my @articles = $ai->articles_by_date_range('20050211000000', '20050212000000', 'create');

#foreach my $article (@articles) {
#    print $article->subject . "\n";
#}

#my ($year, $month) = $ai->min_time('create');
#print "$year, $month\n";
#my ($year, $month) = $ai->max_time('create');
#print "$year, $month\n";

#foreach my $article ($ai->articles_by_search_string('test', 'limit 1, 5', 'order by create_time desc')) {
    #print $article->summary . "\n\n";
    #print $article->body;
    #print $ai->truncate($article, 'body', '255', 1);
#    print $article->subject . "\n";
#}

#foreach my $month ($ai->month_summary) {
#    print $month->{month_name} . ", " . $month->{year} . "(" . $month->{count} . ")\n";
#}

foreach my $file ($ai->all_files) {
    print $file->file_name . "\n";
}

#foreach my $day ($ai->recent_days_with_articles(2)) {

#    print $day->today . "\n";

#}
