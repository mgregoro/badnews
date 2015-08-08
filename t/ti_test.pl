#!/usr/bin/env perl

$ENV{DOCUMENT_ROOT} = '/usr/local/mg2dev/sites/bndev.mg2.org/badnews';
use BadNews::TagInterface;

my $ti = BadNews::TagInterface;

#my $tag = BadNews::TagInterface->new(
#                name        =>      'Oatmeal',
#                type        =>      'file',
#                ent_id      =>      4,
#
#            );

my $entity = $ti->entity_by_tag(5);
use Data::Dumper;

print Dumper($entity);


                
