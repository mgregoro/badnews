# the article object.  sets and retrieves article data  
# $Id: Article.pm 428 2006-08-30 02:00:57Z corrupt $

package BadNews::Article;

@ISA = ('BadNews');
use BadNews::Article::Comment;
use BadNews::File;
use BadNews::Links;
use BadNews;
use Carp;

# creates a new article
sub new {
    my ($class, %article) = @_;
    my $self = bless(\%article, $class);
    if ($self->subject && $self->body) {
        # we have enough for a post!
        $self->{category} = $self->{category} ? $self->{category} : 'general';
        $self->{published} = $self->{published} ? $self->{published} : 0;
        
        # only default if we weren't passed any value at all...
        $self->{enable_comments} = exists($self->{enable_comments}) ?  $self->{enable_comments} : $self->c->ENABLE_COMMENTS;

        $self->{author} = $self->{author} ? $self->{author} : 'unknown';
        $self->{create_time} = $self->{create_time} ? $self->{create_time} : 'now()';
        my $dbh = $self->open_db;

        $dbh->do("insert into articles (subject, author, category, body, published, create_time, modify_time, associated_files, associated_links, enable_comments) VALUES (" .
                $dbh->quote($self->subject) . ", " . $dbh->quote($self->author) . ", " . $dbh->quote($self->category) . ", " .
                $dbh->quote($self->body) . ", " . $dbh->quote($self->published) . ", $self->{create_time}, now(), " . $dbh->quote($self->associated_files) . ", " .
                $dbh->quote($self->associated_links) . ", " . $dbh->quote($self->enable_comments) . ")");

        $self->{id} = $dbh->{mysql_insertid};
        return BadNews::Article->open($self->id);
    } else {
        croak "can't create article without subject and body.";
    }
}

# opens an existing article
sub open {
    my ($class, $id) = @_;
    my $self = bless({}, $class);
    my $dbh = $self->open_db;

    my $sth = $dbh->prepare("select id, subject, author, category, body, published, create_time, modify_time, associated_files, associated_links, enable_comments from articles where id = $id");
    $sth->execute();

    my $hr = $sth->fetchrow_hashref;

    return undef unless $hr;

    foreach my $key (keys %$hr) {
        $self->{$key} = $hr->{$key};
    }

    return $self;
}

# saves a changed article
sub save {
    my ($self) = @_;

    my $dbh = $self->open_db;

    my $sql = "update articles set ";
    my @attribs = ('subject', 'author', 'category', 'body', 'published', 'associated_files', 'associated_links', 'enable_comments');
    my $i;

    foreach my $attr (@attribs) {
        ++$i;
        if ($i == scalar(@attribs)) {
            $sql .= "$attr = " . $dbh->quote($self->$attr);
        } else {
            $sql .= "$attr = " . $dbh->quote($self->$attr) . ", ";
        }
    }
    $sql .= " where id = " . $self->id;

    $dbh->do($sql);
}

sub delete {
    my ($self) = @_;
    my $dbh = $self->open_db;
    $dbh->do("delete from articles where id = " . $self->id);
}

sub subject {
    my ($self, $subject) = @_;
    $self->{subject} = $subject ? $subject : $self->{subject};
    return ($self->{subject});
}

sub id {
    my ($self) = @_;
    return ($self->{id});
}

sub ucfirst_body {
    my ($self, $pre_tag, $post_tag) = @_;
    my $l_body = $self->body;
    $l_body =~ s/^(.)(.+)$/$2/g;
    return "$pre_tag$1$post_tag$l_body";
}

sub escaped_body {
    my ($self) = @_;
    my $body = $self->{body};
    $body =~ s/"/\\\"/g;
    return $body;
}

sub summary {
    my ($self) = @_;
    return $self->body;
}

sub body {
    my ($self, $body) = @_;
    $self->{body} = $body ? $body : $self->{body};
    return ($self->{body});
}

sub published {
    my $self = shift;
    if (scalar(@_)) {
        $self->{published} = $_[0];
    }
    return ($self->{published});
}

sub clean_category {
    my ($self, $category) = @_;
    my $clean_category = $self->category($category);
    $clean_category =~ s/\[SYS\]\s*//g;
    return $clean_category;
}

