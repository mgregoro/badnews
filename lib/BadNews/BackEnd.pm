# 
# the BadNews::BackEnd module.. 
# essentially this is a web server
#

package BadNews::BackEnd;

# this is a subclass of BadNews.. and Apache::Registry ..
@ISA = ('BadNews', 'Apache::Registry');

use BadNews;
use HTTP::Daemon;
use HTTP::Status;
use Carp;

# Major components follow

# server initialization code

# log code

# URL parser

# Dispatcher

# ENV variable setter

# Compile / hash "plugin" mechanism for external tools

__END__

=head1 COPYRIGHT

BadNews CMS
Copyright 2004-2006 by Michael Gregorowicz
                       the mg2 organization

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

the mg2 organization makes no representations about the suitability of
this software for any purpose. It is provided "as is" without express or
implied warranty.

See http://www.perl.com/perl/misc/Artistic.html

=cut
