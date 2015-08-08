# the BadNews perl module
# $Id: BadNews.pm 441 2006-12-11 21:32:47Z corrupt $
# the base BadNews class

package BadNews;

# declare version!
my $VERSION = '0.21';

# release type (alpha, beta, pre-release, release, stable) a/b/pr/r/s
my $RELEASE = 'b';

use DBI;
use Carp;

# use the xmlified badnews config
use BadNews::Config;

# ToolRegistry baby:)
use BadNews::ToolRegistry;

# initialize config cache object and tr cache
our ($cc, $trc, $dbic);

# also let's cache the config if we're in MOD_PERL
if ($ENV{MOD_PERL}) {
    use BadNews::ConfigCache;
    $cc = BadNews::ConfigCache->new();

    use BadNews::ToolRegistry::Cache;
    $trc = BadNews::ToolRegistry::Cache->new();

    use BadNews::DBICache;
    $dbic = BadNews::DBICache->new();
}

sub new {
    my ($class, %attribs) = @_;
    my $self = bless (\%attribs, $class);
    $self->setup();
    return $self;
}

sub setup {
    my ($self) = @_;
    if ($ENV{MOD_PERL}) {
        my $cached_conf = $cc->get_from_cache($ENV{SERVER_NAME});
        if ($cached_conf) {
            $self->{config} = $cached_conf;
        } else {
            $self->{config} = BadNews::Config->new(ConfigFile =>  "$ENV{DOCUMENT_ROOT}/../conf/badnews.xml");
            $cc->add_to_cache($ENV{SERVER_NAME}, $self->{config});
        }
    } else {
        # we're not running under mod perl..
        # no point in caching anything..
    }
}

sub c {
    my ($self) = @_;
    if ($ENV{MOD_PERL}) {
        my $cached_conf = $cc->get_from_cache($ENV{SERVER_NAME});
        if ($cached_conf) {
            $self->{config} = $cached_conf;
        } else {
            $self->{config} = BadNews::Config->new(ConfigFile =>  "$ENV{DOCUMENT_ROOT}/../conf/badnews.xml") unless $self->{config};
            $self->{config}->{pxml}->{dir} = "$ENV{DOCUMENT_ROOT}/../conf/";
            $cc->add_to_cache($ENV{SERVER_NAME}, $self->{config});
        }
    } else {
        # we're not running under mod perl.. so create the config object and return
        $self->{config} = BadNews::Config->new(ConfigFile =>  "$ENV{DOCUMENT_ROOT}/../conf/badnews.xml");
        $self->{config}->{pxml}->{dir} = "$ENV{DOCUMENT_ROOT}/../conf/";
    }
    return $self->{config};
}

sub tr {
    my ($self) = @_;
    if ($ENV{MOD_PERL}) {
        my $cached_tr = $trc->get_from_cache($ENV{SERVER_NAME});
        if ($cached_tr && $cached_tr ne "EXPIRED") {
            $self->{tr} = $cached_tr;
        } else {
            $self->{tr} = BadNews::ToolRegistry->new() unless $self->{tr};
            $trc->add_to_cache($ENV{SERVER_NAME}, $self->{tr});
        }
    } else {
        # we're not running under mod perl.. so create the config object and return
        $self->{tr} = BadNews::ToolRegistry->new();
    }
    return $self->{tr};
}

sub user_config {
    my ($self) = @_;
    return undef unless -e "$ENV{DOCUMENT_ROOT}/../conf/badnews_user.xml";
    if ($ENV{MOD_PERL}) {
        my $cached_conf = $cc->get_from_cache($ENV{SERVER_NAME} . "user_config");
        if ($cached_conf) {
            $self->{user_config} = $cached_conf;
        } else {
            $self->{user_config} = BadNews::Config->new(ConfigFile  =>  "$ENV{DOCUMENT_ROOT}/../conf/badnews_user.xml") unless $self->{user_config};
            $cc->add_to_cache($ENV{SERVER_NAME} . "user_config", $self->{user_config});
        }
    } else {
        # we're not running under mod perl.. so create the config and return
        $self->{user_config} = BadNews::Config->new(ConfigFile  =>  "$ENV{DOCUMENT_ROOT}/../conf/badnews_user.xml");
    }
    return $self->{user_config};
}

sub log {
    my ($self, $username, $action, $details) = @_;
    return undef unless $username && $action;
    $details = $details ? $details : "none";
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("insert into event_log (username, action, details, timestamp) VALUES (?, ?, ?, now())");
    return $sth->execute($username, $action, $details);
}

sub open_db {
    my ($self) = @_;
    my $dbh;
    if ($ENV{MOD_PERL}) {
        my $cached_dbh = $dbic->get_from_cache("$ENV{SERVER_NAME}");
        if ($cached_dbh && $cached_dbh ne "EXPIRED") {
            $dbh = $cached_dbh;
        } else {
            $dbh = DBI->connect($self->c->DSN, $self->c->DB_USER, $self->c->DB_PASS);
            $dbic->add_to_cache("$ENV{SERVER_NAME}", $dbh);
        }
    } else {
        # we're not running under mod perl.. so create the config object and return
        $dbh = DBI->connect($self->c->DSN, $self->c->DB_USER, $self->c->DB_PASS);
    }
    return $dbh;
}

sub DESTROY {
    # don't destroy a thing!
    my $self = (@_);
    undef $self;
    return $self;
}

sub version {
    my ($self) = @_;
    return "$VERSION";
}

sub version_release {
    my ($self) = @_;
    return "$VERSION$RELEASE";
}

sub pretty_version {
    my ($self) = @_;
    return "BadNews (bNcms) v$VERSION$RELEASE";
}

sub entity_type {
    my ($self) = @_;
    my ($ent_type) = ref($self) =~ /::(\w+)$/;
    return lc($ent_type);
}

1;
__END__

=head1 NAME

C<BadNews> - The base BadNews class

=head1 SYNOPSIS

=head1 DESCRIPTION

Handles database connections, configuration, and logging for the BadNews CMS.

=head1 METHODS

=over 2

=item new

the BadNews constuctor, you will only use this when you're creating tools.

 use BadNews;
 my $bn = new BadNews;

 # get configuration object (BadNews::Config)
 my $c = $bn->c;

 # get user config
 my $uc = $bn->user_config;

=item setup

caches configuration, or pulls the configuration from cache and loats it into the object

=item c

returns the bN configuration object, from cache. (conf/badnews.xml)

=item tr

returns the bN tool registry object

=item user_config

returns the bN user configuration object, from cache. (conf/badnews_user.xml)

=item log

Takes 3 arguments.  The username of the actor, the action, and the details of that action.  This method logs 
the action to the event_log table in the database.

=item open_db

returns a database handle to the instance's database

=back

=head1 KNOWN ISSUES

C<BadNews> has no known issues.

=head1 AUTHOR

Michael Gregorowicz <michael@gregorowicz.com>

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

