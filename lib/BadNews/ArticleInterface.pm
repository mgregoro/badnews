# the CMS interface to the article object.  prepares and passes data to the article
# $Id: ArticleInterface.pm 447 2007-01-06 23:05:14Z corrupt $
# object.

package BadNews::ArticleInterface;

@ISA = ('BadNews');
use BadNews::Links;
use BadNews::Author;
use BadNews::Article;
use BadNews::Article::Search;
use BadNews::Article::Comment;
use BadNews::File::Search;
use BadNews::CalendarInterface;
use BadNews::TagInterface;
use BadNews;
use Carp;

sub new {
    my ($class) = @_;
    return bless({}, $class);
}

sub recent_days_with_articles {
    my ($self, $number, $type, $from, $to) = @_;
    my $ci = BadNews::CalendarInterface->new();
    my @days = $ci->recent_days_with_articles($number, $type, $from, $to);
    return (@days);
}

sub formatted_date {
    my ($self, $date, $format) = @_;
    my $ci = BadNews::CalendarInterface->new();
    $date =~ s/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/$1-$2-$3 $4:$5:$6/og;
    $ci->any_to_ezdate($date);
    return $ci->format_date($format);
}


sub pretty_date {
    my ($self, $date) = @_;
    my $ci = BadNews::CalendarInterface->new();
    $ci->any_to_ezdate($date);
    return $ci->time_short;
}

