
# $Id: Extension.pm 460 2007-03-21 16:57:07Z corrupt $
# the BadNews::FrontEnd::Extension package

package BadNews::FrontEnd::Extension;

@ISA = ('BadNews');

use BadNews;

sub new {
    my ($class, $fe, $r) = @_;
    return bless({}, $class);
}

sub fe {
    my ($self, $fe) = @_;
    if (defined($fe)) {
        $self->{fe} = $fe;
    }
    return $self->{fe};
}

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;

    $r->content_type('text/html');
    $r->send_http_header();
    $fe->template->process($self->theme . "/error.tt2", { error => "Default request handler error, load an extention with a handle_request method for this :~(" });
}

sub render_page {
    my ($self, $page, $ns) = @_;
    $page .= ".tt2" unless $page =~ /^.+\.tt2$/o;
    $self->fe->template->process($self->fe->theme . '/' . $page,
        {   
            fe      =>      $self->fe,
            self    =>      $self,
            ns      =>      $ns,
        }
    ) or $self->fe->render_error("Couldn't process " . $self->fe->theme . "/$page: $!, $@", $ns);
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

