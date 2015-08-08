#
# $Id: Tool.pm 441 2006-12-11 21:32:47Z corrupt $
# the BadNews tool registry
#
# Stores tool atributes in a nice neat little object ;)
#

package BadNews::ToolRegistry::Tool;

use Carp;

sub new {
    my ($class, %attribs) = @_;

    # we can be one of two ways..
    if (exists($attribs{register_text})) {
        my $self = bless({attribs   =>      {}}, $class);
        foreach my $entry (split(/\n/, $attribs{register_text})) {
            $entry =~ /^(.+)=(.*)$/;
            $self->{attribs}->{$1} = $2;
        }
        return $self;
    } else {
        # just require a few things.. nothing too strict.
        unless (exists($attribs{tool_name})) {
            croak "tool_name must be specified to register tool.";
        }
        unless (exists($attribs{tool_title})) {
            croak "tool_title must be specified to register tool.";
        }
        unless (exists($attribs{sufficient_flags})) {
            croak "sufficient_flags must be specified to register tool.";
        }
        unless (exists($attribs{menu_position})) {
            croak "menu_position must be specified to register tool.";
        }
        return bless({attribs   =>  \%attribs}, $class);
    }
}

sub registration {
    my ($self) = @_;
    my $return;
    foreach my $key (keys %{$self->{attribs}}) {
        if (ref($self->{attribs}->{$key}) eq "ARRAY") {
            $return .= "$key=" . join(',', @{$self->{attribs}->{$key}}) . "\n";
        } else {
            $return .= "$key=" . $self->{attribs}->{$key} . "\n";
        }
    }
    return $return;
}

# this way it won't be split into an array by commas in the description ;)
sub description {
    my ($self) = @_;
    if (exists($self->{attribs}->{description})) {
        return $self->{attribs}->{description};
    }
    return undef;
}

sub AUTOLOAD {
    my ($self) = @_;
    my $key = $AUTOLOAD;
    $key =~ s/^.+::([\w\_]+)$/$1/g;
    if (exists $self->{attribs}->{$key}) {
        if (ref($self->{attribs}->{$key}) eq "ARRAY") {
            return @{$self->{attribs}->{$key}};
        } elsif ($self->{attribs}->{$key} =~ /,/) {
            my @array = split(/\s*,\s*/, $self->{attribs}->{$key});
            $self->{attribs}->{$key} = \@array;
            return @array;
        } else {
            return $self->{attribs}->{$key};
        }
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

