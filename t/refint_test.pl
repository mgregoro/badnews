#!/usr/bin/perl

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';
use lib('../lib');
use BadNews::ReferrerInterface;

my $ri = BadNews::ReferrerInterface;

foreach my $ref ($ri->last_referrers('10')) {
    print $ref->id . ": " . $ref->query_string . " @ " . $ref->search_engine . "\n";
}
