# $Id: Referrer.pm 441 2006-12-11 21:32:47Z corrupt $
# the BadNews::Referrer package

package BadNews::Referrer;

@ISA = ('BadNews');
use BadNews;
use Carp;

sub new {
    my ($class, %referrer) = @_;
    my $self = bless(\%referrer, $class);

    if ($self->full_href) {
        return undef if $self->contains_banned_word;
        $self->{search_engine} = $self->search_engine ? $self->search_engine : $self->_parse_search_engine;
        $self->{query_string} = $self->query_string ? $self->query_string : $self->_parse_query_string;
        my $dbh = $self->open_db;
        my $sth = $dbh->prepare("insert into referrers (search_engine, query_string, full_href, create_time) VALUES (?,?,?,now())");
        $sth->execute($self->search_engine, $self->query_string, $self->full_href);
        $self->{id} = $dbh->{mysql_insertid};

        # one way to do it.. 
        #return $self;
        # or to get the proper create_timestamp...
        return BadNews::Referrer->open($self->{id});
    }

    return undef;
}

sub open {
    my ($class, $id) = @_;

    return undef unless $id;

    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select id, search_engine, query_string, full_href, create_time from referrers where id = $id");

    $sth->execute;

    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    # bless the hashref we get back from fetchrow_hashref.. why not
    $self = bless($hr, $class);
    return $self;
}

sub contains_banned_word {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, word from r_banned_words");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        my $word = $$ar[1];
        if ($self->{full_href} =~ /$word/i) {
            $self->log("not_available", "banned_referrer", $self->full_href . " contains banned word $word.  Banned word id: $$ar[0]");
            return 1;
        }
    }
    return undef;
}

sub _parse_query_string {
    my ($self) = @_;
    # ask.com = u
    # google = q
    # msn = q
    # hotbot = query
    # yahoo = p
    # altavista = q

    my $qshr = $self->_qs_breakdown;
    if ($self->search_engine eq "ask") {
        return $qshr->{u};
    } elsif ($self->search_engine eq "google") {
        return $qshr->{q};
    } elsif ($self->search_engine eq "msn") {
        return $qshr->{q};
    } elsif ($self->search_engine eq "hotbot") {
        return $qshr->{query};
    } elsif ($self->search_engine eq "yahoo") {
        return $qshr->{p};
    } elsif ($self->search_engine eq "altavista") {
        return $qshr->{q};
    } else {
        return "none";
    }
}

sub _qs_breakdown {
    my ($self) = @_;
    my ($start, $args) = split(/\?/, $self->{full_href}, 2);
    my $qs_hr = {};
    while ($args =~ /([\w\%\_\$\+\,\.\/\:\;\?\@]+)=([\w\_\.\%\$\+\,\/\:\;\?\@]+)/g) {
        my ($key, $value) = ($1, $2);
        $qs_hr->{$key} = $value;
        
        # turn "+"s into spaces
        $qs_hr->{$key} =~ s/\+/ /g;

        # turn hex variants into their character counterparts
        $qs_hr->{$key} =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    }
    return $qs_hr;
}

sub _parse_search_engine {
    my ($self) = @_;
    if ($self->{full_href} =~ /(msn|yahoo|google|altavista|hotbot|ask)\.(?:com|net)/) {
        return $1;
    }
    return "none";
}

sub search_engine {
    my ($self, $se) = @_;
    if ($se) {
        $self->{search_engine} = $se;
        return $se;
    }
    if (exists($self->{search_engine})) {
        return $self->{search_engine};
    } else {
        return undef;
    }
}

sub query_string {
    my ($self, $qs) = @_;
    if ($qs) {
        $self->{query_string} = $qs;
        return $qs;
    }
    if (exists($self->{query_string})) {
        return $self->{query_string};
    } else {
        return undef;
    }
}

sub full_href {
    my ($self, $fhr) = @_;
    if ($fhr) {
        $self->{full_href} = $fhr;
        return $fhr;
    }
    if (exists($self->{full_href})) {
        return $self->{full_href};
    } else {
        return undef;
    }
}

sub tidy_href {
    my ($self, $len) = @_;
    $len = $len ? $len : 29;
    my $hrf = $self->full_href;
    if (length($hrf) > $len) {
        return (substr($hrf, 0, $len) . "...");
    } else {
        return $hrf;
    }
}

sub is_last {
    my ($self, $is_last) = @_;
    if ($is_last) {
        $self->{is_last} = 1;
        return 1;
    }
    if (exists($self->{is_last})) {
        return $self->{is_last};
    } else {
        return undef;
    }
}

sub id {
    my ($self) = @_;
    return $self->{id} ? $self->{id} : undef;
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

