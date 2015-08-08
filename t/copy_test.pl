#!/usr/bin/env perl

$ENV{DOCUMENT_ROOT} = '/usr/local/mg2dev/sites/bndev.mg2.org/badnews';
use Data::Dumper;

use BadNews::Copy;

#my $copy = BadNews::Copy->copy_by_name('intro_copy');
my $copy = all BadNews::Copy;

#my $copy = BadNews::Copy->new(
#    copy        =>      "Hi this is some copy, nifty eh?",
#    name        =>      "intro_copy",
#    lang        =>      "en",
#);

for (0...90000) {
    my $copy = $copy->en->intro_copy . "\n";
    print "$_, $copy\n";
}

#print $copy->en->intro_copy . "\n";
#print $copy->en->intro_copy . "\n";
#print $copy->de->whatever . "\n";

#print Dumper($copy);

