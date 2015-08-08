# the user perl module for BadNews... defines users opens users authenticates users...
# $Id: Author.pm 441 2006-12-11 21:32:47Z corrupt $
#

package BadNews::Author;

@ISA = ('BadNews', 'BadNews::User');
use BadNews;
use BadNews::User;
use Carp;

sub new {
    my ($class, %user) = @_;
    my $bnuser = BadNews::User->new(%user);
    return bless($bnuser, $class);
}

sub list {
    my ($class) = @_;
    my $self;

    # just in case im stupid and call you from an object... which i probably will..
    if (ref($class) =~ /BadNews/) {
        $self = $class;
    } else {
        $self = bless({}, $class);
    }

    my $dbh = $self->open_db;

    my @users;

    my $sth = $dbh->prepare("select id from users where flags like '%a%'");
    $sth->execute();

    while (my $ar = $sth->fetchrow_arrayref) {
        push (@users, BadNews::Author->open($$ar[0]));
    }

    return @users;
}

sub open_by_name {
    my ($class, $username) = @_;
    my $user = BadNews::User->open_by_name($username);
    if ($user && $user->has_flag('a')) {
        # this is an author
        my $author = bless($user, $class);
        return $author;
    } else {
        croak "$username is not an author!";
    }
}

sub open {
    my ($class, $id) = @_;
    my $user = BadNews::User->open($id);
    if ($user->has_flag('a')) {
        # this is an author
        my $author = bless($user, $class);
        return $author;
    } else {
        croak "$username is not an author!";
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
