package HTML::SocialMedia;

use warnings;
use strict;
use CGI::Lingua;

=head1 NAME

HTML::SocialMedia - Put social media links into your website

=head1 VERSION

Version 0.25

=cut

our $VERSION = '0.25';
use constant DEFAULTFACEBOOKURL => "https://connect.facebook.net/en_GB/sdk.js#xfbml=1&version=v2.4";

=head1 SYNOPSIS

Many websites these days have links and buttons into social media sites.
This module eases links into Twitter, Facebook and Google's PlusOne.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new();
    # ...

The language of the text displayed will depend on the client's choice, making
HTML::SocialMedia ideal for running on multilingual sites.

Takes optional parameter logger, an object which is used for warnings and
traces.
This logger object is an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> object.

Takes optional parameter cache, an object which is used to cache country
lookups.
This cache object is an object that understands get() and set() messages,
such as an L<CHI> object.

Takes optional parameter, which is a L<CGI::Lingua> object.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a HTML::SocialMedia object.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(twitter => 'example');
    # ...

=head3 Optional parameters

twitter: twitter account name
twitter_related: array of 2 elements - the name and description of a related account
cache: This object will be an instantiation of a class that understands get and
set, such as L<CHI>.
info: Object which understands host_name messages, such as L<CGI::Info>.

=cut

sub new {
	my $proto = shift;

	my $class = ref($proto) || $proto;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $lingua = $params{lingua};
	unless(defined($lingua)) {
		my %args;
		if($params{twitter}) {
			# Languages supported by Twitter according to
			# https://twitter.com/about/resources/tweetbutton
			$args{supported} = ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr'],
		} else {
			# TODO: Google plus only supports the languages listed at
			# http://www.google.com/webmasters/+1/button/index.html
			require I18N::LangTags::Detect;

			# Facebook supports just about everything
			my @l = I18N::LangTags::implicate_supers_strictly(I18N::LangTags::Detect::detect());

			if(@l) {
				$args{supported} = [$l[0]];
			} else {
				$args{supported} = [];
			}
		}
		if($params{cache}) {
			$args{cache} = $params{cache};
		}
		if($params{logger}) {
			$args{logger} = $params{logger};
		}
		$lingua = $params{lingua} || CGI::Lingua->new(%args);
		if((!defined($lingua)) && scalar($args{supported})) {
			$args{supported} = [];
			$lingua = CGI::Lingua->new(%args);
		}
	}

	return bless {
		_lingua => $lingua,
		_twitter => $params{twitter},
		_twitter_related => $params{twitter_related},
		_cache => $params{cache},
		_logger => $params{logger},
		_info => $params{info},
		_alpha2 => undef,
	}, $class;
}

=head2 as_string

Returns the HTML to be added to your website.
HTML::SocialMedia uses L<CGI::Lingua> to try to ensure that the text printed is
in the language of the user.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(
	twitter => 'mytwittername',
	twitter_related => [ 'someonelikeme', 'another twitter feed' ]
    );

    print "Content-type: text/html\n\n";

    print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">';
    print '<HTML><HEAD></HEAD><BODY>';

    print $sm->as_string(
	twitter_follow_button => 1,
	twitter_tweet_button => 1,
	facebook_like_button => 1,
	linkedin_share_button => 1,
	google_plusone => 1,
	reddit_button => 1,
    );

    print '</BODY></HTML>';
    print "\n";

=head3 Optional parameters

twitter_follow_button: add a button to follow the account

twitter_tweet_button: add a button to tweet this page

facebook_like_button: add a Facebook like button

linkedin_share_button: add a LinkedIn share button

google_plusone: add a Google +1 button

reddit_button: add a Reddit button

=cut

