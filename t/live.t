#!perl
use strict;
use warnings;
use Test::More tests => 5;
use WWW::3172::Crawler ();

my $gif = 'http://imgur.com/images/imgur.gif';
my $crawler = new_ok('WWW::3172::Crawler' => [host => $gif, max => 1]);
my $data = $crawler->crawl;

ok exists $data->{$gif}, "$gif was crawled";
isa_ok $data->{$gif}, 'HASH';
cmp_ok $data->{$gif}->{size},  '>', 0, "$gif has a size";
cmp_ok $data->{$gif}->{speed}, '>', 0, "speed is non-zero";

