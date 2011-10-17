
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A simple web crawler for CSCI 3172 Assignment 1",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Response" => 0,
    "Module::Build" => "0.3601",
    "Test::Mock::LWP::Dispatch" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "WWW-3172-Crawler",
  "EXE_FILES" => [
    "bin/crawler2mysql",
    "bin/crawler"
  ],
  "LICENSE" => "perl",
  "NAME" => "WWW::3172::Crawler",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Data::Printer" => 0,
    "Data::Validate::URI" => 0,
    "Getopt::Long" => 0,
    "HTML::TokeParser::Simple" => 0,
    "HTML::TreeBuilder" => 0,
    "LWP::RobotUA" => 0,
    "Lingua::Stem::Snowball" => 0,
    "Lingua::StopWords" => 0,
    "List::MoreUtils" => 0,
    "List::UtilsBy" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Pod::Usage" => 0,
    "Text::Unidecode" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "URI::WithBase" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "v0.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



