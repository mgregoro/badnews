# $Id: Formal_resume.pm 441 2006-12-11 21:32:47Z corrupt $
package BadNews::FrontEnd::Formal_resume;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews::FrontEnd::Extension;
use BadNews::GenericCache;
use Apache::Util qw /ht_time/;
use Apache::Constants qw/:common/;

# to process the resume!
use YAML::Syck;

# to create PDFS!
use HTML::HTMLDoc;

my $gc = BadNews::GenericCache->new();

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;
    my $page_cache_duration = $fe->c->PAGE_CACHE_DURATION ? $fe->c->PAGE_CACHE_DURATION : 15 * 60;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;

    if ($http_version >= 1.1) {
        $r->header_out('Cache-Control', 'max-age=' . $page_cache_duration);
    } else {
        $r->header_out('Expires', ht_time(time + $page_cache_duration));
    }

    # pull the view out of the second element of the URI (the first 
    # is formal_resume), default to "default".
    $self->{view} = $uri[1] ? $uri[1] : "default";

    unless ($self->{data} = $gc->get_from_cache($r->hostname)) {
        # re-process the data!
        $self->{data} = LoadFile($r->document_root . "/../conf/resume.yaml");

        $gc->add_to_cache($r->hostname, $self->{data});
    }

    if ($uri[$#uri] eq "resume.pdf") {
        # Render the PDF version if the last element of the URI is resume.pdf

        if ($#uri == 1) {
            # the view still should be "default" if a view wasn't specified
            # in the second element of the URI.
            $self->{view} = "default";
        }

        $r->content_type('application/pdf');
        $r->send_http_header;

        # Process the template into a string for feeding to HTML::HTMLDoc
        my $string;
        $fe->template->process($fe->theme . "/formal_resume.tt2", {
                                fe      =>      $fe,
                                resume  =>      $self,
                                is_pdf  =>      1,
                            }, \$string) or $fe->template->process($fe->theme . '/error.tt2', 
                                { 
                                    error => "Couldn't process " . $fe->theme . "/$page: $!, $@", 
                                    fe    =>      $fe,
                                }, 
                            \$string);

        my $h2pdf = HTML::HTMLDoc->new();

        # configure the PDF
        $h2pdf->set_page_size('letter');
        $h2pdf->set_bodyfont('Arial');
        $h2pdf->set_left_margin(1, 'in');
        $h2pdf->set_html_content($string);

        # generate and print the PDF
        my $pdf = $h2pdf->generate_pdf;
        print $pdf->to_string();

    } else {
        # Render the HTML version

        $r->content_type('text/html');
        $r->send_http_header;

        # rather than use render page, we need to use template->process so we can include the resume data!
        #$fe->render_page("article_resume.tt2");
        $fe->template->process($fe->theme . "/formal_resume.tt2", {
                                fe      =>      $fe,
                                resume  =>      $self
                            }) or $fe->template->process($fe->theme . '/error.tt2', 
                            { 
                                error => "Couldn't process " . $fe->theme . "/$page: $!, $@", 
                                fe    =>      $fe
                            }
                        );
    }

    return OK;
}

sub view {
    my ($self) = @_;
    return $self->{view};
}

sub data {
    my ($self) = @_;
    return $self->{data};
}

# finds views for a certain node recursively.
sub find_views {
    my ($self, $node, $data, $views) = @_;

    my $found_views;

    unless ($views) {
        # prime the views!
        if ($data->{views}) {
            $views = $data->{views};
        } else {
            $views = ["all"];
        }
    }

    # skip all this nonsense if we can :D
    if ($node == $data) {
        return $views;
    }

    # look through this node's children trying to find a matching ref!
    if (ref($data) eq "HASH") {
        # behaviorally a nested hashref needs to be searched through differently than a 
        # nested arrayref.  hashes here... ###
        foreach my $key (keys %{$data}) {
            if (ref($data->{$key}) eq "HASH") {
                $views = exists($data->{$key}->{views}) ? $data->{$key}->{views} : $views;
            }

            if ($node == $data->{$key}) {
                return $views;
            } else {
                # recurse!
                $found_views = $self->find_views($node, $data->{$key}, $views);
                last if $found_views;
            }
        }
    } elsif (ref($data) eq "ARRAY") {
        ### and arrays here.
        my $parent_views = $views;
        foreach my $val (@{$data}) {
            # don't munge views!
            if (ref($val) eq "HASH") {
                $views = exists($val->{views}) ? $val->{views} : $parent_views;
            }

            if ($node == $val) {
                return $views;
            } else {
                # recurse!
                $found_views = $self->find_views($node, $val, $views);
                last if $found_views;
            }
        }
    }

    if ($found_views) {
        return $found_views;
    } else {
        return undef;
    }
}

# recursively pull sub items
sub sub_items {
    my ($self, $items, $level, $views) = @_;
    my @sub_items;
    $level = 1 unless $level;
    $views = "all" unless $views;
    foreach my $item (@{$items->{sub_items}}) {
        $item->{level} = $level;
        push (@sub_items, $item);
        if (exists($item->{sub_items})) {
            push(@sub_items, $self->sub_items($item, $level + 1, $views));
        }
    }
    return (@sub_items);
}

# returns an arrayref instead of an array.  template toolkit always 
# treats array refs as lists.. it was treating a single value real
# array like a scalar and couldn't be coerced even with the .list 
# virtual method.
sub sub_items_ref {
    my ($self, $items, $level, $views) = @_;
    my @sub_items = $self->sub_items($items, $level, $views);
    return \@sub_items;
}

# simple method that returns true if a node has a certain view.
sub has_view {
    my ($self, $node, $view) = @_;

    # everyone has the "all" view ;)
    return 1 if $view eq "all";

    foreach my $check_view (@{$self->find_views($node, $self->data)}) {
        if ($view eq $check_view) {
            return 1;
        }
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

