# $Id: Spellchk.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::FrontEnd::Spellchk;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Registry;
use Apache::Constants qw/:common :http/;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;

# $Id: Spellchk.pm 441 2006-12-11 21:32:47Z corrupt $
$|=1;

# WBOSS, Web Based Open Source Spellchcker Version 2.5i
# Copyright 2001, Joshua Cantara <jcantara@grappone.com>
# This program is licensed under the GPL: http://www.gnu.org/licenses/gpl.txt
# Newest version can always be found at: http://dontpokebadgers.com/spellchecker/

#####################################
# LOAD MODULES!
#####################################
use strict;
use CGI;
use IPC::Open3;

#####################################
# WHICH SPELL CHECKER TO USE?
# CHANGE THIS VARIABLE IF NEEDED!
#####################################
my $path = '/usr/bin/aspell';
#my $path = '/usr/bin/ispell';

######################################
# SET GLOBAL VARIABLES
######################################
use vars qw(@words $wordframe $wordcount $worderror $wordignore $pageheaders);
@words = ();
$wordframe = "";
$wordcount = 0;
$worderror = 0;
$wordignore = "";
$pageheaders = qq|
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-2">
<style type="text/css">
BODY	{
	font-family : arial,verdana,tahoma,sans-serif;
	font-size : 12px;
	color : #000000;
	margin-top : 5px;
	margin-left : 10px;
	margin-right : 10px;
	margin-bottom : 5px;
	background : #F9F9F9;
	text-align : center;
}

A {
	color : #003366;
	font-family : arial,verdana,tahoma,sans-serif;
	font-size : 12px;
	font-weight : bold;
	text-decoration : none;
}

FORM {
	padding : 0px;
	margin : 0px;
}

DIV.main {
	padding : 0px;
	margin-left : auto;
	margin-right : auto;
}

DIV.header {
	padding : 0px;
	font-family : arial, verdana,tahoma,sans-serif;
	font-size : 20px;
}

DIV.inputs {
	padding : 0px;
	padding-top : 10px;
}

DIV.goback {
	padding : 0px;
	padding-top:10px;
}

DIV.bodytext	{
	padding : 0px;
	padding-top : 10px;
	padding-bottom : 10px;
	text-align : justify;
}

DIV.textcheck {
	width : 96%;
	padding : 5px;
	border : 1px solid black;
	background : #FFFFFF;
	/* NS4 IGNORE BUG */
	/*/*/
	text-align : justify;
	/* END IGNORE BUG */
}

SELECT,TEXTAREA	{
	font-family : arial,verdana,tahoma,sans-serif;
	font-size : 12px;
	color : #000000;
	background : #FFFFF0;
}

INPUT {
	font-family : arial,verdana,tahoma,sans-serif;
	font-size : 12px;
	color : #000000;
}
</style>
|;

#####################################
# MAIN LOOP!
#####################################
my $query = $fe->cgi;
my $string = $query->param('checkme');
my $form = $query->param('form');
my $field = $query->param('field');
my $pid;
my $pwd = `pwd`;
chomp $pwd;

#print "Content-type: text/html\n\n";
print qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	   "http://www.w3.org/TR/html4/loose.dtd">|;

untie *STDIN;
if ($query->param('spell') eq 'check')
	{
	if (-e '/mg2web/cma.mg2.org/etc/custom.dic')
		{
		$pid = open3(\*WRITER,\*READER,\*ERROR,"$path -p /mg2web/cma.mg2.org/etc/custom.dic -a -S") or die "Can't open aspell!";
		}
	else	{
		$pid = open3(\*WRITER,\*READER,\*ERROR,"$path -a -S") or die "Can't open aspell!";
		}
	text2words($string);
	checkit($form, $field);
	close READER;
	close WRITER;
	wait;
	}
elsif ($query->param('Update And Close') eq 'Update And Close')
	{
	query2words($query);
	final($form, $field);
	}
