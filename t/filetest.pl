#!/usr/bin/perl
# $Id: filetest.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2web/www.ascscyo.org/lib');

use BadNews::File;

open(FH, "Bank One Customer Services.doc");
{
    local $/;
    $data = <FH>;
}
close(FH);

my $file = BadNews::File->new(file_name     =>      'Bank_One_Customer_Services.doc',
                              data          =>      $data,
                              description   =>      'in the ghetto!',
                              file_type     =>      'document');

exit();

#my $file = BadNews::File->open("test.mp3");

if ($file->file_name) {

    print "Found file " . $file->file_name . ": " . $file->description . "\n";
    open(TOP, ">test_out.mp3");
    print TOP $file->data;
    close(TOP);

    print "file type: " . $file->file_type . "\n";

    print $file->media_type . "\n";

}

#$file->delete;
