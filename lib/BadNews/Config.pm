# BadNews::Config is where we're going to store all of our fun configuration options!
# $Id: Config.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::Config;

@ISA = ('BadNews');
use XML::Simple;
use BadNews;
use Carp;

sub new {
    my ($class, %attribs) = @_;
    my $self = bless(\%attribs, $class);
    if (-e $self->{ConfigFile}) {
        $self->{pxml} = XMLin($self->{ConfigFile});
    } else {
        croak "$self->{ConfigFile} doesn't exist...";
    }
    return $self;
}

sub AUTOLOAD {
    my ($self) = @_;
    my $option = $AUTOLOAD;
    $option =~ s/^.+::([\w\_]+)$/$1/g;
    if (exists($self->{pxml}->{lc($option)})) {
        return $self->{pxml}->{lc($option)};
    } else {
        return undef;
    }
}

sub dump_cfg {
    my ($self) = @_;
    my $cfg;
    foreach my $key (keys %{$self->{pxml}}) {
        $cfg .= "$key: $self->{pxml}->{$key}\n";
    }
    return $cfg;
}

sub DESTROY {
    my ($self) = @_;
    $self = {};
    return;
}
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