sub random_article {
    my ($self) = @_;
    my (@articles);
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from articles where published = '1'");
    $sth->execute;

    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, $$ar[0]);
    }

    return $articles[int(rand($#articles))];
}

sub all_articles {
    my ($self) = @_;
    my @articles;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from articles order by create_time desc");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }
    return @articles;
}

# get all the articles with this tag
sub articles_by_tag {
    my ($self, $tag, $to, $from) = @_;
    my $ti = BadNews::TagInterface->new();
    return $ti->entities_by_name_and_type($tag, 'article', $to, $from);
}

sub recent_articles {
    my ($self, $to, $from) = @_;
    my @articles;
    my $dbh = $self->open_db;
    my $sth;
    if ($from) {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' order by create_time desc limit $from,$to");
    } else {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' order by create_time desc limit $to");
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }

    $articles[$#articles]->is_last(1) if scalar(@articles);
    return (@articles);
}

sub recently_commented_on_articles {
    my ($self, $to, $from) = @_;
    my @articles;
    $number = $number ? $number : 10;
    my $dbh = $self->open_db;
    my $sth;
    if ($from) {
        $sth = $dbh->prepare("select comments.article_id, max(comments.create_time) from comments, articles where comments.article_id = articles.id && articles.published = '1' group by comments.article_id order by 'max(comments.create_time)' desc limit $from, $to");
    } else {
        $sth = $dbh->prepare("select comments.article_id, max(comments.create_time) from comments, articles where comments.article_id = articles.id && articles.published = '1' group by comments.article_id order by 'max(comments.create_time)' desc limit $to");
    }

    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }

    $articles[$#articles]->is_last(1) if scalar(@articles);
    return(@articles);
}

sub count_recent_articles {
    my ($self, $to, $from) = @_;
    return scalar($self->recent_articles($to, $from));
}

sub count_articles_by_category {
    my ($self, $category, $time_type, $to, $from) = @_;
    return scalar($self->articles_by_category($category, $time_type, $to, $from));
}

sub articles_by_category {
    my ($self, $category, $time_type, $to, $from) = @_;
    $time_type = 'create' unless $time_type;
    my $dbh = $self->open_db;
    my @articles;
    my $sth;
    if ($to) {
        if ($from) {
            if ($category =~ /^all$/i) {
                #print "select id from articles where published = '1' && category not like '%[SYS]%' order by " . $time_type . "_time desc limit $num\n";
                $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' order by " . $time_type . "_time desc limit $from, $to")
            } else {
                $sth = $dbh->prepare("select id from articles where published = '1' && category = " . $dbh->quote($category) . " order by " . $time_type . "_time desc limit $from, $to");
            }
        } else {
            if ($category =~ /^all$/i) {
                #print "select id from articles where published = '1' && category not like '%[SYS]%' order by " . $time_type . "_time desc limit $num\n";
                $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' order by " . $time_type . "_time desc limit $to")
            } else {
                $sth = $dbh->prepare("select id from articles where published = '1' && category = " . $dbh->quote($category) . " order by " . $time_type . "_time desc limit $to");
            }
        }
    } else {
        if ($category =~ /^all$/i) {
            $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' order by " . $time_type . "_time desc")
        } else {
            $sth = $dbh->prepare("select id from articles where published = '1' && category = " . $dbh->quote($category) . " order by " . $time_type . "_time desc");
        }
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }
    $articles[$#articles]->is_last(1) if scalar(@articles);
    return (@articles);
}

sub articles_by_search_string {
    my ($self, $string, $limit_string, $order_string) = @_;
    if ($string =~ /^all$/i) {
        $string = "";
    }

    # make sure we aren't get poisoned SQL
    $order_string = $order_string =~ /^order by \w+\s*(?:asc|desc|)$/i ? $order_string : undef;
    $limit_string = $limit_string =~ /^limit \d+,*\s*\d*$/i ? $limit_string : undef;

    my $as = BadNews::Article::Search->new(
                    subject     =>      $string,
                    body        =>      $string,
                    meta_criteria   =>  {
                        order_string        =>  $order_string,
                        limit_string        =>  $limit_string
                    });

    my @results = $as->results;

    if ($self->c->HIGHLIGHT_SEARCH_STRING) {
        my @highlighted;
        foreach my $result (@results) {
            $result->{body} =~ s/($string)/<span class="highlight">$1<\/span>/gi;
            $result->{subject} =~ s/($string)/<span class="highlight">$1<\/span>/gi;
            push(@highlighted, $result);
        }
        $highlighted[$#highlighted]->is_last(1) if scalar(@highlighted);
        return (@highlighted);
    } else {
        $results[$#results]->is_last(1) if scalar(@results);
        return (@results);
    }
}

sub count_articles_by_search_string {
    my ($self, $string, $limit_string, $order_string) = @_;
    if ($string =~ /^all$/i) {
        $string = "";
    }

    $order_string = $order_string =~ /^order by \w+\s*(?:asc|desc|)$/i ? $order_string : undef;
    $limit_string = $limit_string =~ /^limit \d+,*\s*\d*$/i ? $limit_string : undef;

    my $as = BadNews::Article::Search->new(
                    subject     =>      $string,
                    body        =>      $string,
                    meta_criteria   =>  {
                        order_string        =>  $order_string,
                        limit_string        =>  $limit_string
                    });

    return scalar($as->results);
}

# month summary!
sub month_summary {
    my ($self) = @_;

    # get out the guns!
    my (@months, $start_time, $month, $year);
    my $dbh = $self->open_db;
    my $ci = BadNews::CalendarInterface->new();

    # obtain the last year/month that we'll do!
    my ($min_year, $min_month) = $self->min_time('create');

    # prime the calendar interface object!
    $ci->switch_to_this_month;
    $ci->next_month;

    # prime the start time!
    my $end_time = $ci->dim;

    # exit loop only when $month = $min_month and $year = $min_year
    while ($month != $min_month || $year != $min_year) {
        $month = $ci->month;
        $year = $ci->year;

        # update the year if necessary
        if ($ci->year != $year) {
            $year = $ci->year;
        }

        $ci->last_month;

        # get the start time!
        $start_time = $ci->dim;

        my $sth = $dbh->prepare("select count(id) from articles where published = '1' && category not like '%[SYS]%' && create_time >= $start_time && create_time <= $end_time");
        $sth->execute;
        $ar = $sth->fetchrow_arrayref;

        push(@months, {
                month       =>      $ci->month,
                month_name  =>      $ci->month_name,
                year        =>      $ci->year,
                count       =>      $$ar[0],
            });

        $end_time = $ci->dim;
    }

    return (@months);
}

sub min_time {
    my ($self, $type) = @_;
    $type = "create" unless $type;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select date_format(min(" . $type . "_time), '%Y:%m') from articles");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    my ($year, $month) = split(':', $$ar[0]);
    return($year, sprintf('%02d', $month));
}

sub max_time {
    my ($self, $type) = @_;
    $type = "create" unless $type;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select date_format(max(" . $type . "_time), '%Y:%m') from articles");
    $sth->execute;
    my $ar = $sth->fetchrow_arrayref;
    my ($year, $month) = split(':', $$ar[0]);
    return($year, sprintf('%02d', $month));
}  

sub articles_by_date_range {
    my ($self, $from_date, $to_date, $type, $to, $from) = @_;
    $type = "create" unless $type;
    unless ($from_date =~ /^\d{14}$/ && $to_date =~ /^\d{14}$/) {
        warn "from date or to date must be in diminished time!\n";
        return undef;
    }
    my $dbh = $self->open_db;
    my @articles;
    my $sth;
    if ($from) {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $from, $to");
    } elsif ($to) {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc limit $to");
    } else {
        $sth = $dbh->prepare("select id from articles where published = '1' && category not like '%[SYS]%' && " . $type . "_time >= $from_date && " . $type . "_time <= $to_date order by " . $type . "_time desc");
    }
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }
    $articles[$#articles]->is_last(1) if scalar(@articles);
    return (@articles);
}

sub count_articles_by_date_range {
    my ($self, $from_date, $to_date, $type, $to, $from) = @_;
    return scalar($self->articles_by_date_range($from_date, $to_date, $type, $to, $from));
}

sub articles_by_subject {
    my ($self, $subject, $type) = @_;
    $type = "create" unless $type;
    my $dbh = $self->open_db;
    my @articles;
    my $sth = $dbh->prepare("select id from articles where published = '1' && subject = " . $dbh->quote('subject') . " order by " . $type . "_time desc");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@articles, BadNews::Article->open($$ar[0]));
    }
    $articles[$#articles]->is_last(1) if scalar(@articles);
    return (@articles);
}

sub count_articles_by_subject {
    my ($self, $subject, $type) = @_;
    return scalar($self->articles_by_subject($self, $subject, $type));
}

sub count_array {
    my ($self, $array) = @_;
    return scalar(@$array);
}

sub open_article {
    my ($self, $id) = @_;
    return BadNews::Article->open($id);
}

sub all_links {
    my ($self) = @_;
    return BadNews::Links->links_by_cat('all');
}

sub all_files {
    my ($self) = @_;
    my $search = BadNews::File::Search->new(all =>  1);
    return $search->results;
}

sub all_images {
    my ($self) = @_;
    my $search = BadNews::File::Search->new(file_type   =>      'image');
    return $search->results;
}

sub author_cn {
    my ($self, $author) = @_;
    my $a_obj = BadNews::Author->open_by_name($author);
    return $a_obj->common_name;
}

sub parse_body {
    my ($self, $body, $nl_is_br) = @_;
    my @tags;

    # first do the tags...

    # parse out the tags one at a time
    while($body =~ /[.\r\n]*(\[\<\w+\s+\w+\s*\=\s*\w+\s*\>\])[.\r\n]*/go) {
        my $tag_str = $1;

        my $new_str;
        $tag_str =~ /^\[\<(\w+)\s+(\w+)\s*\=\s*(\w+)\s*\>\]$/o;
        my ($action, $attrib, $val) = ($1, $2, $3);

        if ($action eq "href") {
            my $link = BadNews::Links->open($val);
            if ($link) {
                $new_str = '<a href="' . $link->url . '" target="_new" class="ul_link" onMouseOver="this.style.backgroundColor=\'#7F8EAB\'" onMouseOut="this.style.backgroundColor=\'transparent\'">' . $link->short_name . '</a>';
            } 
        } elsif ($action eq "img") {
            my $file = BadNews::File->open_by_id($val);
            if ($file) {
                $new_str = '<img align="left" alt="' . $file->description . '" src="/bin/get_file?file_id=' . $file->id . '">';
            }
        }

        # escape the brackets
        $tag_str =~ s/\[/\\[/go;
        $tag_str =~ s/\]/\\]/go;

        # check to see if the tag exists. one instance will get them all.
        unless (tag_exists($tag_str, @tags)) {
            push(@tags, { tag_string        =>          $tag_str,
                          new_string        =>          $new_str });
        }
    } 

    # replace the tags with html
    foreach my $tag (@tags) {
        my ($tstr, $nstr) = ($tag->{tag_string}, $tag->{new_string});
        $body =~ s/$tstr/$nstr/g;
    }

    # now swap out newlines for <br>'s
    if ($self->c->NEWLINE_IS_BR || $nl_is_br) {
        # turn cr/newlines into newlines
        $body =~ s/\r\n/\n/g;

        # turn newlines into <br>'s
        $body =~ s/\n/<br>/g;
    }

    # return finished body
    return $body;
}

sub tag_exists {
    my ($tag, @tags) = @_;
    foreach my $t (@tags) {
        if ($t->{tag_string} eq $tag) {
            return 1;
        }
    }
    return undef;
}
    
sub add_category {
    my ($self, $cat) = @_;
    unless (($self->category_exists($cat)) || ($cat =~ /^all$/i)) {
        my $dbh = $self->open_db;
        return $dbh->do("insert into article_categories (category) values (" . $dbh->quote($cat) . ")");
    }
    return undef;
}

sub delete_category {
    my ($self, $cat) = @_;
    if ($self->category_exists($cat)) {
        my $dbh = $self->open_db;
        return $dbh->do("delete from article_categories where category = " . $dbh->quote($cat));
    }
    return undef;
}

sub is_system_category {
    my ($self, $cat) = @_;
    if ($cat =~ /^\[SYS\]/) {
        return 1;
    } else {
        return undef;
    }
}

sub category_exists {
    my ($self, $cat) = @_;
    foreach my $ty ($self->list_categories) {
        return 1 if $ty eq $cat;
    }
    return undef;
}

sub list_categories {
    my ($self) = @_;
    my @categories;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select category from article_categories order by category asc");
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@categories, $$ar[0]);
    }
    return @categories;
}

sub list_non_system_categories {
    my ($self) = @_;
    my @cats = $self->list_categories;
    my @newcats;
    foreach my $cat (@cats) {
        # get rid of the system categories
        push(@newcats, $cat) unless $cat =~ /^\[SYS\]/o;
    }
    return @newcats;
}

sub list_system_categories {
    my ($self) = @_;
    my @cats = $self->list_categories;
    my @newcats;
    foreach my $cat (@cats) {
        # get rid of the system categories
        push(@newcats, $cat) if $cat =~ /^\[SYS\]/o;
    }
    return @newcats;
}

sub open_comment_by_id {
    my ($self, $id) = @_;
    return BadNews::Article::Comment->open($id);
}

sub all_comments {
    my ($self) = @_;
    my @comments;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select id from comments order by create_time asc");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@comments, BadNews::Article::Comment->open($$ar[0]));
    }
    return (@comments);
}

# returns true if there are previous posts in this category
sub previous_posts_by_category {
    my ($self, $display_articles, $skip_articles, $category) = @_;
    my $count = $self->count_articles_by_category($category, 'create', $display_articles, ($skip_articles + $display_articles));
    return $count;
}

sub previous_posts_by_search_string {
    my ($self, $search_string, $limit_string) = @_;
    my $count = $self->count_articles_by_search_string($search_string, $limit_string);
    return $count;
}

sub previous_posts_by_date_range {
    my ($self, $from_date, $to_date, $display_articles, $skip_articles) = @_;
    my $count = $self->count_articles_by_date_range($from_date, $to_date, 'create', $display_articles, ($skip_articles + $display_articles));
    return $count;
}

# truncate:
# takes 4 arguments, 3 required one optional
# they are: the BadNews::Article object, 
# the method we're going to pull data from, 
# the length of the truncated value, and a boolean
# value for wether or not we're going to break at the end of a word
sub truncate {
    my ($self, $article, $method, $len, $bow) = @_;
    my $data = $article->$method;

    # return data if the length of all the data is less than the length
    if (length($data) < $len) {
        return $data;
    }

    if ($bow) {
        # we're going to strip out html and formatting, and replace it with whitespace.  This should do the trick..
        $data =~ s/\<[\\A-Za-z0-9\/\=\"\'\s\_\-\?\!\.\&:;]+\>/ /og;
        
        # prepare the return value...
        my $return_value;
        my @words = split(/\s+/, $data);
        my $word = 1; 
        $return_value = $words[0];

        # add words until we exceed the specified length or run out of words
        while (length($return_value) < $len) {
            $return_value .= " $words[$word]";
            last if $word == $#words;
            ++$word;
        }

        # and return! (w/ yadda yadda yadda)
        return $return_value . " [...]";
    } else {
        return substr($data, 0, $len);
    }
}

sub add_comment_banned_word {
    my ($self, $word) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("insert into c_banned_words (word, create_time) values (?,now())");
    $sth->execute($word);

    # build the where clause...
    my $where_clause = "comment like " . $dbh->quote("%" . $word . "%") . " ";
    for (qw/subject name url/) {
        $where_clause .= "OR $_ like " . $dbh->quote("%" . $word . "%") . " ";
    }

    $sth = $dbh->do(qq/
        delete from comments where 
            (  
                $where_clause
            )
    /);
}

sub remove_comment_banned_word {
    my ($self, $word) = @_;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("delete from c_banned_words where word = ?");
    $sth->execute($word);
}

sub list_comment_banned_words {
    my ($self) = @_;
    my @return;
    my $dbh = $self->open_db;
    my $sth = $dbh->prepare("select word from c_banned_words");
    $sth->execute;
    while (my $ar = $sth->fetchrow_arrayref) {
        push(@return, $$ar[0]);
    }
    return (@return);
}

1;
__END__

=head1 NAME

B<BadNews::ArticleInterface> - The BadNews Article Interface Class (aka the Article Toolbox)

=head1 SYNOPSIS

[% FOREACH article = fe.ai.recent_articles(5) %]

=head1 DESCRIPTION

Controls article retrieval, and also provides mechanisms for searching for and dealing with articles.

Almost all of these methods will be called from template-toolkit.  Because of this, I'll put all examples in 
tt2 format.

=head1 METHODS

=over 2

=item fe.ai.formatted_date(article.create_time, format_string)

Takes a date from an article (either article.modify_time, or article.create_time) or any other date for that
matter, and returns a string version of it based on the format specified in format_string.

=item fe.ai.pretty_date(article.create_time)

This is a wrapper around B<BadNews::CalendarInterface::time_short>.  It returns the date in a certain 
format.

=item fe.ai.all_articles()

Returns all articles in the database ordered by create time.

=item fe.ai.recent_articles(display_articles, start_at)

Returns the most recent articles if start_at is specified, it skips that many articles in the database before it 
displays the number of articles you asked for in display_articles.  This is primarily useful for paging results.  
For example, if you specify 5, and 10 for display_articles and start_at, the engine will return articles 10-15.

Note: the second argument is OPTIONAL.  If omitted, it will return the number of articles you specified.

=item fe.ai.count_recent_articles(display_articles, start_at)

Returns an integer count of the number of articles returned by C<fe.ai.recent_articles()>.

=item fe.ai.recently_commented_on_articles(display_articles, start_at)

Returns the articles that were most recently commented on.  If start_at is specified, it skips that many articles in the database before it 
displays the number of articles you asked for in display_articles.  This is primarily useful for paging results.  
For example, if you specify 5, and 10 for display_articles and start_at, the engine will return articles 10-15.

Note: the second argument is OPTIONAL.  If omitted, it will return the number of articles you specified.

=item fe.ai.articles_by_category(category, time_filter, display_articles, start_at)

Returns the most recent articles by category, ordered by the time_filter which can be either 'create' or 'modify'.
If start_at is specified, it skips that many articles in the database before it 
displays the number of articles you asked for in display_articles.  This is primarily useful for paging results.  
For example, if you specify 5, and 10 for display_articles and start_at, the engine will return articles 10-15.

=item fe.ai.count_articles_by_category(category, time_filter, display_articles, start_at)

Returns an integer count of the number of articles returned by C<fe.ai.articles_by_category()>.

=item fe.ai.articles_by_search_string(search_string, limit_string, order_string)

To provide more flexibility (at the expense of breaking API convention) I opened up the search interface to allow 
the user to specify their own "limit" segment of sql code and "order by" sql code.  The limit_string must follow the 
convention "limit #, #".  As in SQL, the second # and , are optional.  The order_string must follow the convention 
"order by <column> <asc or desc or null>".  Both the limit_string and order_string are optional, but they are currently 
the best way to sort and page article search results at this time.

=item fe.ai.count_articles_by_search_string(search_string, limit_string, order_string)

Returns an integer count of the number of articles returned by C<fe.ai.articles_by_search_string()>.

=item fe.ai.min_time(time_filter)

Returns a list (year, month) of the minimum (earliest) timestamp of an article in the database.  Time filter must be 
either 'create' or 'modify'.

=item fe.ai.max_time(time_filter)

Returns a list (year, month) of the maximum (latest) timestamp of an article in the database.  Time filter must be 
either 'create' or 'modify'.

=item fe.ai.articles_by_date_range(from_date, to_date, time_filter)

Returns a list of all of the articles between from_date and to_date ordered by the time specified in the time_filter.  
Time filter must be either 'create' or 'modify'.

=item fe.ai.count_articles_by_date_range(from_date, to_date, time_filter)

Returns an integer count of the number of articles returned by C<fe.ai.articles_by_date_range()>.

=item fe.ai.articles_by_subject(subject, time_filter)

Returns a list of all of the articles that match the subject specified in the first argument ordered by the time 
specified in the second argument.  The second argument must be either 'create' or 'modify'.

Note: The second argument is OPTIONAL C<fe.ai.articles_by_subject> defaults to 'create'.

=item fe.ai.count_articles_by_subject(subject, time_filter)

Returns an integer count of the number of articles returned by C<fe.ai.articles_by_subject()>.

=item fe.ai.count_array(array_ref)

Returns the length of the array that the array_ref points to.  I dont even know why this is here, but I must be 
using it for something inside some template.  I hope it's useful for you. :)

=item fe.ai.open_article(article_id)

Returns a B<BadNews::Article> object of the article specified in article_id.

=item fe.ai.all_links()

Returns all the B<BadNews::Links> objects in the database.

=item fe.ai.all_files()

Returns all the B<BadNews::File> objects in the database.

=item fe.ai.all_images()

Returns all the B<BadNews::File> objects that are images.

=item fe.ai.author_cn(author_username)

Returns the specified author's common name.. 

=item fe.ai.parse_body(body, newline_is_br)

Parses the text passed to add html where there were tags.  This was a bigger part of the CMS before we implemented
TinyMCE as a wysiwyg editor, or the upload functionality which allows you to use an external editor.

=item fe.ai.add_category(category)

Adds the specified article category to the CMS, if the category doesn't already exist within the system.  Returns true if 
successful.

=item fe.ai.delete_category(category)

Removes the specified category from the CMS.  Returns true if successful.

=item fe.ai.is_system_category(category)

Simply checks wether the article category name contains or does not contain [SYS].  Returns true if it does, undef if it 
does not.

=item fe.ai.category_exists(category)

Checks wether the article category name exists or does not exist.  Returns true if it does, undef if it does not.

=item fe.ai.list_categories()

Lists all of the article categories within the CMS.

=item fe.ai.list_non_system_categories()

Lists all of the article categories within the CMS whose names do not contain [SYS].

=item fe.ai.all_comments()

Returns a list of all the comments within the CMS as B<BadNews::Article::Comment> objects.  

=item fe.ai.previous_posts_by_category(display_articles, start_at, category)

Counts the articles in the category that are previous to this display_articles, start_at pair.  If you don't 
understand what I'm saying, take a look at the routine.  It's very.. very simple.

=item fe.ai.previous_posts_by_search_string(search_string, limit_string)

Counts the articles based on the search and limit strings (as would be specified in C<fe.ai.articles_by_search_string>
and returns an integer value of their count.

=item fe.ai.truncate(article_object, method, truncate_length, break_on_word)

Truncates the value returned by calling method on article_object to whatever the truncate_length was specified as.  
This is used to create article summaries.  Specifying a true value for break_on_word will truncate the string to the 
last whole word before the string exceeds the truncate length.  It's much more natural for creating summaries of text.

=back

=head1 KNOWN ISSUES

C<BadNews::ArticleInterface> has no known issues.

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
