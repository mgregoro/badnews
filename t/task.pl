#!/usr/bin/perl
# $Id: task.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2root/web/bndev.mg2.org/lib');

$ENV{DOCUMENT_ROOT} = '/mg2root/web/bndev.mg2.org/html';

use BadNews::Todo::Task;

#my $task = BadNews::Todo::Task->open(10);

#my $task = BadNews::Todo::Task->new(
#    description     =>          'a test task',
#    creator         =>          'mikey g',
#    category        =>          'Test Task');

my $task = BadNews::Todo::Task->open(1);
    

#print ref($task) . "\n";

$task->name("some name");

$task->save;

