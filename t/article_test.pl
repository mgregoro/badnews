#!/usr/bin/perl
# $Id: article_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib ('/mg2root/web/bndev.mg2.org/lib');
#use Benchmark;
#use diagnostics;
use BadNews::Article;
use Apache::DBI;

#my $article = BadNews::Article->new( subject    =>      'Hi',
#                                     body       =>      'some real content here!',
#                                     author     =>      'Mikey G',
#                                     associated_files   =>  '1:2' );

my $article = BadNews::Article->open(18);

#print $article->body . "\n";

#my @cmnts = $article->comments();
#use Data::Dumper;
#print Dumper(@cmnts);

#$article->add_comment('Mikey G', 'www.mg2.org', 'Hi i love this post!', $cmnts[3]);

#my @comments = $article->comments;

#print $article->summary;

#$article->delete_comment(1);

#$article->body("here's your new body, bitch.");

#$article->save;

#$article->associate_file(1);

#$article->save;

#my @files = $article->files() if $article->associated_files;

#foreach my $file (@files) {
#    print $file->name . "\n";
#    open(FILE, ">", $file->name);
#    print FILE $file->data;
#    close(FILE);
#}

my $prev = $article->prev_by_create;

print $prev->id . "\n";

my $next = $article->next_by_create;

print $next->id . "\n";
