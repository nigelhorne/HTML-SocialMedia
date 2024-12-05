package HTML::SocialMedia;

use warnings;
use strict;
use CGI::Lingua;
use Carp;

=head1 NAME

HTML::SocialMedia - Put social media links onto your website

=head1 VERSION

Version 0.29

=cut

our $VERSION = '0.29';

=head1 SYNOPSIS

Many websites these days have links and buttons into social media sites.
This module eases links into Twitter and Facebook.

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

Takes optional parameter lingua, which is a L<CGI::Lingua> object.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a HTML::SocialMedia object.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(x => 'example');
    # ...

=head3 Optional parameters

cache: This object will be an instantiation of a class that understands get and
set, such as L<CHI>.
info: Object which understands host_name messages, such as L<CGI::Info>.
x: x account name
x_related: array of 2 elements - the name and description of a related account

For the above, twitter and twitter_related still work

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Using HTML::SocialMedia->new(), not HTML::SocialMedia::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $lingua = $args{lingua};
	unless(defined($lingua)) {
		my %args;
		if($args{'x'}) {
			$args{'twitter'} ||= $args{'x'};
		}
		if($args{twitter}) {
			# Languages supported by Twitter according to
			# https://x.com/about/resources/tweetbutton
			$args{supported} = ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr'];
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
		if($args{cache}) {
			$args{cache} = $args{cache};
		}
		if($args{logger}) {
			$args{logger} = $args{logger};
		}
		$lingua = $args{lingua} || CGI::Lingua->new(%args);
		if((!defined($lingua)) && scalar($args{supported})) {
			$args{supported} = [];
			$lingua = CGI::Lingua->new(%args);
		}
	}

	# Return the blessed object
	return bless {
		_lingua => $lingua,
		_twitter => $args{twitter},
		_twitter_related => $args{twitter_related},
		_cache => $args{cache},
		_logger => $args{logger},
		_info => $args{info},
		# _alpha2 => undef,
	}, $class;
}

=head2 as_string

Returns the HTML to be added to your website.
HTML::SocialMedia uses L<CGI::Lingua> to try to ensure that the text printed is
in the language of the user.

    use HTML::SocialMedia;
    my $sm = HTML::SocialMedia->new(
	x => 'mytwittername',
	s_related => [ 'someonelikeme', 'another x feed' ]
    );

    print "Content-type: text/html\n\n";

    print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">';
    print '<HTML><HEAD></HEAD><BODY>';

    print $sm->as_string(
	x_follow_button => 1,
	x_tweet_button => 1,	# button to tweet this page
	facebook_like_button => 1,
	facebook_share_button => 1,
	linkedin_share_button => 1,
	reddit_button => 1,
	align => 'right',
    );

    print '</BODY></HTML>';
    print "\n";

If no social media links have been requested,
as_string() returns undef

=head3 Optional parameters

facebook_like_button: add a Facebook like button

facebook_share_button: add a Facebook share button

linkedin_share_button: add a LinkedIn share button

x_follow_button: add a button to follow the account

x_tweet_button: add a button to tweet this page

reddit_button: add a Reddit button

align: argument to <p> HTML tag

=cut