sub category {
    my ($self, $category) = @_;
    $self->{category} = $category ? $category : $self->{category};
    return ($self->{category});
}

sub author {
    my ($self, $author) = @_;
    $self->{author} = $author ? $author : $self->{author};
    return ($self->{author});
}

sub create_time {
    my ($self) = @_;
    return ($self->{create_time});
}

sub modify_time {
    my ($self) = @_;
    return $self->{modify_time} ? $self->{modify_time} : $self->{create_time};
}

sub is_last {
    my ($self) = shift;
    if (scalar(@_)) {
        $self->{is_last} = $_[0];
    }
    return ($self->{is_last});
}

sub associated_files {
    my $self = shift;
    if (scalar(@_)) {
        $self->{associated_files} = $_[0];
    }
    return ($self->{associated_files});
}

sub associated_links {
    my $self = shift;
    if (scalar(@_)) {
        $self->{associated_links} = $_[0];
    }
    return ($self->{associated_links});
}

sub associate_file {
    my ($self, $file_id) = @_;

    # make sure this file isn't already associated
    return undef if $self->file_is_associated($file_id);

    if ($self->associated_files) {
        $self->{associated_files} .= ":$file_id";
        return 1;
    } else {
        $self->{associated_files} = $file_id;
        return 1;
    }
    return undef;
}

sub associate_link {
    my ($self, $link_id) = @_;

    return undef if $self->link_is_associated($link_id);

    if ($self->associated_links) {
        $self->{associated_links} .= ":$link_id";
        return 1;
    } else {
        $self->{associated_links} = $link_id;
        return 1;
    } 
    return undef;
}

sub link_is_associated {
    my ($self, $link_id) = @_;
    if (($self->associated_links) && ($link_id)) {
        foreach my $id (split(/:/, $self->associated_links)) {
            return 1 if $link_id eq $id;
        }
        return undef;
    } else {
        return undef;
    }
}

sub file_is_associated {
    my ($self, $file_id) = @_;
    if (($self->associated_files) && ($file_id)) {
        foreach my $id (split(/:/, $self->associated_files)) {
            return 1 if $file_id eq $id;
        }
        return undef;
    } else {
        return undef;
    }
}

sub deassociate_file {
    my ($self, $file_id) = @_;
    if ($self->associated_files) {
        my @files;
        foreach my $id (split(/:/, $self->associated_files)) {
            push(@files, $id) unless $id eq $file_id;
        }
        $self->{associated_files} = join(':', @files);
    }
}

sub deassociate_link {
    my ($self, $link_id) = @_;
    if ($self->associated_links) {
        my @links;
        foreach my $id (split(/:/, $self->associated_links)) {
            push(@links, $id) unless $id eq $link_id;
        }
        $self->{associated_links} = join(':', @links);
    }
}

sub files {
    my ($self) = @_;
    if ($self->associated_files) {
        my @files;
        foreach my $id (split(/:/, $self->associated_files)) {
            push (@files, BadNews::File->open_by_id($id));
        }
        return @files;
    } else {
        return (undef);
    }
}

sub links {
    my ($self) = @_;
    if ($self->associated_links) {
        my @links;
        foreach my $id (split(/:/, $self->associated_links)) {
            push (@links, BadNews::Links->open($id));
        }
        return @links;
    } else {
        return undef;
    }
}

sub enable_comments {
    my $self = shift;
    if (scalar(@_)) {
        $self->{enable_comments} = $_[0];
    }
    return ($self->{enable_comments});
}

sub comments {
    my ($self, $sort_order) = @_;
    return undef unless $self->enable_comments;

    if ($self->c->THREADED_COMMENTS) {
        return $self->threaded_comments($sort_order);
    }
    $sort_order = $sort_order ? $sort_order : "asc";
    my @comments;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
        select id, subject, name, url, comment, create_time, article_id, parent_id 
            from comments
            where article_id = ?
            order by create_time $sort_order
        /);
    $sth->execute($self->id);
    while (my $hr = $sth->fetchrow_hashref) {
        push(@comments, BadNews::Article::Comment->objectify($hr));
    }
    return (@comments);
}

