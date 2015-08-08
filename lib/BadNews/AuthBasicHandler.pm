package BadNews::AuthBasicHandler;

# the goal of this is to simply allow bN auth'd users access to Apache protected things

# $Id: AuthBasicHandler.pm 441 2006-12-11 21:32:47Z corrupt $

use Carp;
use MIME::Base64 qw(decode_base64);
use BadNews::Session;
use Apache::Constants qw(:common M_GET FORBIDDEN REDIRECT);

use vars qw($VERSION);

$VERSION = 0.02;

sub handler {
    my $r = shift;

    return OK unless $r->is_initial_req;

    # get the user, cos $r->connection->user isn't working
    my ($sent_user);
    my $auth_hdr = $r->header_in("Authorization");
    if ($auth_hdr =~ /^Basic (.+)$/) {
        my $decoded = decode_base64($1);
        ($sent_user) = $decoded =~ /^(.+)\:.+$/;
    }

    my ($ret, $sent_pw) = $r->get_basic_auth_pw;

    return $ret if $ret != OK;

    unless ($sent_user) {
        $r->note_basic_auth_failure;
        $r->log_error("BadNews::AuthBasicHandler: user not specified! ", $r->uri);
        return AUTH_REQUIRED;
    }

    $ENV{SERVER_NAME} = $r->hostname;
    $ENV{DOCUMENT_ROOT} = $r->document_root;

    my $session = BadNews::Session->new(User        =>      $sent_user,
                                        Pass        =>      $sent_pw);

    if ($session) {
        my $bnuser = $session->bnuser;

        # user needs the webdav flag!
        if ($bnuser->has_flag('d') || $bnuser->has_flag('s')) {
            return OK;
        } else {
            $r->note_basic_auth_failure;
            $r->log_error("BadNews::AuthBasicHandler: web(d)av or (s)ysadmin flag required ", $r->uri);
            return AUTH_REQUIRED;
        }
    } else {
        $r->note_basic_auth_failure;
        $r->log_error("BadNews::AuthBasicHandler: invalid credentials ", $r->uri);
        return AUTH_REQUIRED;
    }
}

sub authz {
    my $request = shift;        # Apache request
    my $requires = $request->requires;  # Apache Requires arrayref
    my $username            # username
      = $request->connection->user;
    my $require = "";           # one Requires statement
    my $type    = "";           # type of Requires
    my @users   = ();           # list of valid users

    # decline unless we have a requires
    return OK unless $requires;

    # process each Requires statement
    for my $require (@$requires) {
        my($type, @users) = split /\s+/, $require->{requirement};

    # user is one of these users
    if ($type eq "user") {
        return OK if grep($username eq $_, @users);

    # user is simply authenticated
    } elsif ($type eq "valid-user") {
        return OK;
    }
    }

    $request->note_basic_auth_failure;
    $request->log_reason("user $username: not authorized", $request->uri);
    return AUTH_REQUIRED;

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
