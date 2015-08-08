#!/usr/bin/perl

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';
use lib('../lib');
use BadNews::Referrer;

my $ref = BadNews::Referrer->new(full_href      =>          'http://www.google.com/search?client=safari&rls=en-us&q=perl+url+%2B+decode&ie=UTF-8&oe=UTF-8');

use Data::Dumper;

print Dumper($ref);

my $ref2 = BadNews::Referrer->new(full_href     =>          'http://search.yahoo.com/search?fr=FP-pull-web-t&p=paul+loves+CHe%24r');

print Dumper($ref2);

my $ref3 = BadNews::Referrer->new(full_href     =>          'http://www.mg2.org/');

print Dumper($ref3);