sub as_string {
	my $self = shift;

	$self->_trace('Entering as_string');

	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: as_string($options)');
	} elsif(@_ % 2 == 0) {
		%params = @_;
	}

	my $lingua = $self->{_lingua};

	unless($self->{_alpha2}) {
		my $alpha2 = $lingua->language_code_alpha2();
		my $locale = $lingua->locale();	# Locale::Object::Country

		if(defined($alpha2)) {
			$self->_debug("language_code_alpha2: $alpha2");
		} else {
			$self->_debug('language_code_alpha2 returned undef');
		}
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
				# Can't determine the area, i.e. is it en_GB or en_US?
				$self->_debug('Clearing the value of alpha2');
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
				$self->_info("Can't determine country, falling back to en_GB");
			}
		}
		$self->_debug("alpha2: $alpha2");
		$self->{_alpha2} = $alpha2;
	}

	my $rc;

	if($params{facebook_like_button} || $params{facebook_share_button}) {
		if(!defined($self->{_country})) {
			# Grab the Facebook preamble and put it as early as we can

			# See if Facebook supports our wanted language. If not then
			# I suppose we could enumerate through other requested languages,
			# but that is probably not worth the effort.

			my $country = $self->{_alpha2} || 'en_US';
			my $res;
			if($self->{_cache}) {
				$res = $self->{_cache}->get($country);
			}

			if(defined($res)) {
				unless($res) {
					$country = 'en_US';
				}
			} else {
				# Response is of type HTTP::Response
				require LWP::UserAgent;

				my $response;

				eval {
					$response = LWP::UserAgent->new(timeout => 10)->request(
						HTTP::Request->new(GET => "http://connect.facebook.com/$country/sdk.js")
					);
				};
				if($@) {
					$self->_info($@);
					$response = undef;
				}
				if(defined($response) && $response->is_success()) {
					# If it's not supported, Facebook doesn't return an HTTP
					# error such as 404, it returns a string, which no doubt
					# will get changed at sometime in the future. Sigh.
					if($response->decoded_content() =~ /is not a valid locale/) {
						# TODO: Guess more appropriate fallbacks
						$country = 'en_US';
						if($self->{_cache}) {
							$self->{_cache}->set($country, 0, '10 minutes');
						}
					} elsif($self->{_cache}) {
						$self->{_cache}->set($country, 1, '10 minutes');
					}
				} else {
					$country = 'en_US';
					if($self->{_cache}) {
						$self->{_cache}->set($country, 0, '10 minutes');
					}
				}
			}
			$self->{_country} = $country;
		}

		$rc = << "END";
			<div id="fb-root"></div>
			<script>(function(d, s, id) {
					var js, fjs = d.getElementsByTagName(s)[0];
					if (d.getElementById(id)) return;
					js = d.createElement(s); js.id = id;
					js.src = "//connect.facebook.com/$self->{_country}/sdk.js#xfbml=1&version=v2.8&appId=953901534714390";
					fjs.parentNode.insertBefore(js, fjs);
				}(document, 'script', 'facebook-jssdk'));
			</script>
END
	}

	my $paragraph;
	if($params{'align'}) {
		$paragraph = "<p align=\"$params{'align'}\">";
	} else {
		$paragraph = '<p>';
	}

	$params{'twitter_follow_button'} ||= $params{'x_follow_button'};
	$params{'twitter_tweet_button'} ||= $params{'x_tweet_button'};

	if($self->{_twitter}) {
		if($params{twitter_follow_button}) {
			my $language = $lingua->language();
			if(($language eq 'English') || ($language eq 'Unknown')) {
				$rc .= '<a href="//x.com/' . $self->{_twitter} . '" class="twitter-follow-button">Follow @' . $self->{_twitter} . '</a>';
			} else {
				my $langcode = substr($self->{_alpha2}, 0, 2);
				$rc .= '<a href="//x.com/' . $self->{_twitter} . "\" class=\"twitter-follow-button\" data-lang=\"$langcode\">Follow \@" . $self->{_twitter} . '</a>';
			}
			if($params{twitter_tweet_button}) {
				$rc .= $paragraph;
			}
		}
		if($params{twitter_tweet_button}) {
			$rc .= << 'END';
				<script type="text/javascript">
					window.twttr = (function(d, s, id) {
						var js, fjs = d.getElementsByTagName(s)[0],
						t = window.twttr || {};
						if (d.getElementById(id)) return t;
						js = d.createElement(s);
						js.id = id;
						js.src = "https://platform.x.com/widgets.js";
						fjs.parentNode.insertBefore(js, fjs);

						t._e = [];
						t.ready = function(f) {
							t._e.push(f);
						};

						return t;
					}(document, "script", "twitter-wjs"));
				</script>
				<a href="//x.com/intent/tweet" class="twitter-share-button" data-count="horizontal" data-via="
END
			$rc =~ s/\n$//;
			$rc .= $self->{_twitter} . '"';
			if($self->{_twitter_related}) {
				my @related = @{$self->{_twitter_related}};
				$rc .= ' data-related="' . $related[0] . ':' . $related[1] . '"';
			}
			$rc .= '>Tweet</a><script type="text/javascript" src="//platform.x.com/widgets.js"></script>';
		}
	}

	if($params{facebook_like_button}) {
		if($params{twitter_tweet_button} || $params{twitter_follow_button}) {
			$rc .= $paragraph;
		}

		my $host_name;
		unless($self->{info}) {
			require CGI::Info;

			$self->{info} = CGI::Info->new();
		}
		$host_name = $self->{info}->host_name();

		$rc .= "<div class=\"fb-like\" data-href=\"//$host_name\" data-layout=\"standard\" data-action=\"like\" data-size=\"small\" data-show-faces=\"false\" data-share=\"false\"></div>";

		if($params{google_plusone} || $params{linkedin_share_button} || $params{reddit_button} || $params{'facebook_share_button'}) {
			$rc .= $paragraph;
		}
	}
	if($params{'facebook_share_button'}) {
		if($params{twitter_tweet_button} || $params{twitter_follow_button}) {
			$rc .= $paragraph;
		}

		my $host_name;
		unless($self->{info}) {
			require CGI::Info;

			$self->{info} = CGI::Info->new();
		}
		$host_name = $self->{info}->host_name();

		$rc .= "<div class=\"fb-share-button\" data-href=\"//$host_name\" data-layout=\"button_count\" data-size=\"small\" data-mobile-iframe=\"false\"><a class=\"fb-xfbml-parse-ignore\" target=\"_blank\" href=\"//www.facebook.com/sharer/sharer.php?u=%2F%2F$host_name&amp;src=sdkpreparse\">Share</a></div>";

		if($params{google_plusone} || $params{linkedin_share_button} || $params{reddit_button}) {
			$rc .= $paragraph;
		}
	}

	if($params{linkedin_share_button}) {
		$rc .= << 'END';
<script src="//platform.linkedin.com/in.js" type="text/javascript"></script>
<script type="IN/Share" data-counter="right"></script>
END
		if($params{google_plusone} || $params{reddit_button}) {
			$rc .= $paragraph;
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

		my $protocol;
		if($self->{_info}) {
			$protocol = $self->{_info}->protocol() || 'http';
		} else {
			require CGI::Info;
			$protocol = CGI::Info->protocol() || 'http';
		}

		$rc .= << "END";
			  (function() {
			    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
			    po.src = '$protocol://apis.google.com/js/plusone.js';
			    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
			  })();
			</script>
END
		if($params{reddit_button}) {
			$rc .= $paragraph;
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

=head2	set_logger

Sets class or code reference that will be used for logging.

=cut

sub set_logger
{
	my $self = shift;
	my $args = $self->_get_params('logger', @_);

	if(defined($args->{'logger'})) {
		$self->{'_logger'} = $args->{'logger'};
		return $self;
	}
	Carp::croak('Usage: set_logger(logger => $logger)')
}

# Helper routines for logger()
sub _log {
	my ($self, $level, @messages) = @_;

	if(my $logger = $self->{'_logger'}) {
		if(ref($logger) eq 'CODE') {
			$logger->({ level => $level, message => \@messages });
		} else {
			$logger->$level(@messages);
		}
	}
}

sub _debug {
	my $self = shift;
	$self->_log('debug', @_);
}

sub _info {
	my $self = shift;
	$self->_log('info', @_);
}

sub _trace {
	my $self = shift;
	$self->_log('trace', @_);
}

# Helper routine to parse the arguments given to a function,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	shift;  # Discard the first argument (typically $self)
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if ref $_[0] eq 'HASH';

	my %rc;
	my $num_args = scalar @_;

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && (defined $default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif($num_args == 0 && defined $default) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '($default => \$val)');
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	}

	return \%rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

When adding a FaceBook like button, you may find performance improves a lot if
you use L<HTTP::Cache::Transparent>.

Please report any bugs or feature requests to C<bug-html-socialmedia at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-SocialMedia>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Would be good to have
    my ($head, $body) = $sm->onload_render();

=head1 SEE ALSO


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::SocialMedia

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/HTML-SocialMedia>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-SocialMedia>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=HTML-SocialMedia>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=HTML::SocialMedia>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of HTML::SocialMedia
