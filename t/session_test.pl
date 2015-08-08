#!/usr/bin/perl
# $Id: session_test.pl 428 2006-08-30 02:00:57Z corrupt $

use lib('/mg2web/www.ascscyo.org/lib');
use BadNews::Session;

# type A:
# establish session w/ user and pass
#my $session = BadNews::Session->new(User    =>      'mikey g',
#                                   Pass    =>      'test123');

# type B:
# establish Anonymous session with 'Anon' set to true
#my $session = BadNews::Session->new(Anon => 1);

# type C:
# re-open/re-establish old session using pre-existing session id
my $session = BadNews::Session->new(session_id  =>      'c7c32d35b5fccb79b7798cc3e066eec7');

#my $session = BadNews::Session->new(User    =>      'corrupt',
#                                Pass    =>      'brokejki99');

print $session->session_id . "\n";
print $session->user . "\n";

#$session->fux0r('__clear__');

#print $session->fux0r . "\n";

