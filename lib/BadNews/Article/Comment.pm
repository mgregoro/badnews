#
# $Id: Comment.pm 448 2007-02-09 02:19:34Z corrupt $
# the article comments system
#

package BadNews::Article::Comment;

@ISA = ('BadNews');
use BadNews;
use Carp;

# used to hold the children...
our @children;

# used to cache children counts...
our $cc = {};

sub new {
    my ($class, %attribs) = @_;

    my $self = bless({}, $class);
    # take inventory
    unless ($attribs{name} && $attribs{comment} && $attribs{article_id}) {
        croak "Must specify article_id, name, and comment!";
    }

    if ($self->c->STRICT_COMMENTS) {
        # check that we have a valid session
        unless (ref($attribs{session}) eq "BadNews::Session") {
            croak "Must specify session (a BadNews::Session object) with strict_comments set to true!";
        }

        # check that we have a session from a cookie!
        unless ($attribs{session}->from_cookie) {
            croak "Must have a session initiated from a cookie to post comments with strict_comments set to true!";
        }

        my $min_page_count = $self->c->MINIMUM_PAGES_TO_POST ? $self->c->MINIMUM_PAGES_TO_POST : 1;

        # check that we aren't a first hit poster ;)
        unless ($attribs{session}->page_count > $min_page_count) {
            # blacklist here...
            croak "Comment without reading! tsk tsk! with strict_comments set to true!";
        }

        # this can be a part of strict comments...
        # check the banned word list...
        if ($self->contains_banned_word(\%attribs)) {
            croak "Comment contains a banned word! tsk tsk! with strict_comments set to true!";
        }
    }

    # find out if we're using the baysien filtering
    if ($self->c->FILTER_COMMENTS) {
        eval "use Mail::SpamAssassin;";     # check to make sure we can even do this
        if ($@) {
            croak "Can't use SpamAssassin, set <filter_comments> in badnews.xml to 0";
        }

        # Configure SpamAssassin
        my $config_text;
        $config_text .= "bayes_path " . $self->c->DIR . "/spam_bayes_data.dat\n";
        $config_text .= "include /path/to/global/config.conf\n";

        # Load SpamAssassin
        my $sa = Mail::SpamAssassin->new(config_text    =>  $config_text);

        # parse the comment..
        my $parsed_comment = $sa->parse($attribs{comment}, 1);

        # evaluate the spam
        my $status = $sa->check($parsed_comment);

        if ($status->is_spam) {
            $status->finish;
            $parsed_comment->finish;
            croak "Message deemed spam by spamassassin, thou shalt not pass.";
        }
        $status->finish;
        $parsed_comment->finish;
    }

    if ($self->c->THREADED_COMMENTS) {
        croak "Must specify parent_id if THREADED_COMMENTS set to true" unless exists $attribs{parent_id};
        $attribs{parent_id} = $attribs{parent_id} ? $attribs{parent_id} : 0;
    } else {
        $attribs{parent_id} = 0;
    }

    # check for http:// in front of the url
    if ($attribs{url}) {
        unless ($attribs{url} =~ /^http[s]*:\/\//) {
            $attribs{url} = 'http://' . $attribs{url};
        }
        if ($attribs{url} =~ /\@/) {
            # no e-mail addresses!
            delete($attribs{url});
        }
    }

    # check for a user object in there.
    if (ref($attribs{user}) eq "BadNews::User") {
        # this is a user object! pull the other stuff out of there!
    }

    if (my $session = $attribs{session}) {
        $self->log($session->user, "add_comment", $session->ip_address . " left comment $attribs{subject}");
    }

    $attribs{comment} =~ s/([^\w\s\-\.[\<br\>]])/sprintf('&#%02X;', ord($1))/seg;

    $self = bless(\%attribs, $class);

    $self->save;

    # if we got here, we should clear the cache.
    undef $cc;

    return $self;
}

sub open {
    my ($class, $id, $level) = @_;
    my $self;

    if (ref($class) eq "BadNews::Article::Comment") {
        $self = $class;
    } else {
        $self = bless({}, $class);
    }

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, subject, name, url, comment, create_time, article_id, parent_id from comments where id = $id");
    $sth->execute;
    my $hr = $sth->fetchrow_hashref;

    $self = bless($hr, $class);

    # set a level of some sort
    $self->{level} = $level ? $level : "0";

    # return the object :D
    return $self;
}

sub objectify {
    my ($class, $hr, $level) = @_;

    if (ref($hr) ne "HASH") {
        croak "Must specify a hash ref as the first argument.. must contain id, subject, name, url, comment, create_time, article_id, and parent_id.";
    }

    my $self =  bless($hr, $class);
    $self->{level} = $level ? $level : "0";

    return $self;
}

# simple enough.. deletes the comment
sub delete {
    my ($self) = @_;
    if ($self->id) {
        my $dbh = $self->open_db;

        # make sure to move the children comments to this comments' parent if deleted!

        $dbh->do("update comments set parent_id = " . $self->parent_id . " where parent_id = " . $self->id);
        $dbh->do("delete from comments where id = " . $self->id);
        return 1;
    } 
    return undef;
}

