#!/usr/bin/perl

use lib('../lib');

use BadNews;

my $bn = BadNews->new();

$bn->log('mikey g', 'edit_event', 'event id 3');
