#!/usr/bin/perl
# $Id: newstest.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2web/www.ascscyo.org/lib');

use BadNews::Calendar;

my $bn = BadNews::Calendar->new();

use Data::Dumper;

print Dumper ($bn) . "\n";

my $dbh = $bn->open_db;

print Dumper ($dbh) . "\n";
