# 
# $Id: ToolRegistry.pm 441 2006-12-11 21:32:47Z corrupt $
# the ToolRegistry package
#

package BadNews::ToolRegistry;

@ISA = ('BadNews');
use BadNews;
use BadNews::ToolRegistry::Tool;
use Carp;

sub new {
    my ($class) = @_;
    my $self = bless({tools     =>      []}, $class);
    $self->register_tools;
    return $self;
}

sub tools {
    my ($self) = @_;
    return @{$self->{tools}}
}

sub register_tools {
    my ($self) = @_;
    opendir(TOOLS, $self->c->CMS_PATH . "/tools") or croak $self->c->CMS_PATH . "/tools doesn't exist!";
    while (my $tool = readdir(TOOLS)) {
        next if $tool =~ /^\.+$/;
        next if $tool eq "CVS";
        $tool = $self->c->CMS_PATH . "/tools/$tool";
        my @stat = stat($tool);
        my $register_text = `$tool register`;
        $register_text .= "m_time=" . scalar localtime($stat[9]) . "\n";
        $register_text .= "size=$stat[7]\n";
        push(@{$self->{tools}}, BadNews::ToolRegistry::Tool->new(register_text  =>  $register_text));
    }
}

sub tool_by_name {
    my ($self, $tool_name) = @_;
    foreach my $tool ($self->tools) {
        return $tool if $tool->tool_name eq $tool_name;
    }
    return undef;
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