sub threaded_comments {
    my ($self, $sort_order) = @_;

    $sort_order = $sort_order ? $sort_order : "asc";
    my @comments;

    # iterate through all comments $comment->children() is recursive
    foreach my $comment ($self->base_comments) {
        push(@comments, $comment, $comment->children);
    }

    return (@comments);
}

sub base_comments {
    my ($self, $sort_order) = @_;

    # this is a method for threaded comments only
    return undef unless $self->c->THREADED_COMMENTS;

    my @comments;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare(qq/
        select id, subject, name, url, comment, create_time, article_id, parent_id 
            from comments
            where article_id = ? and parent_id = '0'
            order by create_time $sort_order
        /);
    $sth->execute($self->id);

    while (my $hr = $sth->fetchrow_hashref) {
        push(@comments, BadNews::Article::Comment->objectify($hr));
    }
    return @comments;
}

sub count_comments {
    my ($self) = @_;
    return scalar($self->comments);
}

sub add_comment {
    my ($self, $name, $url, $comment, $irt, $subject, $session) = @_;
    return undef unless $self->enable_comments;

    unless (ref($irt) eq "BadNews::Article::Comment") {
        $irt = BadNews::Article::Comment->open($irt) if $irt;
    }

    my $parent_id;

    if ($self->c->THREADED_COMMENTS) {
        unless (ref($irt) eq "BadNews::Article::Comment") {
            # this comment is a base comment
            $parent_id = 0;
        } else {
            $parent_id = $irt->id;
            if ($irt->article_id ne $self->id) {
                croak "Can't thread a comment in reply to a comment that was not made on this article.";
            }
        }
    }
    
    if ($name && $comment) {
        my $cmnt;
        if (defined($parent_id)) {
            $cmnt = BadNews::Article::Comment->new(   article_id      =>      $self->id,
                                                               name            =>      $name,
                                                               url             =>      $url,
                                                               parent_id       =>      $parent_id,
                                                               subject         =>      $subject,
                                                               session         =>      $session,
                                                               comment         =>      $comment);
        } else {
            $cmnt = BadNews::Article::Comment->new(   article_id      =>      $self->id,
                                                               name            =>      $name,
                                                               url             =>      $url,
                                                               subject         =>      $subject,
                                                               session         =>      $session,
                                                               comment         =>      $comment);
        }
        return $cmnt->id;
    } else {
        return undef;
    }
}

sub delete_comment {
    my ($self, $comment_id) = @_;
    return undef unless $self->enable_comments;
    if ($comment_id) {
        my $comment = BadNews::Article::Comment->open($comment_id);
        if ($comment->article_id eq $self->id) {
            $comment->delete;
            return 1;
        } else {
            # this comment doesn't belong to this article...
            return undef;
        }
    } else {
        return undef;
    }
}

sub next_by_create {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from articles where create_time > " . $dbh->quote($self->create_time) . " and published = '1' order by create_time asc limit 1");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    if ($$ar[0]) {
        return BadNews::Article->open($$ar[0]);
    }
    return undef;
}

sub prev_by_create {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from articles where create_time < " . $dbh->quote($self->create_time) . " and published = '1' order by create_time desc limit 1");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    if ($$ar[0]) {
        return BadNews::Article->open($$ar[0]);
    }
    return undef;
}

=head1 NAME

B<BadNews::Article> - The BadNews Article Class

=head1 SYNOPSIS

 [% FOREACH article = fe.ai.recent_articles(5) %]
     Subject: [% article.subject %]
     Body: [% article.body %]
 [% END %]

=head1 DESCRIPTION

A BadNews article object

Almost all of these methods will be called from template-toolkit.  Because of this, I'll put most examples in
template toolkit form..

=head1 METHODS

=over 2

=item BadNews::Article->B<new(%article)> [perl]

Creates a new article, is also a wrapper around a constructor of the BadNews::Article object.  Takes a hash as 
an argument.  Returns a BadNews::Article object.  Takes the following key value pairs:

Required Attributes:

 subject
 body

