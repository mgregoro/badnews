#!/usr/bin/perl

use lib('../lib');

use XML::RSS;
use BadNews::Article;

my $rss = XML::RSS->new(version     =>      2);

my $article = BadNews::Article->open('11');

$rss->channel(
    title       =>          'bndev.mg2.org',
    link        =>          'http://bndev.mg2.org',
    description =>          'the rants of me... mikey g',
    dc          => {
        date    =>          '2005-04-18T07:00+00:00',
        subject =>          'BadNews 0.10a RSS',
        creator =>          'mike@mg2.org',
        publisher   =>      'mike@mg2.org',
        rights  =>          '(c) 2005, the mg2 organization',
        language    =>      'en-us',
    },
    syn         =>          {
        updatePeriod    =>      'hourly',
        updateFrequency =>      '1',
        updateBase      =>      '1901-01-01T00:00+00:00'
    }
);

$rss->add_item(
    title           =>          $article->subject,
    link            =>          'http://bndev.mg2.org/?page=article&id=' . $article->id,
    description     =>          strip_html($article->body),
    content         =>          { encoded   =>  $article->body }
);

print $rss->as_string . "\n";

sub strip_html {
    my ($string) = @_;
    $string =~ s/\<br\>/\n/;
    $string =~ s/\<\/p\>/\n/;
    $string =~ s/(\<.+?\>)//g;
    return $string;
}
