# the badnews front end module
# $Id: FrontEnd.pm 461 2007-05-01 20:18:55Z corrupt $
# unites all of the other modules into one usable module

package BadNews::FrontEnd;

@ISA = ('BadNews');
use BadNews::Config;
use BadNews::Links;
use BadNews::Author;
use BadNews::User;
use BadNews::Article;
use BadNews::File::Search;
use BadNews::File;
use BadNews::Session;
use BadNews::CalendarInterface;
use BadNews::ArticleInterface;
use BadNews::ReferrerInterface;
use BadNews::DrawCalendar;
use BadNews::Calendar;
use BadNews::Calendar::Event;
use BadNews::Calendar::Day;
use BadNews::TagInterface;
use BadNews::Tag;
use BadNews::Copy;
use Time::HiRes;
use Apache::Request;
use Apache::Cookie;
use Apache::Constants qw /:common/;
use Apache::Util qw /ht_time/;
use BadNews;
use Template;
use Carp;

our ($tc, $cc, $ec);

if ($ENV{MOD_PERL}) {
    use BadNews::TemplateCache;
    $tc = BadNews::TemplateCache->new();

    use BadNews::ConfigCache;
    $cc = BadNews::ConfigCache->new();

    use BadNews::ExtensionCache;
    $ec = BadNews::ExtensionCache->new();
}

sub new {
    my ($class, %attrs) = @_;
    my $self = bless(\%attrs, $class);
    $self->{bn} = BadNews->new();
    $self->{theme} = $attrs{theme} ? $attrs{theme} : $self->{bn}->c->DEFAULT_THEME;
    $self->{anon_session} = $attrs{anon_session} ? $attrs{anon_session} : undef;
    $self->{user_session} = $attrs{user_session} ? $attrs{user_session} : undef;
    my $tcd = $self->{bn}->c->TEMPLATE_COMPILE_DIR ? $self->{bn}->c->TEMPLATE_COMPILE_DIR : "/tmp/";

    # is it cached?
    unless ($self->{tmpl} = $tc->get_from_cache($ENV{SERVER_NAME})) {
        # if not, make a new one
        $self->{tmpl} = Template->new({INCLUDE_PATH         =>      $self->{bn}->c->THEME_PATH,
                                       COMPILE_DIR          =>      $tcd . $self->{bn}->c->COOKIE_DOMAIN,
                                       #DEBUG                =>      'provider',
                                       #DEBUG_FORMAT         =>      '<!-- $file line $line : [% $text %] -->',
                                       TRIM                 =>      1});
        # and cache it!
        $tc->add_to_cache($ENV{SERVER_NAME}, $self->{tmpl});
    }

    $self->{ci} = BadNews::CalendarInterface->new();
    $self->{ai} = BadNews::ArticleInterface->new();
    $self->{ri} = BadNews::ReferrerInterface->new();
    $self->{ti} = BadNews::TagInterface->new();
    $self->{copy} = BadNews::Copy->all();

    return $self;
}

sub DESTROY {
    my $self = (@_);
    $self = undef;
    return $self;
}

sub start_time {
    my ($self) = @_;
    return $self->{start_time};
}

sub time_taken {
    my ($self) = @_;
    return sprintf('%.5f', (Time::HiRes::time() - $self->start_time));
}

sub theme_config {
    my ($self) = @_;
    return $self->tc;
}

# per-theme configuration file
sub tc {
    my ($self) = @_;
    my @paths = split(/:/, $self->{bn}->c->THEME_PATH);
    my $config_file;
    foreach my $path (@paths) {
        $config_file = $path . "/" . $self->theme . "/conf/" . $self->theme . ".xml";
        if (-e $config_file) {
            last;
        } else {
            warn "Attempt to use theme config on " . $self->theme . ": $config_file not found.\n";
            return undef;
        }
    }

    if ($ENV{MOD_PERL}) {
        my $cached_conf = $cc->get_from_cache($ENV{SERVER_NAME} . "_theme_config_" . $self->theme);
        if ($cached_conf) {
            $self->{theme_config} = $cached_conf;
        } else {
            $self->{theme_config} = BadNews::Config->new(ConfigFile  =>  $config_file);
            $cc->add_to_cache($ENV{SERVER_NAME} . "_theme_config_" . $self->theme, $self->{theme_config});
        }
    } else {
        # we're not running under mod perl.. so create the config and return
        $self->{theme_config} = BadNews::Config->new(ConfigFile  =>  $config_file);
    }
    return $self->{theme_config};
}

