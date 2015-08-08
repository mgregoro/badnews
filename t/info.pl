#!/usr/bin/perl
# $Id: info.pl 428 2006-08-30 02:00:57Z corrupt $

use MP3::Info;

my $tag = get_mp3tag("test.mp3") or die "No tag info!\n";

my $info = get_mp3info("test.mp3");

foreach my $key (keys %$tag) {
    print "$key: $tag->{$key}\n";
}

print "\n";

foreach my $key (keys %$info) {
    print "$key: $info->{$key}\n";
}
