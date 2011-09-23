#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Mock::LWP::Dispatch ();
use HTTP::Response;
use HTTP::Headers;
use WWW::3172::Crawler;

sub mock_response {
    my $req = shift;
    die 'Unsupported method: ' . $req->method unless $req->method eq 'GET';

    my $uri = $req->uri;
    my $html = do { open my $in, '<', 't/test.html' or die $!; local $/; <$in> };
    my $res = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new('Content-Length' => length $html),
        $html
    );
    return $res;
}

my $url = 'http://127.0.0.1/';
my $mock_ua = LWP::UserAgent->new(); # Mocked LWP::UserAgent!
$mock_ua->map(
    $url,
    \&mock_response,
);

my $crawler = WWW::3172::Crawler->new(
    host    => $url,
    ua      => $mock_ua,
    max     => 1,
);
my $data = $crawler->crawl;

isa_ok($data, 'HASH');
is((keys %$data)[0], $url, 'URL fetched OK');

