#!/usr/bin/perl
# $Id: author_test.pl 428 2006-08-30 02:00:57Z corrupt $
#use lib ('/mg2root/web/bndev.mg2.org/lib');
$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::User;


#my $author = BadNews::Author->new(username  =>      'allsaintsad',
#                                  common_name   =>  'All Saints Athletics Director',
#                                  password  =>      'allsaints123');

#my $user = BadNews::User->new(username      =>      'Joey P',
#                              common_name   =>      'Joseph Peters',
#                              password      =>      'deeznuts',
#                              extended_attributes   =>  1);

my $user = BadNews::User->open_by_name("paul");

#$user->extended_attributes(1);

#if ($author->user_exists('mikey g')) {
#    print "Hi!\n";
#}

$user->add_flag('a');

#$author->add_flag('a');
#$author->remove_flag('b');

#if ($author->has_flag('a')) {
#    print "Test flag found!\n";
#}

#die "no such user\n" unless $author;

#print $author->authenticate('test123') . "\n";

print $user->common_name . "\n";

$user->ice_cream('vanilla');
print $user->ice_cream . "\n";

#use Data::Dumper;

#print Dumper ($user);
