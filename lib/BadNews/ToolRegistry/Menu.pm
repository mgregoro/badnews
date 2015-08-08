#
# $Id: Menu.pm 441 2006-12-11 21:32:47Z corrupt $
# the ToolRegistry menu
#

package BadNews::ToolRegistry::Menu;

@ISA = ('BadNews');

use BadNews;
use BadNews::User;
use Carp;

sub new {
    my ($class, %attribs) = @_;

    # verify input
    unless (ref($attribs{tool_registry}) eq "BadNews::ToolRegistry") {
        croak "tool_registry attribute passed to BadNews::ToolRegistry::Menu->new() must be a BadNews::ToolRegistry object!";
    }

    # verify input
    unless (ref($attribs{user}) eq "BadNews::User" || ref($attribs{user}) eq "BadNews::Author") {
        unless ($attribs{user} = BadNews::User->open_by_name($attribs{user})) {
            croak "user attribute passed to BadNews::ToolRegistry::Menu->new() must be a valid user, a BadNews::User or a BadNews::Author object!";
        }
    }

    my $self = bless(\%attribs, $class);
    $self->render_menu;
    return $self;
}

sub render_menu {
    my ($self) = @_;

    foreach my $tool ($self->tr->tools) {
        # iterate through the toolz!
        my @tmenu = ($tool->menu_position, $tool->tool_title);

        # skip if this tool doesn't go on a menu
        next if $tmenu[$#tmenu] eq "_none";

        # skip if the user doesn't have access to this item
        next unless $self->has_sufficient_access($tool);

        my $eval_string = '$self->{menu}';
        foreach my $tool (@tmenu) {
            $eval_string .= "->{'$tool'}";
        }
        $eval_string .= " = '" . $tool->tool_name . "';";
        eval $eval_string;
    }

}

sub sorted_children_by_location {
    my ($self, $hr, $pos, $lpos) = @_;
    my @items = $self->children_by_location($hr, $pos, $lpos);
    return ($self->sort_by_name(@items), undef);
}

sub children_by_location {
    my ($self, $hr, $pos, $lpos) = @_;
    unless ($hr) {
        # undef as the first arg initializes this recursive method
        $hr = $self->{menu};
        $self->{returned_children} = [];
    }
    $hr = $self->{menu} unless $hr;
    return undef unless ($lpos);
    foreach my $key (sort {$a <=> $b} keys %$hr) {
        # localize the position variable
        my $pos = $pos;

        if ($pos eq $lpos) {
            my $item = {
                            name    =>  $key,
                            loc     =>  "$pos, $key" };

            unless (ref($hr->{$key})) {
                $item->{tool} = $hr->{$key};
            }

            push (@{$self->{returned_children}}, $item);
        }

        if ($pos) {
            $pos .= ", $key";
        } else {
            $pos = $key;
        }
        if (ref($hr->{$key}) eq "HASH") {
            #print "$key @ $pos\n";
            # the only way to descend is to call this function again with the descending hashref and the localized position
            $self->children_by_location($hr->{$key}, $pos, $lpos);
        } else {
            # this is the end of the road.. a value that isn't a hashref.
            #print "$hr->{$key} @ $pos\n";
        }
    }

    # oh and sort it by the name..
    return (@{$self->{returned_children}});
}

sub sort_by_name {
    my ($self, @items) = @_;
    my (%sh, @nitems);
    
    foreach my $item (@items) {
        $sh{$item->{name}} = $item;
    }

    foreach my $key (sort keys %sh) {
        push(@nitems, $sh{$key});
    }

    return (@nitems);
}

sub parent_menu {
    my ($self, $pos) = @_;
    my $parent;

    if ($pos ne "_top") {
        my @posit = split(/\s*,\s*/, $pos);
        $parent = join(', ', @posit[0..($#posit - 1)]);
    } else {
        $parent = '_top';
    }

    return $parent;
}

sub has_sufficient_access {
    my ($self, $tool) = @_;
    foreach my $flag ($tool->sufficient_flags) {
        return 1 if $self->user->has_flag($flag);
    }
    return undef;
}

sub menu {
    my ($self) = @_;
    return $self->{menu};
}

sub tr {
    my ($self) = @_;
    return $self->{tool_registry};
}

sub user {
    my ($self) = @_;
    return $self->{user};
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

