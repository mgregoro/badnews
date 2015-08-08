
# $Id: Mailer.pm 441 2006-12-11 21:32:47Z corrupt $

package BadNews::FrontEnd::Mailer;

@ISA = ('BadNews::FrontEnd::Extension');

use BadNews;
use BadNews::FrontEnd::Extension;
use Apache::Registry;
use Apache::Constants qw/:common :http/;

use Mail::Sender;

sub handle_request {
    my ($self, $fe, $r, @uri) = @_;

    # Configure the smtpd!
    my $smtpd = "mail.mg2.org";

    # modified for bN, this has an e-mail address in it - of the user running bN..
    my $mail_to = $fe->c->RSS_PUBLISHER;

    # fetch input
    my $name = $fe->param('name');
    my $email = $fe->param('email');
    my $comment = $fe->param('comment');
    my $post_submit = $fe->param('post_submit');
    my $subject = $fe->param('subject');

    # init message variable
    my $message;

    # create the message
    $message .= "Name: $name\n" if $name;
    $message .= "Email: $email\n" if $email;
    $message .= "\nComment: $comment\n" if $comment;

    # and a place to go to afterwards
    my $post_submit = $post_submit ? $post_submit : $fe->bn_location . "/thank_you.html";

    my $from_mail = $email ? $email : 'mailer@mg2.org';

    my $sender = Mail::Sender->new( {
            smtp        =>          $smtpd,
            from        =>          $from_mail});

    if ($sender->MailMsg({
                to      =>      $mail_to,
                subject =>      $subject,
                msg     =>      $message})) {
    } else {
        $r->content_type('text/plain');
        $r->send_http_header;
        $fe->render_error("Error sending mail: $Mail::Sender::Error");
        return OK;
    }

    $r->header_out("Location"   =>      $fe->bn_location . $post_submit);
    $r->status(HTTP_MOVED_TEMPORARILY);
    $r->send_http_header;
    return HTTP_MOVED_TEMPORARILY;
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

