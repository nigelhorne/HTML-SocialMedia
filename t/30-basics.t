#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 6;

# Load the module
BEGIN { use_ok('HTML::SocialMedia') }

# Test the version
is($HTML::SocialMedia::VERSION, '0.29', 'Module version is correct');

# Test the 'new' method
my $sm = HTML::SocialMedia->new(
	twitter => 'example',
	lingua  => CGI::Lingua->new(supported => ['en']),
);
isa_ok($sm, 'HTML::SocialMedia', 'Created HTML::SocialMedia object');

# Test 'as_string' method
my $html = $sm->as_string(
	twitter_follow_button => 1,
	twitter_tweet_button  => 1,
);
like($html, qr/twitter-follow-button/, 'Generated Twitter follow button');
like($html, qr/twitter-share-button/, 'Generated Twitter share button');

# Test default parameters
$sm = HTML::SocialMedia->new();
$html = $sm->as_string();
ok(!defined($html), 'as_string generates no HTML output by default');