sub learn_as_spam {
    my ($self) = @_;
    if ($self->c->FILTER_COMMENTS) {
        eval "use Mail::SpamAssassin;";     # check to make sure we can even do this
        if ($@) {
            croak "Can't use SpamAssassin, set <filter_comments> in badnews.xml to 0";
        }

        # Configure SpamAssassin
        my $config_text;
        $config_text .= "bayes_path " . $self->c->DIR . "/spam_bayes_data.dat\n";
        $config_text .= "include /path/to/global/config.conf\n";

        my $sa = Mail::SpamAssassin->new(config_text    =>  $config_text);

        # parse the comment..
        my $parsed_comment = $sa->parse($self->comment, 1);

        # evaluate the spam
        my $status = $sa->check($parsed_comment);
        
        # learn that this message is spam
        $sa->learn($parsed_comment, "bN_" . $self->c->COOKIE_DOMAIN . $self->id, 1);
    }
    $status->finish;
    $parsed_comment->finish;

    # finally, delete yourself!
    $self->delete;
}

sub contains_banned_word {
    my ($self, $attr) = @_;

    # turn the entire comment into one string for checking against the word regex.
    my $comment_string;
    for (keys %$attr) {
        $comment_string .= $attr->{$_} unless ref($_);
    }

    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id, word from c_banned_words");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        my $word = $$ar[1];
        if ($comment_string =~ /$word/i) {
            $self->log("not_available", "banned_comment", "comment from " . $attr->{session}->ip_address . " contains banned word $word.  Banned word id: $$ar[0]");
            return 1;
        }
    }
    return undef;
}

# shorthand method for direct_children
sub dc {
    $_[0]->direct_children;
}

# the direct descendents of this comment
sub direct_children {
    my ($self) = @_;

    my @comments;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
        select id, subject, name, url, comment, create_time, article_id, parent_id 
            from comments
            where parent_id = ?
            order by create_time $sort_order
        /);
    $sth->execute($self->id);

    while (my $hr = $sth->fetchrow_hashref) {
        push(@comments, BadNews::Article::Comment->objectify($hr));
    }

    return @comments;
}

# new and improved count_children with caching :D
sub count_children {
    my ($self) = @_;
    if (exists($cc->{$ENV{SERVER_NAME}}->{$self->id})) {
        # if the cache is older than c->THREADED_COMMENTS_CACHE seconds...
        if ((time - $cc->{$ENV{SERVER_NAME}}->{$self->id}->{age}) > $self->c->THREADED_COMMENTS_CACHE) {
            # recache, and return
            $cc->{$ENV{SERVER_NAME}}->{$self->id}->{age} = time;
            $cc->{$ENV{SERVER_NAME}}->{$self->id}->{value} = scalar($self->children);
            return $cc->{$ENV{SERVER_NAME}}->{$self->id}->{value};
        } else {
            # just return what we have in the cache
            return $cc->{$ENV{SERVER_NAME}}->{$self->id}->{value};
        }
    } else {
        $cc->{$ENV{SERVER_NAME}}->{$self->id}->{age} = time;
        $cc->{$ENV{SERVER_NAME}}->{$self->id}->{value} = scalar($self->children);
        return $cc->{$ENV{SERVER_NAME}}->{$self->id}->{value};
    }
}

# return all children (recursive)
sub children {
    my ($self, $level) = @_;
    unless ($level) {
        undef(@children);
    }
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
        select id, subject, name, url, comment, create_time, article_id, parent_id 
            from comments
            where parent_id = ?
            order by create_time $sort_order
        /);
    $sth->execute($self->id);
    while (my $hr = $sth->fetchrow_hashref) {
        my $child = BadNews::Article::Comment->objectify($hr, $level + 1);
        push(@children, $child);
        $child->children($level + 1);
    }
    return (@children);
}
    
sub save {
    my ($self) = @_;
    my $dbh = $self->open_db;

    if ($self->id) {
        # this is an update...
        my $res = $dhh->do("update comments set name = " . $dbh->quote($self->name) . ", url = " . $dbh->quote($self->url) . 
                ", comment = " . $dbh->quote($self->comment) . ", subject = " . $dbh->quote($self->subject) . 
                ", parent_id = " . $dbh->quote($self->parent_id) . " where id = " . $self->id);
        return $res;
    } else {
        # this is new...
        my $res = $dbh->do("insert into comments (subject, name, url, comment, create_time, article_id, parent_id) VALUES (" .
                $dbh->quote($self->subject) . ", " . $dbh->quote($self->name) . ", " . $dbh->quote($self->url) . ", " . $dbh->quote($self->comment) . 
                ", now(), " . $self->article_id . ", " . $self->parent_id  . ")");
        $self->{id} = $dbh->{mysql_insertid};
        return $res;
    }
}
     
sub id {
    my ($self) = @_;
    return ($self->{id});
}

sub name {
    my ($self, $name) = @_;
    $self->{name} = $name ? $name : $self->{name};
    return ($self->{name});
}

sub url {
    my ($self, $url) = @_;
    $self->{url} = $url ? $url : $self->{url};
    return ($self->{url});
}

sub comment {
    my ($self, $comment) = @_;
    $self->{comment} = $comment ? $comment : $self->{comment};
    return ($self->{comment});
}

sub subject {
    my ($self, $subject) = @_;
    $self->{subject} = $subject ? $subject : $self->{subject};
    return ($self->{subject});
}

sub article_id {
    my ($self) = @_;
    return ($self->{article_id});
}

sub level {
    my ($self, $level) = @_;
    $self->{level} = $level ? $level : $self->{level};
    return ($self->{level});
}

sub parent_id {
    my ($self, $id) = @_;
    $self->{parent_id} = $id ? $id : $self->{parent_id};
    return ($self->{parent_id});
}

1;
