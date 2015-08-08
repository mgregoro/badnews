#!/usr/local/mg2dev/bin/perl
# $Id: forum_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib ('/mg2root/web/bndev.mg2.org/lib');
#use Benchmark;
#use diagnostics;
use BadNews::Forum;

#my $forum = BadNews::Forum->new( subject    =>      'Hi',
#                                     body       =>      'some real content here!',
#                                     author     =>      'Mikey G',
#                                     associated_files   =>  '1:2' );

my $post = BadNews::Forum->open(4);

print $post->body . "\n";

#print $forum->body . "\n";

#my @cmnts = $forum->comments();
#use Data::Dumper;
#print Dumper(@cmnts);

#$forum->add_comment('Mikey G', 'www.mg2.org', 'Hi i love this post!', $cmnts[3]);

#my @comments = $forum->comments;

#print $forum->summary;

#$forum->delete_comment(1);

#$forum->body("here's your new body, bitch.");

#$forum->save;

#$forum->associate_file(1);

#$forum->save;

#my @files = $forum->files() if $forum->associated_files;

#foreach my $file (@files) {
#    print $file->name . "\n";
#    open(FILE, ">", $file->name);
#    print FILE $file->data;
#    close(FILE);
#}

#my $prev = $forum->prev_by_create;

#print $prev->id . "\n";

#my $next = $forum->next_by_create;

#print $next->id . "\n";
