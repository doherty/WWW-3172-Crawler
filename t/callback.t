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

    my $uri     = $req->uri;
    my ($file)  = $uri =~ m{^\Qhttp://127.0.0.1/\E(.*)$};
    my ($ext)   = $file =~ m{\.(.*)$};

    my $html    = do { open my $in, '<', "t/$file" or die $!; local $/; <$in> };
    my $res     = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new(
            'Content-Length'    => length $html,
            'Content-Type'      => ($ext eq 'html' ? 'text/html' : "audio/$ext"),
        ),
        $html
    );
    return $res;
}

my $url = 'http://127.0.0.1/html5audio.html';

my $mock_ua = LWP::UserAgent->new(); # Mocked LWP::UserAgent!
$mock_ua->map(
    qr{^\Qhttp://127.0.0.1/\E.*},
    \&mock_response,
);

sub callback {
    my $uri  = shift;
    my $data = shift;

    isa_ok($data, 'HASH', 'data is a hashref');
    is($uri, $url, 'URL is included & correct');

    delete $data->{speed};
    is_deeply( $data,
    {
        size  => 240,
        stems => {
            your    => 1,
            browser => 1,
            support => 1,
            audio   => 1,
            element => 1,
        }
    }) or diag explain $data;
}

my $crawler = WWW::3172::Crawler->new(
    host    => $url,
    ua      => $mock_ua,
    max     => 1,
    callback=> \&callback,
);
my $end_data = $crawler->crawl;

is($end_data, undef, 'No data returned when callback is in place');

