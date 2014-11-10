#!/usr/bin/perl -wT

use strict;

use Test::Most tests => 1;

use HTML::SocialMedia;

isa_ok(HTML::SocialMedia->new(), 'HTML::SocialMedia', 'Creating HTML::SocialMedia object');
