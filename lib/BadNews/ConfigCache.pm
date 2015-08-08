# the ConfigCache module.. for caching multiple sites configuration files.
# $Id: ConfigCache.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::ConfigCache;

use Carp;

sub new {
    my ($class, %attribs) = @_;
    return bless({cache     =>      {}}, $class);
}

sub add_to_cache {
    my ($self, $site, $cfg) = @_;
    croak "Not a BadNews::Config object..." unless ref($cfg) eq "BadNews::Config";
    if (exists($self->{cache}->{$site})) {
        return undef;
    } else {
        $self->{cache}->{$site} = $cfg;
        return 1;
    }
}

sub get_from_cache {
    my ($self, $site) = @_;
    if (exists($self->{cache}->{$site})) {
        return $self->{cache}->{$site};
    } else {
        return undef;
    }
}

sub sites_in_cache {
    my ($self) = @_;
    return keys %{$self->{cache}};
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