sub draw_calendar {
    my ($self, $month, $year) = @_;
    return BadNews::DrawCalendar->new($month, $year);
}

# returns an authenticated user, if there is one.. otherwise returns the anon session.
sub session {
    my ($self) = @_;
    my $session;

    if (exists($self->{anon_session})) {
        $session = $self->{anon_session} if $self->{anon_session};
    }

    if (exists($self->{user_session})) {
        $session = $self->{user_session} if $self->{user_session};
    }

    return $session;
}

sub anon_session {
    my ($self) = @_;
    return $self->{anon_session} if exists $self->{anon_session};
}

sub user_session {
    my ($self) = @_;
    return $self->{user_session} if exists $self->{user_session};
}

sub add_user {
    my ($self, $user) = @_;
    return BadNews::User->new(%$user);
}

sub ci {
    my ($self) = @_;
    return $self->{ci};
}

sub ti {
    my ($self) = @_;
    return $self->{ti};
}

sub ai {
    my ($self) = @_;
    return $self->{ai};
}

sub fi {
    my ($self) = @_;
    return $self->{fi};
}

sub all_links {
    my ($self) = @_;
    return BadNews::Links->all_links();
}

sub open_event {
    my ($self, $event_id) = @_;
    return BadNews::Calendar::Event->open($event_id);
}

sub published_events {
    my ($self, $type) = @_;
}

sub day {
    my ($self, $month, $day, $year) = @_;
    return BadNews::Calendar::Day->new("$year$month$day" . "000000");
}

sub cal {
    my ($self, $month, $year) = @_;
    return BadNews::Calendar->new("$year$month" . "01000000");
}

sub file_search {
    my ($self, %criteria) = @_;
    return BadNews::File::Search->new(%criteria);
}

sub all_files {
    my ($self) = @_;
    my $fs = BadNews::File::Search->new(all     =>      1);
    return $fs->results;
}

sub links_by_cat {
    my ($self, $cat) = @_;
    return BadNews::Links->links_by_cat($cat);
}

sub template {
    my ($self) = @_;
    return $self->{tmpl};
}

sub author_by_name {
    my ($self, $author) = @_;
    return BadNews::Author->open_by_name($author);
}

sub cgi {
    my ($self) = @_;
    return $self->{cgi};
}

sub pid {
    my ($self) = @_;
    return $$;
}

sub uri {
    my ($self, $uri) = @_;
    $self->{uri} = $uri if $uri;
    return $self->{uri};
}

