#!/usr/bin/perl
# $Id: menu.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('../lib');

use BadNews::ToolRegistry;
use FreezeThaw qw(freeze thaw);
use BadNews::ToolRegistry::Menu;
use Data::Dumper;

my $tr = BadNews::ToolRegistry->new;
my $menu = BadNews::ToolRegistry::Menu->new(tool_registry   =>  $tr,
                                            user            =>  'test');

#@main_menu = $menu->children_by_location(undef, undef, '_top, System');

@main_menu = $menu->sorted_children_by_location(undef, undef, '_top');

foreach my $hr (@main_menu) {
    if (exists($hr->{tool})) {
        print "Tool $hr->{tool} ($hr->{name})" . " @ " . $hr->{loc} . "\n";
    } else {
        print $hr->{name} . " @ " . $hr->{loc} . "\n";
    }
}

#my $frozen_menu = freeze($menu);

#my ($thawed_menu) = thaw($frozen_menu);

#print "$thawed_menu\n";

#print $thawed_menu->parent_menu('_top, Articles') . "\n";

#print Dumper($thawed_menu);
