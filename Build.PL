
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Response" => 0,
    "Module::Build" => "0.3601",
    "Test::Mock::LWP::Dispatch" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A simple web crawler for CSCI 3172 Assignment 1",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "WWW-3172-Crawler",
  "dist_version" => "v0.002",
  "license" => "perl",
  "module_name" => "WWW::3172::Crawler",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Config::General" => 0,
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
    "URI::WithBase" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/crawler2mysql",
    "bin/crawler"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