Optional Attributes:

 author (if none specified defaults to 'unknown')
 create_time (if none specified defaults to now)
 category (if none specified defaults to 'general')
 published (if none specified defaults to '0')
 enable_comments (if none specified defaults to config file value ENABLE_COMMENTS)
 associated_links (a colon delimited list of link ids)
 associated_files (a colon delimited list of file ids)

Example:

 my $article = BadNews::Article->new(
     author     =>      'Me',
     subject    =>      'This is my subject',
     body       =>      'This is my body',
 );

=item BadNews::Article->B<open($article_id)> [perl / constructor]

Takes an article_id, retrieves article from database, populates a BadNews::Article object and returns it.

Example:

 my $article = BadNews::Article->open(3);

=item BadNews::Article->B<save()> [perl / tt2]

This method takes the current values of the object, and writes them to the database.  It lets you make multiple 
changes without the overhead of multiple writes.

Example(s):


perlish:

 $article->body($new_body);
 $article->subject($new_subject);
 $article->save;

tt2ish:

 [% 
    article.body(new_body)
    article.subject(new_subject)
    article.save
 %]

=item BadNews::Article->B<delete()>

Do I really have to explain this?  Deletes this article from the database.  Returns 1 if successful.o

Example(s):

perlish:

 $article->delete;

tt2ish:

 [% article.delete %]

=item BadNews::Article->B<subject($subject)>

Gets / sets the article subject.  Does not write to the database when you set the value, you must call save().

Example:

 [% article.subject %]

=item BadNews::Article->B<id()>

Returns the current article's unique identifier.

Example:

 [% article.id %]

=item BadNews::Article->B<ucfirst_body()>

This method allows you to put a pre_tag and a post_tag around the first character in the body.. fairy tale style 
you can put whatever html or content you need to before and after it to make it look however you want.

Example:

 [% article.ucfirst_body('<font style="font-size: 72px;">', '</font>') %]

=item BadNews::Article->B<escaped_body()>

Not quite sure why I wrote this.. but.. it escapes all quotes within the entire body and returns it.

Example:

 [% article.escaped_body %]

=item BadNews::Article->B<summary()>

This doesn't do anything but return the body.  It used to have a bunch of logic in it, but it was all deprecated by 
BadNews::ArticleInterface->truncate() which you can use for most things these days.

=item BadNews::Article->B<body($body)>

Gets / sets the article body.  Does not write to the database when you set the value, you must call save().

Example(s):

perlish:

 $article->body($new_body);
 $article->save;

tt2ish:

 [% article.body %]

=item BadNews::Article->B<published($published)>

Gets / sets the article published flag.  Does not write to the database when you set the value, you must call save().

Example(s):

 [% IF article.published %]
     [% article.body %]
 [% END %]

=item BadNews::Article->B<clean_category()>

Cleans the [SYS] out of system categories.  And returns the category.  System categories are really lame and are kind of a hack.  C<A better 
way> (tm) to handle this should be devised.

Example:

 [% article.clean_category %]

=item BadNews::Article->B<category($category)>

Gets / sets the article's category.  Does not write to the database when you set the value, you must call save().

Example:

 [% article.category %]

=item BadNews::Article->B<author($author)>
 
Gets / sets the article's author.  Does not write to the database when you set the value, you must call save().

Example:

 Written by: [% article.author %]

=item BadNews::Article->B<create_time()>

Gets the article create time.

Example:

 Created on: [% article.create_time %]

=item BadNews::Article->B<modify_time()>

Gets the article's last modified timestamp.  If there is no last modified timestamp, it returns the create_time.

Example:

 Last modified date: [% article.modify_time %]

=item BadNews::Article->B<is_last($is_last)>

Returns true if this article is the last article in the list.  Call is_last(1) on the last object after sorting an 
array of objects.

