use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::SocialMedia',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/HTML/SocialMedia.pm',
    ABSTRACT_FROM       => 'lib/HTML/SocialMedia.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	# 'Test::Kwalitee' => 0,
	'CGI::Info' => 0.10,	# Needs protocol()
    },
    PREREQ_PM => {
	'CGI::Lingua' => 0.26,	# Need subcountry_code_alpha2()
	'I18N::LangTags::Detect' => 0,
	'LWP::UserAgent' => 0,
	'LWP::Protocol::https' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-SocialMedia-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/HTML-SocialMedia.git',
			web => 'https://github.com/nigelhorne/HTML-SocialMedia',
    		},
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
