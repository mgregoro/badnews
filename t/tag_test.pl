#!/usr/bin/env perl

$ENV{DOCUMENT_ROOT} = '/usr/local/mg2dev/sites/bndev.mg2.org/badnews';
use BadNews::Tag;

my $tag = BadNews::Tag->new(
                name        =>      'Oatmeal',
                type        =>      'file',
                ent_id      =>      4,

            );

$tag->increment_count;

use Data::Dumper;

print Dumper($tag);


print $tag->entity_type . "\n";
