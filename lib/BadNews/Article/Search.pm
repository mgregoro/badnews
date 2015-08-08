# search interface to the article subsystem
# $Id: Search.pm 428 2006-08-30 02:00:57Z corrupt $

package BadNews::Article::Search;

@ISA = ('BadNews');
use BadNews::Article;
use BadNews;
use Carp;

sub new {
    my ($class, %criteria) = @_;

    my $self = bless({criteria  =>  \%criteria}, $class);

    $self->fetch_results;

    return $self;
}

sub results {
    my ($self) = @_;
    return @{$self->{results}};
}

sub formulate_sql {
    my ($self) = @_;
    my $criteria = $self->criteria;
    my $sql = "select id from articles where (published = '1' && (";
    my ($i, $len) = (0, scalar(keys(%$criteria)));
    if (exists($criteria->{meta_criteria})) {
        --$len;
    }
    foreach my $key (keys %$criteria) {
        next if $key eq "meta_criteria";
        ++$i;
        $criteria->{$key} =~ s/\%/\\\%/g;
        if ($i == $len) {
            $sql .= "articles.$key like " . '\'%' . "$criteria->{$key}" . '%\'';
        } else {
            $sql .= "articles.$key like " . '\'%' . "$criteria->{$key}" . '%\' || ';
        }
    }
    $sql .= ")) $criteria->{meta_criteria}->{order_string} $criteria->{meta_criteria}->{limit_string}";
    return $sql;
}

sub fetch_results {
    my ($self) = @_;
    my $dbh = $self->open_db;
    my $sql = $self->formulate_sql($dbh);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ar = $sth->fetchrow_arrayref) {
        my $id = $$ar[0];
        push(@{$self->{results}}, BadNews::Article->open($id));
    }
}

sub criteria {
    my ($self) = @_;
    return $self->{criteria};
}

1;