sub get_form_injection {
    my ($self) = @_;
    return undef unless $self->{parsed_query_string};

    my $html = $self->session->get_form_injection_html;

    # put the header there if we didnt pull anything out of the session.
    unless ($html) {
        $html = "<!-- get_form_injection - turning your get variables into hidden form elements! -->\n\n";
    }

    foreach my $key (keys %{$self->{parsed_query_string}}) {
        my $test_key = $key;
        $test_key =~ s/([\?\(\)\\\/\+\"])/\\$1/g;
        unless ($html =~ /name="$test_key"/) {
            my $value = $self->{parsed_query_string}->{$key};
            $value =~ s/\"/&quot;/g;
            $html .= '<input type="hidden" name="' . $key . '" value="' . 
                    $value . '">' . "\n";
        }
    }

    $self->session->get_form_injection_html($html);

    return $html;
}

sub query_string {
    my ($self, $query_string) = @_;
    $self->{query_string} = $query_string if $query_string;
    return $self->{query_string};
}

sub parsed_query_string {
    my ($self, $parsed_query_string) = @_;
    $self->{parsed_query_string} = $parsed_query_string if $parsed_query_string;
    return $self->{parsed_query_string};
}

# make it a pass-through!
sub param {
    my $self = shift;
    return $self->cgi->param(@_);
}

sub comma_split {
    my ($self, $string) = @_;
    return split(/,\s*/, $string);
}

sub theme {
    my ($self, $theme) = @_;
    if ($theme) {
        $self->{theme} = $theme;
    }
    return $self->{theme};
}

sub rand_int {
    my ($self, $max) = @_;
    return sprintf('%d', rand($max));
}

sub bn_location {
    my ($self, $bn_location) = @_;
    if ($bn_location) {
        $self->{bn_location} = $bn_location;
    }
    return $self->{bn_location};
}

sub instance {
    my ($self, $instance) = @_;
    if ($instance) {
        $self->{instance} = $instance;
    }
    return $self->{instance};
}

# user agent retrieval!
sub user_agent {
    my ($self, $user_agent) = @_;
    if ($user_agent) {
        $self->{user_agent} = $user_agent;
    }
    return $self->{user_agent};
}

# agent is a robot?
sub agent_is_robot {
    my ($self, $agent_is_robot) = @_;
    if ($agent_is_robot) {
        $self->{agent_is_robot} = $agent_is_robot;
    }
    return $self->{agent_is_robot};
}

# keep it simple, stupid.
sub render_page {
    my ($self, $page, $ns) = @_;
    $page .= ".tt2" unless $page =~ /^.+\.tt2$/o;
    $self->template->process($self->theme . "/" . $page, { fe => $self, ns => $ns }) or $self->template->process($self->theme . '/error.tt2', { error => "Couldn't process " . $self->theme . "/$page: $!, $@", fe => $self, ns => $ns});
}

sub render_error {
    my ($self, $error) = @_;
    $self->template->process($self->theme . "/error.tt2", { fe => $self,  error => $error, ns => $ns });
}

# for apache!
sub handler {
    my $r = shift;
    my $start_time = Time::HiRes::time();
    my $apr = Apache::Request->new($r);
    my $cko = Apache::Cookie->new($r);
    my $cookies = $cko->fetch;
    my $location = $r->location;
    my $bn_location = $location =~ /^\/+$/o ? undef : $location;
    my $uri = $r->uri;
    my ($http_version) = $r->protocol =~ /(\d+\.\d+)/o;
    my $user_agent = $r->header_in('User-Agent');

    # check to see if the agent is a robot...
    my ($agent_is_robot) = $user_agent =~ /(?:check_http|avsearch|gulliver|mercator|bigbrother|inktomi|scooter|appie|newscan-online|libwww-perl|searchtone|asterias|indexer|ync|slurp|seek|crawl|spider|bot|smallbear|lwp|echo|flash|load|link|keynote|agent|map|attache|webtool|sweep|wget|extract|fetch|T-H-U-N-D-E-R-S-T-O-N-E|robot|proxy|libwww|whatsup_gold|cnnit)/io;

    # set environment variables
    $ENV{SERVER_NAME} = $r->hostname;
    $ENV{DOCUMENT_ROOT} = $r->document_root;

    my ($self, $anon_session, $user_session, $cookie);

    my $page = $apr->param('page');
    my $theme = $apr->param('theme');
    my $sticky_theme = $apr->param('sticky_theme');

    if ($cookies->{bnanon}) {
        $anon_session = BadNews::Session->new(session_id        =>      $cookies->{bnanon}->value);
        if ($anon_session) {
            $anon_session->from_cookie(1);
            $anon_session->ip_address($r->connection->remote_ip);
            $anon_session->page_count($anon_session->page_count + 1);
        } else {
            $anon_session = BadNews::Session->new(Anon  =>  1);
            $cookie = Apache::Cookie->new($r,   -name       =>      'bnanon',
                                                -value      =>      $anon_session->session_id,
                                                -path       =>      '/',
                                                -domain     =>      $anon_session->c->COOKIE_DOMAIN
                                            );
            # add the cookie to the request.
            $cookie->bake;
        }
    } else {
        $anon_session = BadNews::Session->new(Anon  =>  1);
        $cookie = Apache::Cookie->new($r,   -name       =>      'bnanon',
                                            -value      =>      $anon_session->session_id,
                                            -path       =>      '/',
                                            -domain     =>      $anon_session->c->COOKIE_DOMAIN
                                        );
        # add the cookie to the request.
        $cookie->bake;
    }

    if ($cookies->{bnauth}) {
        $user_session = BadNews::Session->new(session_id    =>  $cookies->{bnauth}->value);
        if ($user_session) {
            $user_session->ip_address($r->connection->remote_ip);
            $user_session->page_count($user_session->page_count + 1);
            $user_session->from_cookie(1);
        }
    }

    if ($theme) {

        # initialize the front end object...
        $self = BadNews::FrontEnd->new( 
            start_time      =>      $start_time, 
            anon_session    =>      $anon_session, 
            user_session    =>      $user_session, 
            cgi             =>      $apr, 
            instance        =>      $ENV{SERVER_NAME}, 
            theme           =>      $theme, 
            config          =>      $anon_session->user_config, 
            bn_location     =>      $bn_location, 
            agent_is_robot  =>      $agent_is_robot, 
            user_agent      =>      $user_agent,
        );

        if ($sticky_theme) {
            if (ref($user_session) eq "BadNews::Session") {
                $user_session->theme($theme);
            } 
            
            if (ref($anon_session) eq "BadNews::Session") {
                $anon_session->theme($theme);
            }
        }
    } elsif (ref($anon_session) eq "BadNews::Session") {
        if ($anon_session->theme) {
            $self = BadNews::FrontEnd->new( 
                start_time      =>      $start_time, 
                anon_session    =>      $anon_session, 
                user_session    =>      $user_session, 
                cgi             =>      $apr, 
                instance        =>      $ENV{SERVER_NAME}, 
                theme           =>      $anon_session->theme, 
                config          =>      $anon_session->user_config, 
                bn_location     =>      $bn_location, 
                agent_is_robot  =>      $agent_is_robot, 
                user_agent      =>      $user_agent,
            );
        }
    } elsif (ref($user_session) eq "BadNews::Session") {
        if ($user_session->theme) {
            $self = BadNews::FrontEnd->new( 
                start_time      =>      $start_time, 
                anon_session    =>      $anon_session, 
                user_session    =>      $user_session, 
                cgi             =>      $apr, 
                instance        =>      $ENV{SERVER_NAME}, 
                theme           =>      $user_session->theme, 
                config          =>      $anon_session->user_config, 
                bn_location     =>      $bn_location, 
                agent_is_robot  =>      $agent_is_robot, 
                user_agent      =>      $user_agent,
            );
        }
    }

    unless ($self) {
        $self = BadNews::FrontEnd->new(
                start_time      =>      $start_time, 
                anon_session    =>      $anon_session, 
                user_session    =>      $user_session, 
                cgi             =>      $apr, 
                instance        =>      $ENV{SERVER_NAME}, 
                config          =>      $anon_session->user_config, 
                bn_location     =>      $bn_location, 
                agent_is_robot  =>      $agent_is_robot, 
                user_agent      =>      $user_agent,
        );
    }

    # load up the uri..
    $self->uri($uri);

    # get the query string too
    $self->query_string($r->args);

    # get the parsed query string?
    my %pqs = $r->args;
    $self->parsed_query_string(\%pqs);

    # optionally take note of the referrer here.
    if ($self->c->COLLECT_REFERRERS) {
        my $referer = $r->header_in('Referer');
        if ($referer && ($referer !~ /$ENV{SERVER_NAME}/)) {
            BadNews::Referrer->new(full_href        =>          $referer);
        }
    }

    if ($uri =~ /^$location\/*$/og) {
        # this is a base request...
        # regular behavior...
        if ($page eq "css_stylesheet") {
            if ($http_version >= 1.1) { 
                $r->header_out('Cache-Control', 'max-age=' . 3600 * 48); 
            } else {
                $r->header_out('Expires', ht_time(time + 3600 * 48));
            }
        } else {
            if ($http_version >= 1.1) {
                $r->header_out('Cache-Control', 'max-age=' . 15 * 60);
            } else {
                $r->header_out('Expires', ht_time(time + 15 * 60));
            }
        }

        # execute the default extension if one is configured
        if ($self->c->DEFAULT_EXTENSION) {
            my @bn_uri = split(/\//o, $1);

            # handle themes...
            if (lc($bn_uri[0]) eq "theme") {
                $self->theme($bn_uri[1]);

                # set the location to keep track of the theme...
                $self->bn_location($self->bn_location . "/$bn_uri[0]/$bn_uri[1]");

                @bn_uri = @bn_uri[2..$#bn_uri];
            }

            return $self->run_extension($r, $self->c->DEFAULT_EXTENSION, @bn_uri);
        }

        # render the page!
        $r->content_type('text/html');
        $r->send_http_header();
        $page ? $self->render_page($page) : $self->render_page('main_page.tt2');
        return OK;
    } elsif ($uri =~ /^$location\/*(.+)$/og) {
        # break out the uri into little bits
        my $response_content;
        my @bn_uri = split(/\//o, $1);

        # if we have a default extension, and we're configured to override
        # the default dispatcher... do so.
        if ($self->c->DEFAULT_EXTENSION && $self->c->EXTENSION_OVERRIDE) {
            # handle themes...
            if (lc($bn_uri[0]) eq "theme") {
                $self->theme($bn_uri[1]);

                # set the location to keep track of the theme...
                $self->bn_location($self->bn_location . "/$bn_uri[0]/$bn_uri[1]");

                @bn_uri = @bn_uri[2..$#bn_uri];
            }
            return $self->run_extension($r, $self->c->DEFAULT_EXTENSION, @bn_uri);
        }

        my $image_cache_duration = $self->c->IMAGE_CACHE_DURATION ? $self->c->IMAGE_CACHE_DURATION : 3600 * 48;
        my $css_cache_duration = $self->c->CSS_CACHE_DURATION ? $self->c->CSS_CACHE_DURATION : 3600 * 48;
        my $page_cache_duration = $self->c->PAGE_CACHE_DURATION ? $self->c->PAGE_CACHE_DURATION : 15 * 60;

        # allow for theme switch in the url.. this is kinda hott.. everything else should
        # behave as normal ;)
        if (lc($bn_uri[0]) eq "theme") {
            $self->theme($bn_uri[1]);

            # set the location to keep track of the theme...
            $self->bn_location($self->bn_location . "/$bn_uri[0]/$bn_uri[1]");

            @bn_uri = @bn_uri[2..$#bn_uri];
            unless (scalar(@bn_uri)) {
                $r->content_type('text/html');
                $r->send_http_header();
                $self->render_page('main_page.tt2');
                return OK;
            }
        }

        # figure out what we have / load image / file data... legacy style
        if ($self->c->LEGACY_THEMES) {
            if (lc($bn_uri[$#bn_uri - 1]) eq "style") {
                # this is a stylesheet. if it looks like it's got style
                my ($css_theme) = $bn_uri[$#bn_uri] =~ /^(\w+)\./;
                my $page = "css_stylesheet";

                # set our theme to whatever css this is asking for..
                $self->theme($css_theme);
                if ($http_version >= 1.1) {
                    $r->header_out('Cache-Control', 'max-age=' . $css_cache_duration);
                } else {
                    $r->header_out('Expires', ht_time(time + $css_cache_duration));
                }
                $r->content_type('text/css');
                $r->send_http_header;
                $self->render_page($page);
                return OK;
            } elsif (lc($bn_uri[$#bn_uri - 2]) eq "theme_images") {
                my $theme = lc($bn_uri[$#bn_uri -1]);
                my $image = $bn_uri[$#bn_uri];
                my @paths = split(/:/, $self->c->THEME_PATH);
                my ($image_file, $media_type);

                foreach my $path (@paths) {
                    $image_file = $path . "/" . $theme . "/images/" . $image;
                    last if -e $image_file;
                    undef $image_file;
                }

                unless ($image_file) {
                    $r->content_type('text/html');
                    $r->send_http_header;
                    #$self->template->process($self->theme . '/error.tt2', { error => "Can't find the file: $image\n, $!, $@"});
                    $self->render_error("Can't find the file: $image\n, $!, $@");
                    return OK;
                }

                # try and get the mime type from the file name
                if ($image =~ /\.gif/o) {
                    $media_type = "image/gif";
                } elsif ($image =~ /\.png/o) {
                    $media_type = "image/png";
                } elsif ($image =~ /\.jpe?g$/o) {
                    $media_type = "image/jpeg";
                } elsif ($image =~ /\.xpm$/o) {
                    $media_type = "image/xpm";
                } elsif ($image =~ /\.tif{1,2}/o) {
                    $media_type = "image/tiff";
                } else {
                    $media_type = "image/unknown";
                }

                # get ready to take in file_data...
                my $file_data;

                if (open(IMAGE, '<', $image_file)) {
                    local $/;
                    $file_data = <IMAGE>;
                    close(IMAGE);
                }

                if ($http_version >= 1.1) {
                    $r->header_out('Cache-Control', 'max-age=' . $image_cache_duration);
                } else {
                    $r->header_out('Expires', ht_time(time + $image_cache_duration));
                }
                $r->content_type($media_type);
                $r->header_out('Content-Length', length($file_data));
                $r->send_http_header;
                print $file_data;
            } elsif (lc($bn_uri[$#bn_uri - 1] eq "files")) {
                # this is a file.
                my $file_name = $bn_uri[$#bn_uri];

                # declare the file variable..
                my $file;
                if ($file_name =~ /^\d+$/o) {
                    $file = BadNews::File->open_by_id($file_name);
                } else {
                    $file = BadNews::File->open($file_name);
                }

                if ($file) {
                    $r->content_type($file->media_type);
                    $r->header_out('Content-Length', $file->size);
                    if ($http_version >= 1.1) {
                        $r->header_out('Cache-Control', 'max-age=' . $image_cache_duration);
                    } else {
                        $r->header_out('Expires', ht_time(time + $image_cache_duration));
                    }
                    $r->send_http_header;
                    print $file->data;
                } else {
                    # error...
                    $r->content_type('text/html');
                    $r->send_http_header;
                    #$self->template->process($self->theme . '/error.tt2', { error => "Can't find the file: $file_name\n, $!, $@"});
                    $self->render_error("Can't find the file: $file_name\n, $!, $@\n");
                    return OK;
                }
            } 
        }
        # end legacy theme stuff

        # load and run extensions for everyone else..
        return $self->run_extension($r, @bn_uri);

    } else {
        $r->content_type('text/plain');
        $r->send_http_header;
        print "Location: $location, URI: $uri\n";
        return OK;
    }
}

sub run_extension {
    my ($self, $r, @bn_uri) = @_;

    my $ec;
    if ($BadNews::FrontEnd::ec) {
        $ec = $BadNews::FrontEnd::ec;
    } else {
        warn "No extension cache found in the BadNews::FrontEnd namespace -- extension performance will suffer greatly.\n";
    }

    if (my $eobj = $ec->get_from_cache($bn_uri[0])) {
        # it's in the cache...
        # set the fe property for convenience purposes
        $eobj->fe($self);
        return $eobj->handle_request($self, $r, @bn_uri);
    } else {
        my $extension = ucfirst($bn_uri[0]);
        if ($extension =~ /[^A-Za-z:]+/) {
            $extension = "Hacker";
        } else {
            warn "Loading legit extension: $extension\n";
        }
        my $bn_namespace = 1;
        eval "use BadNews::FrontEnd::$extension;";
        if ($@) {
            eval "use $extension;";
            if ($@) {
                $r->content_type('text/html');
                $r->send_http_header;
                #$self->template->process($self->theme . '/error.tt2', { error => "Don't know how to handle $extension ($bn_uri[0])... $@", fe   =>  $self });
                $self->render_error("Don't know how to handle $extension ($bn_uri[0])... <br/> More info: $@");
                return OK;
            }
            $bn_namespace = 0;
        }

        # This is a possible security hole, as it allows people to load arbitrary perl modules, so I'll give users a "way out"
        if (!$bn_namespace && $self->c->PARANOID) {
            $r->content_type('text/html');
            $r->send_http_header;
            #$self->template->process($self->theme . '/error.tt2', { error => "Illegal load of extension outside of the bN namespace $extension with <paranoid> set to true!" });
            $self->render_error("Illegal load of extension outside of the bN namespace $extension with <paranoid> set to true!");
            return OK;
        }
        my $eobj;

        if ($bn_namespace) { 
            eval "\$eobj = BadNews::FrontEnd::$extension->new();";
        } else {
            eval "\$eobj = $extension->new();";
        }

        if ($@) {
            $r->content_type('text/html');
            $r->send_http_header;
            #$self->template->process($self->theme . '/error.tt2', { error => "Error creating extension object for $extension..." });
            $self->render_error("Error creating extension object for extension... $@");
            return OK;
        }

        if (ref($eobj)) {
            unless ($eobj->isa("BadNews::FrontEnd::Extension")) {
                $r->content_type('text/html');
                $r->send_http_header;                
                #$self->template->process($self->theme . '/error.tt2', { error => "Not an extension object..." });
                $self->render_error("Not an extension object...");
                return OK;
            }
        } else {
            $r->content_type('text/html');
            $r->send_http_header;
            #$self->template->process($self->theme . '/error.tt2', { error => "Not an object at all... :(" });
            $self->render_error("Not an object at all ... :(");
            return OK;
        }

        # the cache checks to see that it is a true BadNews::FrontEnd::Extension object.. so we won't duplicate that work here..
        $ec->add_to_cache($bn_uri[0], $eobj);

        # for convenience.. 
        $eobj->fe($self);
        return $eobj->handle_request($self, $r, @bn_uri);
    }

}
                                        
1;
