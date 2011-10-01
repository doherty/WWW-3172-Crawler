#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Mock::LWP::Dispatch ();
use HTTP::Response;
use HTTP::Headers;
use WWW::3172::Crawler;

sub mock_response {
    my $req = shift;
    die 'Unsupported method: ' . $req->method unless $req->method eq 'GET';

    my $uri = $req->uri;
    my $html = do { open my $in, '<', 't/html5audio.html' or die $!; local $/; <$in> };
    my $res = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new(
            'Content-Length'    => length $html,
            'Content-Type'      => 'text/html'
        ),
        $html
    );
    return $res;
}

my $url = 'http://127.0.0.1/index.html';
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

isa_ok($crawler->to_crawl, 'HASH');

my @to_crawl = keys %{ $crawler->to_crawl };
is_deeply( [sort @to_crawl], [sort qw(http://127.0.0.1/horse.mp3 http://127.0.0.1/horse.ogg)], 'Audio URLs added to crawl list')
    or diag explain $crawler->to_crawl;

