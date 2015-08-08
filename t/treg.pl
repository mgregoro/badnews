#!/usr/bin/perl
# $Id: treg.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('../lib');

use BadNews::ToolRegistry;
use Data::Dumper;

my $tr = BadNews::ToolRegistry->new;

print Dumper($tr);

my @tools = $tr->tools_by_parent_menu('articles');

foreach my $tool ($tr->tools_by_parent_menu('articles')) {
    print $tool->tool_title . "\n";
}
