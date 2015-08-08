#!/usr/bin/perl
# $Id: image_info.pl 428 2006-08-30 02:00:57Z corrupt $

use Image::Info qw(image_info);

my $info = image_info("test.jpg");

use Data::Dumper;

print Dumper ($info) . "\n";
