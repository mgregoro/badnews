#!/usr/bin/perl

use BadNews;

my $bn = new BadNews;

my $dbh = $bn->open_db();

my $sth = $dbh->prepare("select * from articles");

$sth->execute;

while (1) {
    print $sth->fetchrow_arrayref->[0];
}
