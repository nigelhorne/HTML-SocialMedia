use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::SocialMedia',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/HTML/SocialMedia.pm',
    ABSTRACT_FROM       => 'lib/HTML/SocialMedia.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'CGI::Lingua' => 0.26,	# Need subcountry_code_alpha2()
	'I18N::LangTags::Detect' => 0,
	'LWP::UserAgent' => 0,
	'Test::Kwalitee' => 0,
	'CGI::Info' => 0.10,	# Needs protocol()
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-SocialMedia-*' },
);
