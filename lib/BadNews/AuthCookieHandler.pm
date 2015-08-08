package BadNews::AuthCookieHandler;

# the goal of this is to simply allow bN auth'd users access to Apache protected things

# $Id: AuthCookieHandler.pm 441 2006-12-11 21:32:47Z corrupt $

use Apache;
use BadNews::Session;
use Apache::Constants qw(:common);
use Apache::AuthCookie;
use vars qw($VERSION @ISA);

@ISA = qw(Apache::AuthCookie);

sub login_form {
    my $self = shift;

    my $r = Apache->request or die "no request";
    my $auth_name = $r->auth_name;

    my %args = $r->method eq 'POST' ? $r->content : $r->args;

    $self->_convert_to_get($r, \%args) if $r->method eq 'POST';

    # There should be a PerlSetVar directive that gives us the URI of
    # the script to execute for the login form.

    my $authen_script;
    unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
        $r->log_reason("PerlSetVar '${auth_name}LoginScript' not set", $r->uri);
        return SERVER_ERROR;
    }
    #$r->log_error("Redirecting to $authen_script");
    #$r->custom_response(FORBIDDEN, $authen_script);
    $r->headers_out->set(Location   =>  $authen_script . "?back=" . $r->uri);
    $r->status(302);
    return 302;
}

# this shouldn't be needed, as the only way to log in is through bN
sub authen_cred {
    my ($self, $r, @creds) = @_;
}

sub authen_ses_key {
    my ($self, $r, $session_id) = @_;

    # make this bN friendly
    $ENV{SERVER_NAME} = $r->hostname;
    $ENV{DOCUMENT_ROOT} = $r->document_root;

    my $session = BadNews::Session->new(session_id      =>      $session_id);
    if ($session) {
        return $session->user;
    } else {
        return undef;
    }
}

1;

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
