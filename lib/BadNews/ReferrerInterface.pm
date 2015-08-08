# $Id: ReferrerInterface.pm 441 2006-12-11 21:32:47Z corrupt $
# the BadNews::ReferrerInterface package

package BadNews::ReferrerInterface;

@ISA = ('BadNews');
use BadNews::Referrer;
use BadNews;
use Carp;

sub new {
    my ($class) = @_;
    return bless({}, $class);
}

sub add_banned_word {
    my ($self, $word) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("insert into r_banned_words (word, create_time) values (?,now())");
    $sth->execute($word);
    $sth = $dbh->prepare("delete from referrers where full_href like ?");
    $sth->execute('%' . $word . '%');
}

sub remove_banned_word {
    my ($self, $word) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("delete from r_banned_words where word = ?");
    $sth->execute($word);
}

sub list_banned_words {
    my ($self) = @_;
    my @return;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select word from r_banned_words");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@return, $$ar[0]);
    }
    return (@return);
}

sub last_referrers {
    my ($self, $count, $offset) = @_;
    $count = $count ? $count : $self->c->REF_DISPLAY_NUM;
    my (@return, $sth);
    my $dbh = $self->open_db;
    if ($offset) {
        $sth = $dbh->prepare("select id from referrers order by create_time desc limit $count, $offset");
    } else {
        $sth = $dbh->prepare("select id from referrers order by create_time desc limit $count");
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@return, BadNews::Referrer->open($$ar[0]));
    }

    if (scalar(@return)) {
        $return[$#return]->is_last(1);
    }
    
    return (@return);
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