elsif ($query->param('Check Again') eq 'Check Again')
	{
	if (-e '/mg2web/cma.mg2.org/etc/custom.dic')
		{
		$pid = open3(\*WRITER,\*READER,\*ERROR,"$path -p /mg2web/cma.mg2.org/etc/custom.dic -a -S") or die "Can't open aspell!";
		}
	else	{
		$pid = open3(\*WRITER,\*READER,\*ERROR,"$path -a -S") or die "Can't open aspell!";
		}
	query2words($query);
	checkit($form,$field);
	close READER;
	close WRITER;
	wait;
	}
else	{
	&asktext;
	}

exit;

#####################################
# SPLIT/JOIN THE INPUT
#####################################
sub _word2label {
my $word = $_[0];
my $label = '%%WORD'.$wordcount.'%%';
if ($wordignore =~ /$word/i || $word =~ /^WORD/)
	{
	return($word);
	}
$words[$wordcount] = $word;
$wordcount++;

return($label);
}

##################################################
# FILL $WORDFRAME AND @WORDS BY INPUT SPLIT
##################################################
sub text2words {
my $text = $_[0];

# ignore valid contractions (due to problems with these on some systems)
$wordignore  = "they'll we'll you'll she'll he'll i'll ";
$wordignore .= "hasn't wouldn't shouldn't didn't aren't ";
$wordignore .= "couldn't doesn't hadn't wasn't weren't isn't ";
$wordignore .= "we've you've they've ";
$wordignore .= "can't don't shan't ";

# ignore the following always
$wordignore .= "http ftp nntp smtp nfs html xml mailto bsd linux gnu gpl openwebmail ";

# ignore html characters
$wordignore .= "nbsp lt gt amp img src jpg br blockquote href ";

# ignore URLs
foreach ($text =~ m![A-Za-z]+tp://[A-Za-z\d\.]+!ig)
	{
	$wordignore .= " $_";
	}

# ignore email addresses
foreach ($text =~ m![A-Za-z\d]+\@[A-Za-z\d]+!ig)
	{
	$wordignore .= " $_";
	}

# ignore domain names
foreach ($text =~ m![A-Za-z\d\.]+\.(com|org|edu|net|gov)[A-Za-z\d\.]*!ig)
	{
	$wordignore .= " $_";
	}

@words = ();
$wordcount = 0;
$wordframe = $text;

######################
#ATTN: If you have problems with international characters, disable the bottom line and enable the top one.
######################

# a-z A-Z English characters only.
#$wordframe =~ s/([A-Za-z][A-Za-z\-]*[A-Za-z])|(~~[A-Za-z][A-Za-z\-]*[A-Za-z])/_word2label($1)/ge;

# Extended characters, such as those with accents
$wordframe =~ s/([^\W\d_][^\W\d_\-]*[^\W\d_])|(~~[^\W\d_][^\W\d_\-]*[^\W\d_])/_word2label($1)/ge;

return $wordcount;
}

###########################################
# FILL $WORDFRAME AND @WORDS FROM CGI
###########################################
sub query2words {
my $q = $_[0];
my $i;

@words = ();
$wordcount = $q->param('wordcount');
$wordframe = CGI::unescape($q->param('wordframe'));

for ($i=0; $i<$wordcount; $i++)
	{
	$words[$i] = $q->param($i) if (defined ($q->param($i)))
	}

}

#########################################
# BUILD OUTPUT FROM $WORDFRAME AND @WORDS
#########################################
sub words2text {
my $text = $wordframe;

$text =~ s/%%WORD(\d+)%%/$words[$1]/ge;
$text =~ s/~~([A-Za-z]*)/$1/ge;		# covert manualfix

return($text);
}

##############################################################
# GENERATE SPELLCHECK HTML
##############################################################
sub words2html {
my $html = $wordframe;
my $i;

# escape html codes, convert line breaks
$html =~ s/&/&amp;/g;
$html =~ s/</&lt;/g;
$html =~ s/>/&gt;/g;
$html =~ s/\n/<BR>/g;
$html =~ s/"/&quot;/g;
$html =~ s/ ( +)/&nbsp;$1/g;

for ($i=0; $i<$wordcount; $i++)
	{
	my $wordhtml = "";

	if ($words[$i]=~/^~~/)		# check if manualfix
		{
		my $origword = substr($words[$i],2);
		my $len = length($origword);

		$wordhtml = qq|<input type="text" size="$len" name="$i" value="$origword">\n|;
		$worderror++;
		}
	else	{				# normal word
		my ($r) = spellcheck($words[$i]);

		if ($r->{'type'} eq 'none' || $r->{'type'} eq 'guess')
			{
 			my $len = length($words[$i]);

			$wordhtml = qq|<input type="text" size="$len" name="$i" value="$words[$i]">\n|;
			$worderror++;
			}
		elsif ($r->{'type'} eq 'miss')
			{
			my $sugg;

			$wordhtml = qq|<select size="1" name="$i">\n|.
			qq|<option>$words[$i]</option>\n|.
			qq|<option value="~~$words[$i]">--Manually Fix--</option>\n|;

			foreach $sugg (@{$r->{'misses'}})
				{
				$wordhtml .= qq|<option>$sugg</option>\n|;
				}

			$wordhtml .= qq|</select>\n|;
			$worderror++;
			}
		else	{			# type= ok, compound, root
           		$wordhtml = qq|$words[$i]|;
           		$wordframe =~ s/%%WORD$i%%/$words[$i]/; 	# remove the word symbol from wordframe
			}
		}

	$html =~ s/%%WORD$i%%/$wordhtml/;
	}

return($html);
}

#####################################
# CHECK TEXT FOR ERRORS AND ASK FOR VERIFICATION
#####################################
sub checkit {
my ($formname,$fieldname) = @_;

# escapedwordframe must be done after words2html()
# since $wordframe may changed in words2html()
my $wordshtml = words2html();
my $escapedwordframe = CGI::escape($wordframe);

print qq|
<html><head>
$pageheaders
<title>Checking Spelling...</title></head>
<body onLoad="self.focus();">
<form method="POST" action="spellchk">
<div class="main"><div class="header">Checking Spelling</div>
<div class="bodytext">
Drop the boxes below down to choose a suggested replacement,
keep your original, or choose "--Manually Fix--" and then "Check Again"
if none of the suggestions fit what you intended.
A text box appears if no suggestions were found. Retype the word, and try again.
Click Cancel to exit the Spell Checker without making any changes.
</div><div class="textcheck">$wordshtml</div>
<div class="inputs">
<input type="hidden" name="wordframe" value="$escapedwordframe">
<input type="hidden" name="wordcount" value="$wordcount">
<input type="submit" name="Check Again" value="Check Again">
<input type="submit" name="Update And Close" value="Update And Close">
<input type="hidden" name="form" value="$formname">
<input type="hidden" name="field" value="$fieldname">
<input type="button" name"closeWindow" value="Cancel" onclick="window.close()">
</div>
</form></div></body></html>
|;

}

#####################################
# LOAD FINAL CORRECTIONS AND MAKE CHANGES
#####################################
sub final {
my ($formname, $fieldname) = @_;
my $escapedfinalstring = words2text();

# since jscript has problem in unescape doublebyte char string,
# we only escape " to !QUOT! and unescape in jscript by RegExp
# $escapedfinalstring=CGI::escape(words2text());

$escapedfinalstring =~ s/"/!QUOT!/g;

print qq|
<html><head>
$pageheaders
<title>Done Checking!</title></head>
<!--
<body onload="window.opener.document.$formname.$fieldname.value=document.done.checked.value;window.close();">
-->
<body onload="window.opener.tinyMCE.setContent(document.done.checked.value);window.close();">
<div class="main"><form name="done">
<div class="header">Corrections Are Being Made To Your Original Page</div>
If you see this screen, please wait for it to load. It will close after the corrections have been made to your text.
If an error in loading occurs you may use the links below to navigate back or start again.
<div class="inputs">
<textarea rows="12" cols="50" name="checked">$escapedfinalstring</textarea>
<input type="hidden" name="form" value="$formname">
<input type="hidden" name="field" value="$fieldname">
</div><div class="goback">Click <a href="spellchk">here</a> to check more text.<br>
Go <a href="#" onclick="window.history.back()">back</a> to the previous page.<br>
Click <a href="#" onclick="window.close();">here</a> to close this window.
</div></form></div>
<script language="JavaScript">
<!--
unescape_string();
function unescape_string() {
	var quot = new RegExp("!QUOT!","g");
	// unescape !QUOT! to "
	document.done.checked.value=(document.done.checked.value.replace(quot,'"'));
}
//-->
</script></body></html>
|;

}

#####################################
# ASKS FOR TEXT TO CHECK
#####################################
sub asktext {
print qq|
<html><head>
$pageheaders
<title>Spell Checker</title></head>
<body><div class="main"><form action="spellchk" method="POST">
<div class="header">Please Copy and Paste Text Below</div><div class="inputs">
<textarea rows="8" cols="50" name="checkme"></textarea><br>
<input type="hidden" name="spell" value="check">
<input type="submit" name="Submit" value="Submit"></div>
<div class="goback">Click <a href="#" onclick="window.close();">here</a> to close this window.</div>
</form></div></body></html>
|;

}

#######################################
# DEBUG SUB ROUTINE
# Useage: &debug();
#######################################
sub debug {
my $q = new CGI;

print '<!--// ';
foreach ($q->param)
   {
   print "$_";
   print " : ";
   print $q->param("$_");
   print "\n";
   }
print '//-->';

}

################################################
# SPELLCHECK SUBROUTINE!
################################################
sub spellcheck {
my $pid = undef;
my $word = shift(@_);
my @commentary;
my @results;
my %types = (
	# correct words:
	'*' => 'ok',
	'-' => 'compound',
	'+' => 'root',
	# misspelled words:
	'#' => 'none',
	'&' => 'miss',
	'?' => 'guess',
	);
my %modisp = (
	'root' => sub {
		my $h = shift;
		$h->{'root'} = shift;
		},
	'none' => sub {
		my $h = shift;
		$h->{'original'} = shift;
		$h->{'offset'} = shift;
		},
	'miss' => sub { # also used for 'guess'
		my $h = shift;
		$h->{'original'} = shift;
		$h->{'count'} = shift; # count will always be 0, when $c eq '?'.
		$h->{'offset'} = shift;
		my @misses  = splice @_, 0, $h->{'count'};
		my @guesses = @_;
		$h->{'misses'}  = \@misses;
		$h->{'guesses'} = \@guesses;
		},
	);
$modisp{'guess'} = $modisp{'miss'}; # same handler.
chomp $word;
$word =~ s/\r//g;
$word =~ /\n/ and warn "newlines not allowed";

print WRITER "!\n";
print WRITER "^$word\n";

while (<READER>)
	{
	chomp;
	last unless $_ gt '';
	push (@commentary, $_) if substr($_,0,1) =~ /([*|-|+|#|&|?| ||])/;
	}

for my $i (0 .. $#commentary)
	{
	my %h = ('commentary' => $commentary[$i]);

	my @tail; # will get stuff after a colon, if any.
	if ($h{'commentary'} =~ s/:\s+(.*)//)
		{
		my $tail = $1;
		@tail = split /, /, $tail;
		}

	my($c,@args) = split ' ', $h{'commentary'};
	my $type = $types{$c} || 'unknown';
	$modisp{$type} and $modisp{$type}->( \%h, @args, @tail );
	$h{'type'} = $type;
	$h{'term'} = $h{'original'};
	push @results, \%h;
	}

return $results[0];
}
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