sub as_string {
	my ($self, %params) = @_;

	my $lingua = $self->{_lingua};

	unless($self->{_alpha2}) {
		my $alpha2 = $lingua->language_code_alpha2();
		my $locale = $lingua->locale();	# Locale::Object::Country

		if($alpha2) {
			my $salpha2 = $lingua->sublanguage_code_alpha2();
			if((!defined($salpha2)) && defined($locale)) {
				$salpha2 = $locale->code_alpha2();
			}
			if($salpha2) {
				$salpha2 = uc($salpha2);
				$alpha2 .= "_$salpha2";
			} elsif($locale) {
				my @l = $locale->languages_official();
				$alpha2 = lc($l[0]->code_alpha2()) . '_' . uc($locale->code_alpha2());
			} else {
				$alpha2 = undef;
			}
		}

		unless($alpha2) {
			if($locale) {
				my @l = $locale->languages_official();
				if(scalar(@l) && defined($l[0]->code_alpha2())) {
					$alpha2 = lc($l[0]->code_alpha2()) . '_' . uc($locale->code_alpha2());
				} else {
					@l = $locale->languages();
					if(scalar(@l) && defined($l[0]->code_alpha2())) {
						$alpha2 = lc($l[0]->code_alpha2()) . '_' . uc($locale->code_alpha2());
					}
				}
			}
			unless($alpha2) {
				$alpha2 = 'en_GB';
			}
		}
		$self->{_alpha2} = $alpha2;
	}

	my $rc;

	if($self->{_twitter}) {
		if($params{twitter_follow_button}) {
			my $language = $lingua->language();
			if(($language eq 'English') || ($language eq 'Unknown')) {
				$rc = '<a href="//twitter.com/' . $self->{_twitter} . '" class="twitter-follow-button">Follow @' . $self->{_twitter} . '</a>';
			} else {
				my $langcode = substr($self->{_alpha2}, 0, 2);
				$rc = '<a href="//twitter.com/' . $self->{_twitter} . "\" class=\"twitter-follow-button\" data-lang=\"$langcode\">Follow \@" . $self->{_twitter} . '</a>';
			}
			if($params{twitter_tweet_button}) {
				$rc .= '<p>';
			}
		}
		if($params{twitter_tweet_button}) {
			$rc .= << 'END';
				<script type="text/javascript">
					var t = document.createElement('SCRIPT'), t1 = document.getElementsByTagName('HEAD')[0];
					t.type = 'text/javascript';
					t.async = true;
					t.src = "//platform.twitter.com/widgets.js";
					t1.parentNode.insertBefore(t, t1);
				</script>
				<a href="//twitter.com/share" class="twitter-share-button" data-count="horizontal" data-via="
END
			$rc .= $self->{_twitter} . '"';
			if($self->{_twitter_related}) {
				my @related = @{$self->{_twitter_related}};
				$rc .= ' data-related="' . $related[0] . ':' . $related[1] . '"';
			}
			$rc .= '>Tweet</a><script type="text/javascript" src="//platform.twitter.com/widgets.js"></script>';
		}
	}
	if($params{facebook_like_button}) {
		if($params{twitter_tweet_button} || $params{twitter_follow_button}) {
			$rc .= '<p>';
		}

		# See if Facebook supports our wanted language. If not then
		# I suppose we could enuerate through other requested languages,
		# but that is probably not worth the effort.

		my $url = "https://connect.facebook.net/$self->{_alpha2}/sdk.js#xfbml=1&version=v2.4";
		if($self->{_logger}) {
			$self->{_logger}->debug("URL $url");
		}
		my $res;
		if($self->{_cache}) {
			$res = $self->{_cache}->get($url);
		}

		if(defined($res)) {
			unless($res) {
				$url = DEFAULTFACEBOOKURL;
			}
		} else {
			# Resposnse is of type HTTP::Response
			require LWP::UserAgent;

			my $response;

			eval {
				$response = LWP::UserAgent->new(timeout => 10)->request(HTTP::Request->new(GET => $url));
			};
			if($@) {
				if($self->{_logger}) {
					$self->{_logger}->info($@);
				}
				$response = undef;
			}
			if(defined($response) && $response->is_success()) {
				# If it's not supported, Facebook doesn't return an HTTP
				# error such as 404, it returns a string, which no doubt
				# will get changed at sometime in the future. Sigh.
				if($response->decoded_content() =~ /is not a valid locale/) {
					# TODO: Guess more appropriate fallbacks
					$url = DEFAULTFACEBOOKURL;
					if($self->{_cache}) {
						$self->{_cache}->set($url, 0, '10 minutes');
					}
				} elsif($self->{_cache}) {
					$self->{_cache}->set($url, 1, '10 minutes');
				}
			} else {
				$url = DEFAULTFACEBOOKURL;
				if($self->{_cache}) {
					$self->{_cache}->set($url, 0, '10 minutes');
				}
			}
		}

		$rc .= << 'END';
			<div id="fb-root"></div>
			<script>
				(function(d, s, id) {
					var js, fjs = d.getElementsByTagName(s)[0];
					if (d.getElementById(id)) return;
					js = d.createElement(s); js.id = id;
END
		$rc .= "js.src = \"$url\";";
		$rc .= << 'END';
					fjs.parentNode.insertBefore(js, fjs);
					}(document, 'script', 'facebook-jssdk'));
				</script>
END
		my $host_name;
		unless($self->{info}) {
			require CGI::Info;

			$self->{info} = CGI::Info->new();
		}
		$host_name = $self->{info}->host_name();

		$rc .= "<div class=\"fb-like\" data-href=\"http://$host_name\" data-layout=\"standard\" data-action=\"like\" data-show-faces=\"true\" data-share=\"false\"></div>";

		if($params{google_plusone} || $params{linkedin_share_button} || $params{reddit_button}) {
			$rc .= '<p>';
		}
	}
	if($params{linkedin_share_button}) {
		$rc .= << 'END';
<script src="//platform.linkedin.com/in.js" type="text/javascript"></script>
<script type="IN/Share" data-counter="right"></script>
END
		if($params{google_plusone} || $params{reddit_button}) {
			$rc .= '<p>';
		}
	}
	if($params{google_plusone}) {
		# $rc .= << 'END';
			# <div id="gplus">
				# <script type="text/javascript" src="https://apis.google.com/js/plusone.js">
					# {"parsetags": "explicit"}
				# </script>
				# <div id="plusone-div"></div>
				#
				# <script type="text/javascript">
					# gapi.plusone.render("plusone-div",{"size": "medium", "count": "true"});
				# </script>
			# </div>
# END
		$rc .= '<g:plusone></g:plusone>';
		$rc .= '<script type="text/javascript">';
		my $alpha2 = $self->{_alpha2};
		if(defined($alpha2)) {
			$alpha2 =~ s/_/-/;
			$rc .= "window.___gcfg = {lang: '$alpha2'};\n";
		}

		$rc .= << "END";
			  (function() {
			    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
			    po.src = '//apis.google.com/js/plusone.js';
			    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
			  })();
			</script>
END
		if($params{reddit_button}) {
			$rc .= '<p>';
		}
	}
	if($params{reddit_button}) {
		$rc .= '<script type="text/javascript" src="//www.reddit.com/static/button/button1.js"></script>';
	}

	return $rc;
}

=head2 render

Synonym for as_string.

=cut

sub render {
	my ($self, %params) = @_;

	return $self->as_string(%params);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

When adding a FaceBook like button, you may find performance improves a lot if
you use L<HTTP::Cache::Transparent>.

Please report any bugs or feature requests to C<bug-html-socialmedia at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-SocialMedia>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::SocialMedia


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-SocialMedia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-SocialMedia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-SocialMedia>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-SocialMedia/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of HTML::SocialMedia