Example:

 ... sort objects in @articles yadda yadda ...
 $articles[$#articles]->is_last(1);

=item BadNews::Article->B<associated_files($associated_files)>

Gets / sets the string version of the associated files, this is colon delimited string of file ids.  Does not write 
to the database when you set the value, you must call save().

Example:

 @associated_file_ids = split(/:/, $article->associated_files);

=item BadNews::Article->B<associated_links($associated_links)>

Gets / sets the string version of the associated links, this is colon delimited string of link ids.  Does not write 
to the database when you set the value, you must call save().

Example:

 @associated_link_ids = split(/:/, $article->associated_links);

=item BadNews::Article->B<associate_file($file_id)>

Associates a file (by id) with the current article.  Returns true if the file has been associated.  Does not write
to the database when you set the value, you must call save().

Example:

 $article->associate_file($file->id);

=item BadNews::Article->B<associate_link($link_id)>

Associates a link (by id) with the current article.  Returns true if the link has been associated.  Does not write
to the database when you set the value, you must call save().

Example:

 $article->associate_link($file->id);

=item BadNews::Article->B<file_is_associated($file_id)>

Returns true if the passed file id is associated with the current article.

Example:

 if ($article->file_is_associated($file->id)) { ... }

=item BadNews::Article->B<link_is_associated($link_id)>

Returns true if the passed link id is associated with the current article.

Example:

 if ($article->link_is_associated($link->id)) { ... }

=item BadNews::Article->B<deassociate_file($file_id)>

Deassociates the specified file by file id.

Example:

 $article->deassociate_file($file->id);

=item BadNews::Article->B<deassociate_link($link_id)>

Deassociates the specified link by link id.

Example:

 $article->deassociate_link($link->id);

=item BadNews::Article->B<files()>

Returns an array of BadNews::File objects representing all of the current article's associated files.

Example:

 foreach $file ($article->files()) { ... }

=item BadNews::Article->B<links()>

Returns an array of BadNews::Links objects representing all of the current article's associated links.

Example:

 foreach $link ($article->links()) { ... }

=item BadNews::Article->B<enable_comments($enable_comments)>

Gets / sets the flag (0 or 1) for enabling comments for the current article.  Does not write to the database, you 
must call save().

Example:

 [% IF article.enable_comments %]
    [%# some comments code %]
 [% END %]

=item BadNews::Article->B<comments($sort_order)>

Returns an array of BadNews::Article::Comment objects representing all of the current article's comments.  If 
threaded_comments is configured in the badnews.xml file, it wraps around BadNews::Article->B<threaded_comments()> 
(see below).  Takes 'asc' or 'desc' as a sort order and sorts by the create time.  If comments are threaded and are 
in reply to other comments, they come back in thread order, and then ordered by create time under the threads.

Example:

 [% FOREACH comment = article.comments %]
    [%# print them out %]
 [% END %]

=item BadNews::Article->B<threaded_comments($sort_order)>

Returns comments in thread order.  Not sure what will happen if you call this without threaded_comments configured 
in badnews.xml.

Example:

 @threaded_comments = $article->threaded_comments();

=item BadNews::Article->B<base_comments($sort_order)>

Returns a list of base comments (comments with no parents).  You can use this method to start your own original 
rendering of the comments tree.

Example:

 @base_comments = $article->base_comments();

=item BadNews::Article->B<count_comments()>

Returns the number of comments on the current article.

Example:

 [% article.count_comments %] comments on this article.

=item BadNews::Article->B<add_comment($name, $url, $comment, $in_reply_to, $subject)>

Adds a comment to the current article.  Takes 5 arguments:

 name (the person who's making the comment's name)
 url (a contact url, either mailto: or http: or whatever)
 comment (the comment body)
 irt (the article this comment is in reply to)
 subject (the subject of the comment.. useful for forum subthreads)

Example:

 [% article.add_comment('Bob', 'http://bob.com', 'Nice site!', 34, 'About the site...') %]

=item BadNews::Article->B<delete_comment($comment_id)>

Deletes a descending comment by comment_id.  Returns true if successful.

Example:

 $article->delete_comment($comment->id);

=item BadNews::Article->B<next_by_create()>

Gets the next article by create time.

Example:

 [% next_article = article.next_by_create %]

=item BadNews::Article->B<prev_by_create()>

Gets the previous article by create time.

Example:

 [% prev_article = article.prev_by_create %]

=back

=head1 KNOWN ISSUES

C<BadNews::Article> has no known issues.

=head1 AUTHOR

Michael Gregorowicz <michael@gregorowicz.com>

=cut

1;
