#!perl
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('WWW::3172::Crawler');
}

my $crawler = new_ok('WWW::3172::Crawler' => [host => 'http://127.0.0.1/']);
can_ok ($crawler, 'crawl');

